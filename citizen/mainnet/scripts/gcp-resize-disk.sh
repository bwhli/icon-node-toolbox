#!/bin/bash

# Set GCP variables.
INSTANCE_NAME=$(cat /home/icon/.gcp_vars/INSTANCE_NAME)
ZONE_ID=$(cat /home/icon/.gcp_vars/ZONE_ID)
REGION_ID=$(cat /home/icon/.gcp_vars/REGION_ID)

CURRENT_DISK_USAGE_PERCENT=$(df /home/icon/citizen/data | awk '{print $5}' | tail -n 1 | rev | cut -c 2- | rev)
CURRENT_DISK_USAGE_GB=$(df -h /home/icon/citizen/data | awk '{print $3}' | tail -n 1 | rev | cut -c 2- | rev)

gcloud compute disks resize $INSTANCE_NAME-citizen --size=206GB
