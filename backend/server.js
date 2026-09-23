require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./src/routes/auth');
const locationRoutes = require('./src/routes/locations');
const recommendationRoutes = require('./src/routes/recommendations');

// Ensure the DB exists and is seeded with demo data on first run.
require('./src/db');
require('./src/seed');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => res.json({ status: 'ok', service: 'smart-street-vendor-backend' }));

app.use('/api/auth', authRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/recommendations', recommendationRoutes);

app.use((req, res) => res.status(404).json({ error: 'Not found' }));
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Smart Street-Vendor Location Optimizer API running on port ${PORT}`);
});
