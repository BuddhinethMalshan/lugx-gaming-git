#!/bin/bash

set -e

echo "Running integration tests..."

# Test game-service
response=$(curl -s -o /dev/null -w "%{http_code}" http://lugx-gaming.test/games)
if [ "$response" != "200" ]; then
  echo "game-service /games failed: HTTP $response"
  exit 1
fi
echo "game-service /games: OK"

# Test game creation
response=$(curl -s -X POST http://lugx-gaming.test/games -H "Content-Type: application/json" -d '{"title":"TestGame","genre":"Action","price":49.99,"release_date":"2025-08-01","platform":"PC","description":"Test game"}' -o /dev/null -w "%{http_code}")
if [ "$response" != "200" ] && [ "$response" != "201" ]; then
  echo "game-service /games POST failed: HTTP $response"
  exit 1
fi
echo "game-service /games POST: OK"

# Test order-service
response=$(curl -s -o /dev/null -w "%{http_code}" http://lugx-gaming.test/orders -H "Content-Type: application/json" -d '{"game_id":12,"user_id":"123","quantity":2}')
if [ "$response" != "200" ] && [ "$response" != "201" ]; then
  echo "order-service /orders POST failed: HTTP $response"
  exit 1
fi
echo "order-service /orders POST: OK"

# Test analytics-service
response=$(curl -s -o /dev/null -w "%{http_code}" http://analytics.lugx.test/health)
if [ "$response" != "200" ]; then
  echo "analytics-service /health failed: HTTP $response"
  exit 1
fi
echo "analytics-service /health: OK"

# Test analytics event
response=$(curl -s -X POST http://analytics.lugx.test/events -H "Content-Type: application/json" -d '{"event_type":"test","page":"test-page","target":"button","depth":100,"timestamp":"2025-08-01 07:00:00"}' -o /dev/null -w "%{http_code}")
if [ "$response" != "200" ]; then
  echo "analytics-service /events POST failed: HTTP $response"
  exit 1
fi
echo "analytics-service /events POST: OK"

# Test frontend
response=$(curl -s -o /dev/null -w "%{http_code}" http://lugx-gaming.test)
if [ "$response" != "200" ]; then
  echo "frontend-service / failed: HTTP $response"
  exit 1
fi
echo "frontend-service /: OK"

echo "All tests passed!"
