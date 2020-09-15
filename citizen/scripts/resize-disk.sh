#!/bin/bash

cd /home/icon/citizen && docker-compose down
umount /dev/disk/by-id/scsi-0Linode_Volume_$LINODE_INSTANCE_REGION-$LINODE_ID-data
e2fsck -f /dev/disk/by-id/scsi-0Linode_Volume_$LINODE_INSTANCE_REGION-$LINODE_ID-data
resize2fs /dev/disk/by-id/scsi-0Linode_Volume_$LINODE_INSTANCE_REGION-$LINODE_ID-data
mount /dev/disk/by-id/scsi-0Linode_Volume_$LINODE_INSTANCE_REGION-$LINODE_ID-data /mnt/$LINODE_INSTANCE_REGION-$LINODE_ID-data
cd /home/icon/citizen && docker-compose up -d
