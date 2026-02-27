#!/bin/bash

# Check presence of utilities
for util in curl jq base64; do
  if ! command -v $util &> /dev/null; then
    echo "$util could not be found; ensure that it is installed"
    exit 1
  fi
done

source tests/common.sh

# Wait until the gatway is up and running (max 5 seconds)
echo "Waiting for the gateway $GATEWAY_URL to be up and running..."
for i in {1..5}; do
  if curl -4 -k -s "$GATEWAY_URL" > /dev/null; then
    break
  fi
  sleep 1
done

if [ $i -eq 5 ]; then
  echo "Gateway did not start up in time"
  exit 1
fi

for test in tests/test_*.sh; do
  echo "Running $test..."
  bash "$test"
done
