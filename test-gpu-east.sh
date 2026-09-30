#!/bin/bash
zones=("us-east4-a" "us-east4-b" "us-east4-c")

echo "Probing Virginia (us-east4) for available T4 GPUs..."
for zone in "${zones[@]}"; do
  echo -n "Testing $zone... "
  
  gcloud compute instances create gpu-test-vm \
    --zone=$zone \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --maintenance-policy=TERMINATE \
    --quiet
    
  if [ $? -eq 0 ]; then
    echo "✅ IN STOCK!"
    echo "Cleaning up dummy VM..."
    gcloud compute instances delete gpu-test-vm --zone=$zone --quiet
    echo "========================================="
    echo "WINNER: Update your main.tf to use $zone"
    echo "========================================="
    break
  else
    echo "❌ FAILED (See error above)."
  fi
done
