#!/bin/bash
zones=("us-central1-a" "us-central1-b" "us-central1-c" "us-central1-f")

echo "Probing Google Cloud for available T4 GPUs..."
for zone in "${zones[@]}"; do
  echo -n "Testing $zone... "
  
  # Try to create a dummy VM
  gcloud compute instances create gpu-test-vm \
    --zone=$zone \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --quiet > /dev/null 2>&1
    
  if [ $? -eq 0 ]; then
    echo "✅ IN STOCK!"
    echo "Cleaning up dummy VM..."
    gcloud compute instances delete gpu-test-vm --zone=$zone --quiet > /dev/null 2>&1
    echo "========================================="
    echo "WINNER: Update your main.tf to use $zone"
    echo "========================================="
    break
  else
    echo "❌ OUT OF STOCK."
  fi
done
