#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en sudo"
   exit 1
fi

# Paperless Installation
apt update
apt install -y python3 python3-pip python3-dev imagemagick fonts-liberation gnupg libpq-dev default-libmysqlclient-dev pkg-config libmagic-dev libzbar0 poppler-utils
apt install -y apt install unpaper ghostscript icc-profiles-free qpdf libxml2 pngquant zlib1g tesseract-ocr
apt install -y build-essential python3-setuptools python3-wheel
apt install -y redis-server
apt install -y postgresql

adduser paperless --system --home /opt/paperless --group

apt install -y curl
curl -O -L https://github.com/paperless-ngx/paperless-ngx/releases/download/v2.20.6/paperless-ngx-v2.20.6.tar.xz
tar -xf paperless-ngx-v2.20.6.tar.xz

mkdir /opt/paperless
cp -a ./paperless-ngx/. /opt/paperless

mkdir /opt/paperless/media
mkdir /opt/paperless/data
mkdir /opt/paperless/consume

cd /opt/paperless
apt install -y python3.13-venv
python3 -m venv venv
sudo -u paperless bash -c "source venv/bin/activate && pip install -r requirements.txt"
sudo -u paperless bash -c "source venv/bin/activate && cd src && python manage.py migrate"

cp scripts/paperless-*.service /etc/systemd/system

chown paperless:paperless /opt/paperless/media
chown paperless:paperless /opt/paperless/data
chown paperless:paperless /opt/paperless/consume

cat > "/etc/systemd/system/paperless-autostart.service" <<EOF
[Unit]
Description=Paperless autostart
[Service]
User=paperless
WorkingDirectory=/opt/paperless/src
ExecStart=/opt/paperless/venv/bin/python3 manage.py runserver
Restart=always
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
PrivateDevices=yes
RestrictSUIDSGID=true
ProtectSystem=strict
ReadWritePaths=/opt/paperless/data
ReadWritePaths=/opt/paperless/media
ReadWritePaths=/opt/paperless/consume
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_DAC_READ_SEARCH
PrivateTmp=yes
NoNewPrivileges=true
RestrictNamespaces=uts ipc pid user cgroup
ProtectHome=yes
MemoryDenyWriteExecute=yes
RestrictAddressFamilies=AF_INET AF_INET6
LockPersonality=yes
ProtectHostname=yes
ProtectClock=yes
ProtectKernelLogs=yes
RestrictRealtime=yes
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable paperless-autostart
systemctl start paperless-autostart

# Security System
apt install -y iptables

iptables -F
iptables -X

iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT # Connexion déja établie
iptables -A INPUT -p tcp -i eth0 --dport 8000 -j ACCEPT # Port 8000 de paperless
iptables -A INPUT -i lo -j ACCEPT # local
iptables -A INPUT -p icmp -j ACCEPT # ping
iptables -A INPUT -j DROP # bloque le reste

iptables -A OUTPUT -p icmp -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT # ping

iptables-save

apt install -y fail2ban
systemctl start fail2ban
systemctl enable fail2ban