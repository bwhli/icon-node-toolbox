#!/bin/bash

# Set GCP variables.
INSTANCE_NAME=$(cat /home/icon/.gcp_vars/INSTANCE_NAME)
ZONE_ID=$(cat /home/icon/.gcp_vars/ZONE_ID)
REGION_ID=$(cat /home/icon/.gcp_vars/REGION_ID)

# Only keep 4 newest snapshots, delete the rest.
CURRENT_SNAPSHOTS=$(/snap/bin/gcloud compute snapshots list --format="json(name)" --sort-by=~creationTimestamp --filter="name ~ ctz-db-backup")
CURRENT_SNAPSHOTS_LENGTH=$(echo $CURRENT_SNAPSHOTS | jq 'length')

if [ $CURRENT_SNAPSHOTS_LENGTH -ge 5 ]; then
  for i in $( seq 0 $(( $CURRENT_SNAPSHOTS_LENGTH - 1 )) ); do
    if [ $i -gt 3 ]; then
      SNAPSHOT_NAME=$(echo $CURRENT_SNAPSHOTS | jq -r --arg index "$i" '.[$index|tonumber].name')
      echo "Deleting $SNAPSHOT_NAME..."
      /snap/bin/gcloud compute snapshots delete $SNAPSHOT_NAME --quiet
    fi
  done
fi

# Get latest block height.
LATEST_BLOCK_HEIGHT=$(curl -s http://127.0.0.1:9000/api/v1/avail/peer | jq '.block_height')

# Stop node for snapshot.
sudo -u icon docker-compose -f /home/icon/citizen/docker-compose.yml down

# Unmount disk.
umount /dev/sdb

# Take snapshot.
/snap/bin/gcloud compute disks snapshot $INSTANCE_NAME-citizen --snapshot-names=ctz-db-backup-bh$LATEST_BLOCK_HEIGHT --zone=$ZONE_ID --storage-location=us  --quiet

# Mount disk.
mount -o discard,defaults /dev/sdb /home/icon/citizen/data

# Start node.
sudo -u icon docker-compose -f /home/icon/citizen/docker-compose.yml up -d
