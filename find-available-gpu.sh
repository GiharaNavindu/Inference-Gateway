#!/bin/bash

# Target regions with quota limit 1
test_zones=(
  "us-central1-a" "us-central1-b" "us-central1-c" "us-central1-f"
  "us-east1-b" "us-east1-c" "us-east1-d"
  "us-west1-a" "us-west1-b"
  "europe-west4-a" "europe-west4-b" "europe-west4-c"
  "asia-east1-a" "asia-east1-b" "asia-east1-c"
  "asia-southeast1-a" "asia-southeast1-b" "asia-southeast1-c"
)

echo "Searching for an active T4 GPU allocation..."

for zone in "${test_zones[@]}"; do
  echo -n "Checking $zone... "
  
  output=$(gcloud compute instances create gpu-probe-vm \
    --zone="$zone" \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --maintenance-policy=TERMINATE \
    --quiet 2>&1)
    
  if [ $? -eq 0 ]; then
    echo "IN STOCK!"
    echo "Cleaning up probe VM in $zone..."
    gcloud compute instances delete gpu-probe-vm --zone="$zone" --quiet > /dev/null 2>&1
    
    # Extract the region (e.g., us-east1 from us-east1-b)
    region=$(echo "$zone" | sed 's/-[a-z]$//')
    
    echo ""
    echo "=============================================="
    echo "WINNING LOCATION FOUND:"
    echo "Region: $region"
    echo "Zone:   $zone"
    echo "=============================================="
    exit 0
  else
    if echo "$output" | grep -q "ZONE_RESOURCE_POOL_EXHAUSTED"; then
      echo "No capacity (stockout)."
    elif echo "$output" | grep -q "QUOTA_EXCEEDED"; then
      echo "Quota limit reached."
    else
      echo "Unavailable."
    fi
  fi
done

echo "No available capacity found in tested zones."
