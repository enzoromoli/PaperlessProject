#!/bin/bash

source /opt/.env
export RESTIC_PASSWORD

# Do a zip file to compress data (Bonus)
mkdir -p /opt/paperless-zip-tmp
zip -r "/opt/paperless-zip-tmp/paperless-backup-$(date +%Y-%m-%d_%H-%M-%S).zip" /opt/paperless/data /opt/paperless/consume /opt/paperless/media

# Save data
restic --repo /opt/restic-repository backup /opt/paperless-zip-tmp
# Remove outdated data
restic --repo /opt/restic-repository forget --prune --keep-hourly 24 --keep-daily 7
# Push to the drive the changes
rclone sync /opt/restic-repository backup-paperless:

# Delete temp folder
rm -rf /opt/paperless-zip-tmp