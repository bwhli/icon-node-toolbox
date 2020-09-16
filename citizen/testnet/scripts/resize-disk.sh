#!/bin/bash

LINODE_ID=$(cat /home/icon/.linode_vars/LINODE_ID)
LINODE_INSTANCE_REGION=$(cat /home/icon/.linode_vars/LINODE_INSTANCE_REGION)

echo $LINODE_ID
echo $LINODE_INSTANCE_REGION

cd /home/icon/citizen && docker-compose down
umount /dev/disk/by-id/scsi-0Linode_Volume_ctz-$LINODE_INSTANCE_REGION-$LINODE_ID-data
e2fsck -f /dev/disk/by-id/scsi-0Linode_Volume_ctz-$LINODE_INSTANCE_REGION-$LINODE_ID-data
resize2fs /dev/disk/by-id/scsi-0Linode_Volume_ctz-$LINODE_INSTANCE_REGION-$LINODE_ID-data
mount /dev/disk/by-id/scsi-0Linode_Volume_ctz-$LINODE_INSTANCE_REGION-$LINODE_ID-data /mnt/ctz-block-db
cd /home/icon/citizen && docker-compose up -d
