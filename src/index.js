'use strict';

const express = require('express');
const helmet = require('helmet');
const { sanitizeInput, getAppVersion } = require('./utils');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(express.json({ limit: '100kb' }));

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', version: getAppVersion() });
});

app.get('/echo', (req, res) => {
  const message = sanitizeInput(req.query.message || '');
  console.log('demo lint failure scenario');
  res.status(200).json({ message });
});

if (require.main === module) {
  app.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`Service listening on port ${PORT}`);
  });
}

module.exports = app;
