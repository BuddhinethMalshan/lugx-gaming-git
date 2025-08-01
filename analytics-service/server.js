const express = require('express');
const { createClient } = require('@clickhouse/client');
const app = express();
app.use(express.json());

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

// ClickHouse connection
const client = createClient({
  url: 'http://clickhouse-service.lugx-gaming.svc.cluster.local:8123',
  username: 'default',
  password: 'clickhouse_password'
});

// Health check
app.get('/health', (req, res) => res.send('OK'));

// Event ingestion endpoint
app.post('/events', async (req, res) => {
  try {
    const {
      event_type,
      page = '',
      target = '',
      depth = 0,
      timestamp,
      user_id = ''
    } = req.body;

    // Validation
    if (!event_type || !timestamp) {
      return res.status(400).json({ error: 'event_type and timestamp are required.' });
    }

    const event = {
      event_type,
      page,
      target,
      depth,
      timestamp,
      user_id
    };

    await client.insert({
      table: 'web_analytics',
      values: [event],
      format: 'JSONEachRow'
    });

    res.status(200).json({ message: 'Event recorded successfully.' });
} catch (error) {
  console.error('Error inserting event:', error?.message || error);
  res.status(500).json({ error: error?.message || 'Failed to record event' });
}

});

// Start server
app.listen(3000, () => console.log('Analytics Service running on port 3000'));

