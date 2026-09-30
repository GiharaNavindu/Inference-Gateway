#!/bin/bash
zones=("us-central1-a" "us-central1-b" "us-central1-c" "us-east4-a" "us-east4-b" "us-east4-c")

echo "Probing for modern NVIDIA L4 GPUs (g2-standard-4)..."
for zone in "${zones[@]}"; do
  echo -n "Checking $zone... "
  
  output=$(gcloud compute instances create l4-probe-vm \
    --zone="$zone" \
    --machine-type=g2-standard-4 \
    --accelerator=type=nvidia-l4,count=1 \
    --maintenance-policy=TERMINATE \
    --quiet 2>&1)
    
  if [ $? -eq 0 ]; then
    echo "✅ IN STOCK & QUOTA APPROVED!"
    gcloud compute instances delete l4-probe-vm --zone="$zone" --quiet > /dev/null 2>&1
    echo "========================================="
    echo "WINNING ZONE: $zone"
    echo "========================================="
    exit 0
  else
    if echo "$output" | grep -q "QUOTA_EXCEEDED"; then
      echo "❌ Quota limit reached."
      echo "We need to request an L4 quota in the GCP Console."
      exit 1
    elif echo "$output" | grep -q "ZONE_RESOURCE_POOL_EXHAUSTED"; then
      echo "Stockout."
    else
      echo "Unavailable."
    fi
  fi
done
