const { Pool } = require('pg');
const express = require('express');
const app = express();

app.use(express.json());

// PostgreSQL connection config
const pool = new Pool({
  user: 'lugx',
  password: 'password',
  host: 'postgres-service.lugx-gaming.svc.cluster.local',
  port: 5432,
  database: 'lugx_gaming'
});

// Ensure table exists at startup
const createTableIfNotExists = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS games (
        id SERIAL PRIMARY KEY,
        title VARCHAR(100),
        genre VARCHAR(50),
        price NUMERIC,
        release_date DATE
      );
    `);
    console.log("games table is ready.");
  } catch (err) {
    console.error("Failed to ensure table exists:", err);
  }
};

// Routes
app.get('/', (req, res) => {
  console.log('Received GET /');
  res.json({ message: 'Game Service' });
});

app.get('/games', async (req, res) => {
  console.log('Received GET /games');
  try {
    const { rows } = await pool.query('SELECT * FROM games');
    res.json(rows);
  } catch (err) {
    console.error('Error querying games:', err);
    res.status(500).send('Error querying games');
  }
});

app.post('/games', async (req, res) => {
  const { title, genre, price, release_date } = req.body;
  console.log('Received POST /games:', req.body);

  if (!title || !genre || !price || !release_date) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    await pool.query(
      'INSERT INTO games (title, genre, price, release_date) VALUES ($1, $2, $3, $4)',
      [title, genre, price, release_date]
    );
    res.status(201).json({ message: 'Game added successfully' });
  } catch (err) {
    console.error('Error inserting game:', err);
    res.status(500).json({ error: 'Failed to add game' });
  }
});

// Start the server
const PORT = 3000;
app.listen(PORT, async () => {
  await createTableIfNotExists();
  console.log(`Game Service running on port ${PORT}`);
});
// Retry image push
