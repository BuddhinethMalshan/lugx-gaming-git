CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    release_date TIMESTAMP NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT,
    game_id INT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Optional: Insert sample data for games
INSERT INTO games (title, genre, price, release_date) VALUES
('Test', 'RPG', 39.99, '2025-08-01 00:00:00'),
('Call of Duty', 'Action', 59.99, '2015-08-01 00:00:00'),
('Need for Speed 2', 'Racing', 9.99, '2008-08-01 00:00:00'),
('Cricket 07', 'Sports', 9.99, '2007-02-01 00:00:00');

INSERT INTO orders (user_id, game_id, order_date) VALUES
(101, 1, '2025-08-02 10:30:00'),
(102, 2, '2015-08-03 12:00:00'),
(103, 3, '2008-08-05 14:45:00');
