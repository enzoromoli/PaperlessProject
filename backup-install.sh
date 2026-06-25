#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en sudo"
   exit 1
fi

# Install packages
apt update
apt install -y rclone restic cron

# Install zip
apt install -y zip

# Get RESTIC_PASSWORD env var
source .env
export RESTIC_PASSWORD

# Delete existing files
rm -rf /opt/restic-repository

# Init restic local respository
mkdir -p /opt/restic-repository
restic init --repo /opt/restic-repository

# Create rclone config linked to a google drive folder
rclone config delete backup-paperless
rclone config create backup-paperless drive
rclone config update backup-paperless root_folder_id 1SBAVA7RNcij2BSWb1pgbrXSAOLTx-YAf

# Move .env & backup-run.sh files where wanted
cp ./backup-run.sh /opt/backup-run.sh
cp ./.env /opt/.env

# Allow backup-run.sh execution
chmod +x /opt/backup-run.sh

# Add cron task configuration to execute backup-run.sh moved every hour
echo "0 * * * * root /opt/backup-run.sh" > /etc/cron.d/backup-paperless

# Allow reading of the file from everyone
chmod 644 /etc/cron.d/backup-paperless

# Start cron task
service cron start