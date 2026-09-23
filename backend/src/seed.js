// Seeds the database with a demo admin user, a sample ML/scoring model
// record, and ~18 mock candidate street-vendor locations across Lagos
// areas mentioned in the thesis (Ikeja, Yaba, Surulere, Lekki, Ikorodu
// Road, Oshodi, etc). Feature values are illustrative mock data, not
// measured field data.
const bcrypt = require('bcryptjs');
const db = require('./db');

function run() {
  const userCount = db.prepare('SELECT COUNT(*) AS c FROM User').get().c;
  if (userCount === 0) {
    const hash = bcrypt.hashSync('Admin@123', 10);
    db.prepare(
      `INSERT INTO User (full_name, email, password, role) VALUES (?, ?, ?, ?)`
    ).run('Demo Admin', '[email protected]', hash, 'admin');

    const userHash = bcrypt.hashSync('Vendor@123', 10);
    db.prepare(
      `INSERT INTO User (full_name, email, password, role) VALUES (?, ?, ?, ?)`
    ).run('Demo Vendor', '[email protected]', userHash, 'user');
    console.log('Seeded demo users: [email protected] / Admin@123, [email protected] / Vendor@123');
  }

  const modelCount = db.prepare('SELECT COUNT(*) AS c FROM Model').get().c;
  if (modelCount === 0) {
    db.prepare(
      `INSERT INTO Model (model_name, algorithm, version, accuracy) VALUES (?, ?, ?, ?)`
    ).run('Weighted Suitability Model', 'Weighted Sum (MCDA)', '1.0', null);
  }

  const locCount = db.prepare('SELECT COUNT(*) AS c FROM Location').get().c;
  if (locCount > 0) {
    console.log('Locations already seeded, skipping.');
    return;
  }

  const locations = [
    ['Computer Village Junction', 6.6018, 3.3515, 'Ikeja', 'High foot traffic electronics hub'],
    ['Allen Avenue Roundabout', 6.6006, 3.3508, 'Ikeja', 'Busy commercial roundabout'],
    ['Yaba Tech Front Gate', 6.5158, 3.3841, 'Yaba', 'Student and commuter corridor'],
    ['Tejuosho Market Entrance', 6.5105, 3.3733, 'Yaba', 'Market frontage, heavy pedestrian flow'],
    ['Ojuelegba Bridge Underpass', 6.5083, 3.3623, 'Surulere', 'Transport interchange, high density'],
    ['Bode Thomas Street', 6.4989, 3.3583, 'Surulere', 'Residential/commercial mix'],
    ['Oshodi Bus Terminal', 6.5550, 3.3480, 'Oshodi', 'Major transport hub'],
    ['Oshodi Market Road', 6.5561, 3.3502, 'Oshodi', 'Dense trading corridor'],
    ['Ikorodu Road (Fadeyi)', 6.5290, 3.3690, 'Ikorodu Road', 'Pedestrian bridge trading spot'],
    ['Ikorodu Road (Maryland)', 6.5720, 3.3660, 'Ikorodu Road', 'Heavy vehicular and foot traffic'],
    ['Lekki Phase 1 Admiralty Way', 6.4390, 3.4720, 'Lekki', 'Upscale commercial strip'],
    ['Lekki Chevron Roundabout', 6.4460, 3.5350, 'Lekki', 'Growing commercial area'],
    ['Ajah Bus Stop', 6.4670, 3.5710, 'Lekki', 'Busy suburban transport node'],
    ['CMS Bus Stop', 6.4520, 3.3960, 'Lagos Island', 'CBD transport hub'],
    ['Balogun Market Entrance', 6.4541, 3.3898, 'Lagos Island', 'Very high trading density'],
    ['Mile 2 Interchange', 6.4590, 3.3140, 'Mile 2', 'Major interchange, high congestion'],
    ['Berger Bus Stop', 6.6390, 3.3480, 'Berger', 'Expressway transport node'],
    ['Iyana Ipaja Market', 6.6120, 3.2790, 'Ipaja', 'Busy suburban market corridor'],
  ];

  const insertLoc = db.prepare(
    `INSERT INTO Location (location_name, latitude, longitude, area, description, status)
     VALUES (?, ?, ?, ?, ?, 'active')`
  );
  const insertFeat = db.prepare(
    `INSERT INTO LocationFeature
      (location_id, pedestrian_density, accessibility_score, transport_distance, competition_level, commercial_activity, traffic_density)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  );
  const insertVendor = db.prepare(
    `INSERT INTO Vendor (location_id, vendor_type, product_category, status)
     VALUES (?, ?, ?, 'active')`
  );

  const vendorTypes = ['Food & drinks', 'Phone accessories', 'Fashion', 'Fruits & produce', 'Household items'];

  const seedTx = db.transaction(() => {
    for (const [name, lat, lng, area, desc] of locations) {
      const info = insertLoc.run(name, lat, lng, area, desc);
      const locationId = info.lastInsertRowid;

      // Mock but plausible feature values.
      const pedestrian_density = +(Math.random() * 70 + 30).toFixed(1); // 30-100
      const accessibility_score = +(Math.random() * 60 + 40).toFixed(1); // 40-100
      const transport_distance = +(Math.random() * 900 + 50).toFixed(0); // 50-950 metres
      const competition_level = +(Math.random() * 90 + 5).toFixed(1); // 5-95
      const commercial_activity = +(Math.random() * 70 + 30).toFixed(1); // 30-100
      const traffic_density = +(Math.random() * 80 + 15).toFixed(1); // 15-95

      insertFeat.run(
        locationId,
        pedestrian_density,
        accessibility_score,
        transport_distance,
        competition_level,
        commercial_activity,
        traffic_density
      );

      const vendorCount = 1 + Math.floor(Math.random() * 3);
      for (let i = 0; i < vendorCount; i++) {
        const type = vendorTypes[Math.floor(Math.random() * vendorTypes.length)];
        insertVendor.run(locationId, type, type, 'active');
      }
    }
  });
  seedTx();

  console.log(`Seeded ${locations.length} candidate locations with features and vendors.`);
}

run();
