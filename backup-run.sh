#!/bin/bash

source /opt/.env
export RESTIC_PASSWORD

restic --repo /opt/restic-repository backup /opt/paperless
restic --repo /opt/restic-repository forget --prune --keep-hourly 24 --keep-daily 7
rclone sync /opt/restic-repository backup-paperless: