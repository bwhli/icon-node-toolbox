#!/bin/bash

# Assign metadata files to script variables.
INSTANCE_ID=$(cat /home/icon/.gcp_vars/INSTANCE_ID)
INSTANCE_NAME=$(cat /home/icon/.gcp_vars/INSTANCE_NAME)
ZONE_ID=$(cat /home/icon/.gcp_vars/ZONE_ID)
REGION_ID=$(cat /home/icon/.gcp_vars/REGION_ID)
CTZ_NODE_TYPE=$(cat /home/icon/.gcp_vars/CTZ_NODE_TYPE)

# Create disk with latest ctz-db snapshot.

# Create variable for archive filename.
ARCHIVE_FILE_NAME="MainctzNet_data-$(date +"%Y%m%d_%H%M").tar.lz4"

# Create tar.lz4 archive with .storage and .score_data folders (leveldb archive).
tar cf - /home/icon/citizen/snapshot/mainnet/.storage /home/icon/citizen/snapshot/mainnet/.score_data | lz4 - $ARCHIVE_FILE_NAME

# Get filesize of leveldb archive.
ARCHIVE_FILE_SIZE=$(du -h MainctzNet_data-20200925_0100.tar.lz4 | awk '{print $1}' | rev | cut -c 2- | rev)

# Create disk for leveldb archive.
/snap/bin/gcloud compute disks create $INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --size=$(( $ARCHIVE_FILE_SIZE + 1 ))GB --type=pd-ssd --quiet
# Attach disk to VM.
/snap/bin/gcloud compute instances attach-disk $INSTANCE_NAME --disk=$INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --quiet
# Set disk to auto-delete if VM is deleted.
/snap/bin/gcloud compute instances set-disk-auto-delete $INSTANCE_NAME --auto-delete --disk=$INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --quiet
# Create mount directory.
mkdir -p /home/icon/citizen/leveldb-archive
mount -o discard,defaults /dev/sdd /home/icon/citizen/leveldb-archive
chown -R icon:icon /home/icon/citizen/leveldb-archive
