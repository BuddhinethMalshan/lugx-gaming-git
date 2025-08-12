#!/bin/bash

# Ensure lugx-gaming (Blue) namespace exists and is deployed
echo "Ensuring lugx-gaming (Blue) namespace is ready..."
minikube kubectl -- get namespace lugx-gaming || minikube kubectl -- create namespace lugx-gaming
minikube kubectl -- apply -f kubernetes/ -n lugx-gaming --validate=false

# Prompt before cleaning up lugx-gaming-blue if it exists
if minikube kubectl -- get namespace lugx-gaming-blue &> /dev/null; then
  read -p "Current lugx-gaming-blue is live. Delete it for new deployment? (y/n): " choice
  if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo "Deployment aborted to protect live environment."
    exit 1
  fi
  echo "Cleaning up previous lugx-gaming-blue deployments..."
  minikube kubectl -- delete namespace lugx-gaming-blue --ignore-not-found
else
  echo "No existing lugx-gaming-blue namespace found. Proceeding..."
fi

# Create lugx-gaming-blue namespace
echo "Creating lugx-gaming-blue (Green) namespace..."
minikube kubectl -- get namespace lugx-gaming-blue || minikube kubectl -- create namespace lugx-gaming-blue

# Copy Blue to Green for a clean start and create backup
echo "Preparing lugx-gaming-blue environment..."
cp -r kubernetes/ lugx-gaming-blue/
cp -r kubernetes/ lugx-gaming-blue_backup/

# Backup original ingress.yaml
echo "Backing up original ingress.yaml..."
cp lugx-gaming-blue/ingress.yaml lugx-gaming-blue/bak-ingress

# Update namespace in all files except ingress.yaml
echo "Updating namespaces in manifests..."
for file in lugx-gaming-blue/*.yaml; do
  if [[ "$(basename "$file")" != "ingress.yaml" ]]; then
    yq eval '.metadata.namespace = "lugx-gaming-blue"' -i "$file"
  fi
done


echo "Updating container images for Green deployment..."

for file in lugx-gaming-blue/*-deployment.yaml; do
  filename=$(basename "$file")

  # Skip clickhouse and postgres
  if [[ "$filename" == "clickhouse-deployment.yaml" || "$filename" == "postgres-deployment.yaml" ]]; then
    continue
  fi

  # Derive base name
  service_base=$(basename "$file" -deployment.yaml)

  # Handle special cases
  if [[ "$service_base" == "analytics-service" ]]; then
    image_name="buddhinethmalshan/lugx-analytics-service:blue"
  elif [[ "$service_base" == "frontend" ]]; then
    image_name="buddhinethmalshan/lugx-frontend-service:blue"
  else
    image_name="buddhinethmalshan/lugx-${service_base}:blue"
  fi

  echo "Setting image in $file to $image_name"
  yq eval ".spec.template.spec.containers[0].image = \"${image_name}\"" -i "$file"
done



echo "Updating Ingress manifest..."
#!/bin/bash

set -e

INGRESS_FILE="lugx-gaming-blue/ingress.yaml"
INGRESS_NAME="lugx-ingress"
NAMESPACE="lugx-gaming-blue"

echo "🔧 Updating $INGRESS_FILE with new Ingress definition..."

# Overwrite the ingress.yaml file with new content
cat <<EOF > "$INGRESS_FILE"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $INGRESS_NAME
  namespace: $NAMESPACE
spec:
  rules:
  - host: lugx-gaming-blue
    http:
      paths:
      - path: /games
        pathType: Prefix
        backend:
          service:
            name: game-service
            port:
              number: 3000
      - path: /orders
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  - host: analytics.lugx-blue
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: lugx-analytics-service
            port:
              number: 3000
EOF

# Ensure namespace exists
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo "Namespace '$NAMESPACE' does not exist. Aborting."
  exit 1
fi



# Delete existing ingress if it exists
if kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo "Deleting existing Ingress..."
  kubectl delete ingress "$INGRESS_NAME" -n "$NAMESPACE"
fi

# Apply new Ingress
echo "Applying new Ingress from $INGRESS_FILE..."
kubectl apply -f "$INGRESS_FILE"
echo "✅ Ingress applied successfully in namespace '$NAMESPACE'."




# Deploy to Green
echo "Deploying to lugx-gaming-blue namespace..."
minikube kubectl -- apply -f lugx-gaming-blue/ -n lugx-gaming-blue --validate=false

# Wait for pods to be ready (extended wait)
echo "Waiting for pods to be ready in Green environment (up to 5 minutes)..."

max_wait_time=300  # seconds
interval=10        # seconds
elapsed=0

while [ $elapsed -lt $max_wait_time ]; do
  not_ready=$(minikube kubectl -- get pods -n lugx-gaming-blue --no-headers | grep -v 'Running\|Completed' | wc -l)
  
  if [ "$not_ready" -eq 0 ]; then
    echo "✅ All pods are ready!"
    break
  else
    echo "Waiting for pods... ($elapsed/$max_wait_time seconds)"
    sleep $interval
    elapsed=$((elapsed + interval))
  fi
done

if [ $elapsed -ge $max_wait_time ]; then
  echo "Timeout: Some pods did not become ready within $max_wait_time seconds."
  minikube kubectl -- get pods -n lugx-gaming-blue
  exit 1
fi

# Allow time for services to stabilize
echo "Waiting additional 60 seconds for services to stabilize..."
sleep 60

# Run integration tests
echo "Running integration tests..."
chmod +x ./tests/integration-test.sh
./tests/integration-test.sh | tee integration-test.log
test_result=${PIPESTATUS[0]}

# Swap or rollback
if [ $test_result -eq 0 ]; then
  echo "✅ Tests passed. Deployment to lugx-gaming-blue completed successfully!"
else
  echo "Tests failed. Rolling back to previous deployment..."
  
  # Rollback logic (optional: uncomment ingress restore if needed)
  # mv lugx-gaming-blue/ingress.yaml lugx-gaming-blue/bak-ingress.yaml

  minikube kubectl -- apply -f lugx-gaming-blue/ -n lugx-gaming-blue --validate=false
  minikube kubectl -- apply -f kubernetes/ -n lugx-gaming --validate=false
  minikube kubectl -- delete namespace lugx-gaming-blue --ignore-not-found
  rm -r lugx-gaming-blue/ lugx-gaming-blue_backup/
  echo "Rollback complete. Check integration-test.log for errors."
  exit 1
fi
