#!/bin/bash

# Assign metadata files to script variables.
INSTANCE_ID=$(cat /home/icon/.gcp_vars/INSTANCE_ID)
INSTANCE_NAME=$(cat /home/icon/.gcp_vars/INSTANCE_NAME)
ZONE_ID=$(cat /home/icon/.gcp_vars/ZONE_ID)
REGION_ID=$(cat /home/icon/.gcp_vars/REGION_ID)
CTZ_NODE_TYPE=$(cat /home/icon/.gcp_vars/CTZ_NODE_TYPE)

# Create disk with latest ctz-db snapshot.
GCP_SNAPSHOT_API_REQUEST=$(gcloud compute snapshots list --sort-by=~creationTimestamp --format=json --limit=1 --filter="status:READY AND name ~ ctz-db-backup")
GCP_SNAPSHOT_NAME=$(echo $GCP_SNAPSHOT_API_REQUEST | jq '.[].name' --raw-output)
GCP_SNAPSHOT_SIZE=$(echo $GCP_SNAPSHOT_API_REQUEST | jq '.[].diskSizeGb' --raw-output)
/snap/bin/gcloud compute disks create $INSTANCE_NAME-snapshot --zone=$ZONE_ID --size=${GCP_SNAPSHOT_SIZE}GB --source-snapshot=$GCP_SNAPSHOT_NAME --type=pd-ssd --quiet
/snap/bin/gcloud compute instances attach-disk $INSTANCE_NAME --disk=$INSTANCE_NAME-snapshot --zone=$ZONE_ID --quiet
/snap/bin/gcloud compute instances set-disk-auto-delete $INSTANCE_NAME --auto-delete --disk=$INSTANCE_NAME-snapshot --zone=$ZONE_ID --quiet
mkdir -p /home/icon/citizen/snapshot
mount -o discard,defaults /dev/sdc /home/icon/citizen/snapshot
chown -R icon:icon /home/icon/citizen/snapshot

# Create disk for leveldb archive.
/snap/bin/gcloud compute disks create $INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --size=${GCP_SNAPSHOT_SIZE}GB --type=pd-ssd --quiet
# Attach disk to VM.
/snap/bin/gcloud compute instances attach-disk $INSTANCE_NAME --disk=$INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --quiet
# Set disk to auto-delete if VM is deleted.
/snap/bin/gcloud compute instances set-disk-auto-delete $INSTANCE_NAME --auto-delete --disk=$INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --quiet

# Create mount directory.
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdd
mkdir -p /home/icon/citizen/leveldb-archive
mount -o discard,defaults /dev/sdd /home/icon/citizen/leveldb-archive
chown -R icon:icon /home/icon/citizen/leveldb-archive

# Create tar.lz4 archive with .storage and .score_data folders (leveldb archive).
ARCHIVE_FILE_NAME="MainctzNet_data-$(date +"%Y%m%d_%H%M").tar"
tar cf /home/icon/citizen/leveldb-archive/$ARCHIVE_FILE_NAME /home/icon/citizen/snapshot/mainnet/.storage /home/icon/citizen/snapshot/mainnet/.score_data

# Create snapshot of leveldb archive disk.
/snap/bin/gcloud compute disks snapshot $INSTANCE_NAME-leveldb-archive --snapshot-names=ctz-leveldb-archive-$(date +"%Y%m%d-%H%M") --zone=$ZONE_ID --storage-location=us  --quiet

# Unmout snapshot and leveldb archive disks.
umount -l /home/icon/citizen/snapshot
umount -l /home/icon/citizen/leveldb-archive

# Detach and delete snapshot and leveldb archive disks.
/snap/bin/gcloud compute instances detach-disk $INSTANCE_NAME --disk=$INSTANCE_NAME-snapshot --zone=$ZONE_ID --quiet
/snap/bin/gcloud compute instances detach-disk $INSTANCE_NAME --disk=$INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --quiet
/snap/bin/gcloud compute disks delete $INSTANCE_NAME-snapshot --zone=$ZONE_ID --quiet
/snap/bin/gcloud compute disks delete $INSTANCE_NAME-leveldb-archive --zone=$ZONE_ID --quiet
