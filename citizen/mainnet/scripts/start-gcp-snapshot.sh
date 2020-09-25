#!/bin/bash

INSTANCE_NAME=$(cat /home/icon/.gcp_vars/INSTANCE_NAME)
ZONE_ID=$(cat /home/icon/.gcp_vars/ZONE_ID)
REGION_ID=$(cat /home/icon/.gcp_vars/REGION_ID)

# Get latest block height.
LATEST_BLOCK_HEIGHT=$(curl -s http://127.0.0.1:9000/api/v1/avail/peer | jq '.block_height')
echo $LATEST_BLOCK_HEIGHT

# Stop node for snapshot.
sudo -u icon docker-compose -f /home/icon/citizen/docker-compose.yml down

# Unmount disk.
umount /dev/sdb

# Take snapshot.
gcloud compute disks snapshot $INSTANCE_NAME-citizen --snapshot-names=ctz-db-backup-bh$LATEST_BLOCK_HEIGHT --zone=$ZONE_ID --storage-location=us

# Mount disk.
mount -o discard,defaults /dev/sdb /home/icon/citizen

# Start node.
sudo -u icon docker-compose -f /home/icon/citizen/docker-compose.yml up -d
