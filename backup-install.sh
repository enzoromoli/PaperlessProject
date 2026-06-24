#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en sudo"
   exit 1
fi

apt update
apt install -y rclone restic cron

source .env
export RESTIC_PASSWORD

mkdir -p /opt/restic-repository
restic init --repo /opt/restic-repository

rclone config create backup-paperless drive --drive-root-folder-id 1Rvoyn96zZRJy8oMPaCB51RdwIFf23Cjy
cp ./backup-run.sh /opt/backup-run.sh
chmod +x /opt/backup-run.sh

cp ./.env /opt/.env

echo "0 * * * * /opt/backup-run.sh" > /etc/cron.d/backup-paperless
chmod 644 /etc/cron.d/backup-paperless

service cron start