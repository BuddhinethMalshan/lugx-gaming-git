#!/bin/bash

# Defined variables
CLICKHOUSE_URL="http://localhost:8126/?user=default&password=clickhouse_password&query=SELECT%20*%20FROM%20web_analytics%20FORMAT%20CSV"
S3_BUCKET="lugx-gaming-analytics"
S3_KEY="analytics_data.csv"
OUTPUT_FILE="analytics_data.csv"
SLEEP_INTERVAL=180
VENV_PATH="$HOME/lugx-venv/bin"

while true; do
  echo "Exporting data at $(date +%Y-%m-%d_%H-%M-%S)..."
  # Check if curl is installed
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not installed. Please install curl (e.g., 'sudo apt-get install curl')."
    exit 1
  fi
  # Fetch data from ClickHouse
  curl -f "$CLICKHOUSE_URL" -o "$OUTPUT_FILE" 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "Successfully retrieved data from ClickHouse to $OUTPUT_FILE"
    # Check if virtual environment exists
    if [ ! -f "$VENV_PATH/aws" ]; then
      echo "Error: AWS CLI is not installed in virtual environment at $VENV_PATH. Run 'source ~/lugx-venv/bin/activate && pip install awscli'."
      exit 1
    fi
    # Activate virtual environment and upload to S3
    source "$VENV_PATH/activate"
    # Check AWS CLI configuration
    if ! "$VENV_PATH/aws" sts get-caller-identity >/dev/null 2>&1; then
      echo "Error: AWS CLI is not configured. Run 'source ~/lugx-venv/bin/activate && aws configure'."
      exit 1
    fi
    # Upload to S3
    "$VENV_PATH/aws" s3 cp "$OUTPUT_FILE" "s3://$S3_BUCKET/$S3_KEY" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "Successfully uploaded data to S3: s3://$S3_BUCKET/$S3_KEY"
    else
      echo "Error: Failed to upload to S3. Check S3 bucket permissions and network."
      exit 1
    fi
    deactivate
  else
    echo "Error: Failed to retrieve data from ClickHouse. Check if 'kubectl port-forward svc/clickhouse-service -n lugx-gaming 8126:8123' is running."
    exit 1
  fi
  sleep "$SLEEP_INTERVAL"
done
