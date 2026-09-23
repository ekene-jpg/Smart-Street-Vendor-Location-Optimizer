const express = require('express');
const db = require('../db');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/locations?area=Ikeja  -> list locations (optionally filtered by area/name)
router.get('/', (req, res) => {
  const { area, q } = req.query;
  let sql = `SELECT l.*, f.pedestrian_density, f.accessibility_score, f.transport_distance,
                    f.competition_level, f.commercial_activity, f.traffic_density
             FROM Location l
             JOIN LocationFeature f ON f.location_id = l.location_id
             WHERE 1=1`;
  const params = [];
  if (area) {
    sql += ' AND l.area = ?';
    params.push(area);
  }
  if (q) {
    sql += ' AND l.location_name LIKE ?';
    params.push(`%${q}%`);
  }
  const rows = db.prepare(sql).all(...params);
  res.json({ count: rows.length, locations: rows });
});

// GET /api/locations/areas -> distinct areas for the search dropdown
router.get('/areas', (req, res) => {
  const rows = db.prepare('SELECT DISTINCT area FROM Location ORDER BY area').all();
  res.json({ areas: rows.map((r) => r.area) });
});

// GET /api/locations/:id -> full detail including vendors
router.get('/:id', (req, res) => {
  const location = db.prepare('SELECT * FROM Location WHERE location_id = ?').get(req.params.id);
  if (!location) return res.status(404).json({ error: 'Location not found' });

  const feature = db
    .prepare('SELECT * FROM LocationFeature WHERE location_id = ?')
    .get(req.params.id);
  const vendors = db
    .prepare('SELECT * FROM Vendor WHERE location_id = ?')
    .all(req.params.id);

  res.json({ ...location, feature, vendors });
});

// POST /api/locations -> admin: add a candidate location + features
router.post('/', requireAuth, requireAdmin, (req, res) => {
  const {
    location_name, latitude, longitude, area, description,
    pedestrian_density, accessibility_score, transport_distance,
    competition_level, commercial_activity, traffic_density,
  } = req.body || {};

  if (!location_name || latitude == null || longitude == null || !area) {
    return res.status(400).json({ error: 'location_name, latitude, longitude and area are required' });
  }

  const insertLoc = db.prepare(
    `INSERT INTO Location (location_name, latitude, longitude, area, description, status)
     VALUES (?, ?, ?, ?, ?, 'active')`
  );
  const info = insertLoc.run(location_name, latitude, longitude, area, description || null);
  const locationId = info.lastInsertRowid;

  db.prepare(
    `INSERT INTO LocationFeature
      (location_id, pedestrian_density, accessibility_score, transport_distance, competition_level, commercial_activity, traffic_density)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  ).run(
    locationId,
    pedestrian_density ?? 50,
    accessibility_score ?? 50,
    transport_distance ?? 300,
    competition_level ?? 50,
    commercial_activity ?? 50,
    traffic_density ?? 50
  );

  res.status(201).json({ location_id: locationId });
});

// PUT /api/locations/:id -> admin: update location or its features
router.put('/:id', requireAuth, requireAdmin, (req, res) => {
  const id = req.params.id;
  const location = db.prepare('SELECT * FROM Location WHERE location_id = ?').get(id);
  if (!location) return res.status(404).json({ error: 'Location not found' });

  const fields = ['location_name', 'latitude', 'longitude', 'area', 'description', 'status'];
  const updates = fields.filter((f) => req.body[f] !== undefined);
  if (updates.length) {
    const setClause = updates.map((f) => `${f} = ?`).join(', ');
    db.prepare(`UPDATE Location SET ${setClause} WHERE location_id = ?`).run(
      ...updates.map((f) => req.body[f]),
      id
    );
  }

  const featureFields = [
    'pedestrian_density', 'accessibility_score', 'transport_distance',
    'competition_level', 'commercial_activity', 'traffic_density',
  ];
  const featureUpdates = featureFields.filter((f) => req.body[f] !== undefined);
  if (featureUpdates.length) {
    const setClause = featureUpdates.map((f) => `${f} = ?`).join(', ');
    db.prepare(`UPDATE LocationFeature SET ${setClause} WHERE location_id = ?`).run(
      ...featureUpdates.map((f) => req.body[f]),
      id
    );
  }

  res.json({ message: 'Location updated' });
});

// DELETE /api/locations/:id -> admin
router.delete('/:id', requireAuth, requireAdmin, (req, res) => {
  const info = db.prepare('DELETE FROM Location WHERE location_id = ?').run(req.params.id);
  if (info.changes === 0) return res.status(404).json({ error: 'Location not found' });
  res.json({ message: 'Location deleted' });
});

module.exports = router;
