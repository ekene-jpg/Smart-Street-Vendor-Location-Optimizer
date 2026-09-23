// Location Suitability Model (Chapter 3, section 3.14):
//   S_i = sum_j( w_j * x_ij )
// where x_ij is the min-max normalised value of feature j for location i,
// and w_j is the weight assigned to feature j.
//
// transport_distance, competition_level and traffic_density negatively
// affect suitability, so they are inverted after normalisation
// (section 3.14 / 3.16.3), consistent with the thesis's Min-Max formula:
//   X' = (X - X_min) / (X_max - X_min)

const DEFAULT_WEIGHTS = {
  pedestrian_density: 0.25,
  accessibility_score: 0.2,
  transport_distance: 0.15, // inverted: closer is better
  competition_level: 0.15, // inverted: less competition is better
  commercial_activity: 0.15,
  traffic_density: 0.1, // inverted: less traffic is better
};

const NEGATIVE_FEATURES = new Set(['transport_distance', 'competition_level', 'traffic_density']);

function minMaxNormalize(values) {
  const min = Math.min(...values);
  const max = Math.max(...values);
  if (max === min) return values.map(() => 0.5);
  return values.map((v) => (v - min) / (max - min));
}

/**
 * @param {Array<{location_id:number, [feature]:number}>} rows - locations joined with their features
 * @param {Object} weights - optional override of DEFAULT_WEIGHTS (same keys)
 * @returns {Array} rows with `suitability_score` added, sorted descending, with `rank` assigned
 */
function scoreLocations(rows, weights = {}) {
  const w = { ...DEFAULT_WEIGHTS, ...weights };
  const featureKeys = Object.keys(w);

  const normalizedByFeature = {};
  for (const key of featureKeys) {
    const raw = rows.map((r) => Number(r[key]));
    let norm = minMaxNormalize(raw);
    if (NEGATIVE_FEATURES.has(key)) {
      norm = norm.map((v) => 1 - v);
    }
    normalizedByFeature[key] = norm;
  }

  const scored = rows.map((row, idx) => {
    let score = 0;
    const breakdown = {};
    for (const key of featureKeys) {
      const contribution = w[key] * normalizedByFeature[key][idx];
      breakdown[key] = +contribution.toFixed(4);
      score += contribution;
    }
    return {
      ...row,
      suitability_score: +(score * 100).toFixed(2), // scaled 0-100 for readability
      score_breakdown: breakdown,
    };
  });

  scored.sort((a, b) => b.suitability_score - a.suitability_score);
  scored.forEach((row, i) => {
    row.rank = i + 1;
  });
  return scored;
}

module.exports = { scoreLocations, DEFAULT_WEIGHTS };
