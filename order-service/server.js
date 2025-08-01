const { Pool } = require('pg');
const express = require('express');
const app = express();
app.use(express.json());
const pool = new Pool({
  user: 'lugx',
  password: 'password',
  host: 'postgres-service.lugx-gaming.svc.cluster.local',
  port: 5432,
  database: 'lugx_gaming'
});
app.get('/', (req, res) => {
  res.json({ message: 'Order Service' });
});
app.get('/orders', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM orders');
    res.json(rows);
  } catch (err) {
    console.error('Error querying orders:', err);
    res.status(500).send('Error querying orders');
  }
});
app.post('/orders', async (req, res) => {
  const { game_id, user_id, quantity } = req.body;
  console.log('Received body:', req.body); // 🔍 Debug log
  if (game_id === undefined || user_id === undefined || quantity === undefined) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  try {
    await pool.query(
      'INSERT INTO orders (game_id, user_id, quantity) VALUES ($1, $2, $3)',
      [game_id, user_id, quantity]
    );
    res.json({ message: 'Order inserted successfully' });
  } catch (err) {
    console.error('Error inserting order:', err);
    res.status(500).json({ error: 'Failed to insert order' });
  }
});
app.listen(3000, () => {
  console.log('Order Service running on port 3000');
});
