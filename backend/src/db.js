const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');
require('dotenv').config();

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'vendor_optimizer.db');
fs.mkdirSync(path.dirname(dbPath), { recursive: true });

const db = new Database(dbPath);
db.pragma('foreign_keys = ON');

// Schema follows the entities defined in Chapter 3 (User, Location,
// LocationFeature, Recommendation, Vendor, Model).
db.exec(`
CREATE TABLE IF NOT EXISTS User (
  user_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name    TEXT NOT NULL,
  email        TEXT NOT NULL UNIQUE,
  password     TEXT NOT NULL,
  role         TEXT NOT NULL DEFAULT 'user',
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS Location (
  location_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  location_name  TEXT NOT NULL,
  latitude       REAL NOT NULL,
  longitude      REAL NOT NULL,
  area           TEXT NOT NULL,
  description    TEXT,
  status         TEXT NOT NULL DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS LocationFeature (
  feature_id           INTEGER PRIMARY KEY AUTOINCREMENT,
  location_id          INTEGER NOT NULL REFERENCES Location(location_id) ON DELETE CASCADE,
  pedestrian_density   REAL NOT NULL,
  accessibility_score  REAL NOT NULL,
  transport_distance   REAL NOT NULL,
  competition_level    REAL NOT NULL,
  commercial_activity  REAL NOT NULL,
  traffic_density      REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS Vendor (
  vendor_id         INTEGER PRIMARY KEY AUTOINCREMENT,
  location_id       INTEGER NOT NULL REFERENCES Location(location_id) ON DELETE CASCADE,
  vendor_type       TEXT,
  product_category  TEXT,
  status            TEXT NOT NULL DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS Model (
  model_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  model_name    TEXT NOT NULL,
  algorithm     TEXT NOT NULL,
  version       TEXT NOT NULL,
  accuracy      REAL,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS Recommendation (
  recommendation_id  INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id            INTEGER NOT NULL REFERENCES User(user_id) ON DELETE CASCADE,
  location_id        INTEGER NOT NULL REFERENCES Location(location_id) ON DELETE CASCADE,
  suitability_score  REAL NOT NULL,
  rank               INTEGER NOT NULL,
  generated_at       TEXT NOT NULL DEFAULT (datetime('now'))
);
`);

module.exports = db;
