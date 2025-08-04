#!/bin/bash

echo "Running integration tests..."

# Wait for pods to be ready in lugx-gaming-blue (reduced to 60s)
echo "Waiting for pods to be ready in lugx-gaming-blue..."
pod_count=$(minikube kubectl -- get pods -n lugx-gaming-blue --no-headers 2>/dev/null | wc -l)
if [ "$pod_count" -eq 0 ]; then
  echo "No pods found in lugx-gaming-blue. Deployment failed."
  exit 1
fi
minikube kubectl -- wait --for=condition=ready pod --all -n lugx-gaming-blue --timeout=60s

# Test game-service
echo "Testing game-service..."

code=$(curl -s -o /dev/null -w "%{http_code}" http://lugx-gaming-blue/games)
if [ "$code" -ne 200 ]; then
  echo "game-service /games failed: HTTP $code"
  exit 1
fi

# Test order-service
echo "Testing order-service..."
code=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://lugx-gaming-blue/orders)
if [ "$code" -ne 200 ]; then echo "order-service /orders POST failed: HTTP $code"; exit 1; fi

# Test analytics-service
echo "Testing analytics-service..."
code=$(curl -s -o /dev/null -w "%{http_code}" http://analytics.lugx-blue/health)
if [ "$code" -ne 200 ]; then echo "analytics-service /health failed: HTTP $code"; exit 1; fi
#code=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://lugx-gaming-blue/events)
#if [ "$code" -ne 200 ]; then echo "analytics-service /events POST failed: HTTP $code"; exit 1; fi

# Test frontend-service
echo "Testing frontend-service..."
code=$(curl -s -o /dev/null -w "%{http_code}" http://lugx-gaming-blue/)
if [ "$code" -ne 200 ]; then echo "frontend-service / failed: HTTP $code"; exit 1; fi

echo "All tests passed!"
