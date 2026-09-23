const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');
const { scoreLocations, DEFAULT_WEIGHTS } = require('../scoring');

const router = express.Router();

// POST /api/recommendations
// Body: { area?: string, weights?: {pedestrian_density, accessibility_score,
//          transport_distance, competition_level, commercial_activity, traffic_density} }
// Runs the suitability-scoring pipeline (Ch.3, 3.14): preprocess -> extract
// features -> calculate score -> rank -> return + persist top results.
router.post('/', requireAuth, (req, res) => {
  const { area, weights } = req.body || {};

  let sql = `SELECT l.location_id, l.location_name, l.latitude, l.longitude, l.area, l.description,
                    f.pedestrian_density, f.accessibility_score, f.transport_distance,
                    f.competition_level, f.commercial_activity, f.traffic_density
             FROM Location l
             JOIN LocationFeature f ON f.location_id = l.location_id
             WHERE l.status = 'active'`;
  const params = [];
  if (area) {
    sql += ' AND l.area = ?';
    params.push(area);
  }

  const rows = db.prepare(sql).all(...params);
  if (rows.length === 0) {
    return res.status(404).json({ error: 'No candidate locations found for the given filters' });
  }

  const ranked = scoreLocations(rows, weights || {});

  const insertRec = db.prepare(
    `INSERT INTO Recommendation (user_id, location_id, suitability_score, rank)
     VALUES (?, ?, ?, ?)`
  );
  const saveTx = db.transaction((items) => {
    for (const item of items) {
      insertRec.run(req.user.user_id, item.location_id, item.suitability_score, item.rank);
    }
  });
  saveTx(ranked);

  res.json({
    weights_used: { ...DEFAULT_WEIGHTS, ...(weights || {}) },
    count: ranked.length,
    recommendations: ranked,
  });
});

// GET /api/recommendations/history -> the current user's past recommendation runs
router.get('/history', requireAuth, (req, res) => {
  const rows = db
    .prepare(
      `SELECT r.recommendation_id, r.suitability_score, r.rank, r.generated_at,
              l.location_id, l.location_name, l.area, l.latitude, l.longitude
       FROM Recommendation r
       JOIN Location l ON l.location_id = r.location_id
       WHERE r.user_id = ?
       ORDER BY r.generated_at DESC, r.rank ASC
       LIMIT 100`
    )
    .all(req.user.user_id);
  res.json({ history: rows });
});

module.exports = router;
