#!/usr/bin/env bash

set -e

echo "================================="
echo "Deluge Production Installer v3"
echo "================================="

read -p "Enter the user that will run Deluge: " DELUGE_USER

if id "$DELUGE_USER" >/dev/null 2>&1; then
    echo "User exists: $DELUGE_USER"
else
    echo "User does not exist."
    read -p "Create user $DELUGE_USER ? (y/n): " CREATE

    if [ "$CREATE" = "y" ]; then
        useradd -m "$DELUGE_USER"
    else
        echo "Create the user manually."
        exit 1
    fi
fi

HOME_DIR=$(eval echo "~$DELUGE_USER")
DOWNLOAD_DIR="$HOME_DIR/downloads"

echo "Updating system..."
apt update -y

echo "Installing dependencies..."
apt install -y python3 python3-pip wget curl jq

echo "Allow pip system install..."
pip3 config set global.break-system-packages true

echo "Installing libtorrent..."
pip3 install libtorrent

echo "Installing Deluge..."
pip3 install deluge

echo "Creating download directory..."
mkdir -p "$DOWNLOAD_DIR"
chown -R "$DELUGE_USER:$DELUGE_USER" "$DOWNLOAD_DIR"

PLUGIN_DIR="$HOME_DIR/.config/deluge/plugins"

echo "Creating config directories..."
mkdir -p "$PLUGIN_DIR"

echo "Downloading ltConfig plugin..."
wget -O "$PLUGIN_DIR/ltConfig-2.0.0.egg" \
https://github.com/ratanakvlun/deluge-ltconfig/releases/download/v2.0.0/ltConfig-2.0.0.egg

chown -R "$DELUGE_USER:$DELUGE_USER" "$HOME_DIR/.config"

echo "Creating systemd services..."

cat <<EOF > /etc/systemd/system/deluged.service
[Unit]
Description=Deluge Daemon
After=network.target

[Service]
User=$DELUGE_USER
ExecStart=/usr/local/bin/deluged -d
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/deluge-web.service
[Unit]
Description=Deluge Web UI
After=deluged.service

[Service]
User=$DELUGE_USER
ExecStart=/usr/local/bin/deluge-web
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
systemctl daemon-reload

echo "Stopping old services..."
systemctl stop deluged 2>/dev/null || true
systemctl stop deluge-web 2>/dev/null || true

echo "Enabling services..."
systemctl enable deluged
systemctl enable deluge-web

echo "Starting Deluge daemon..."
systemctl start deluged

echo "Waiting for daemon..."
sleep 6

echo "Starting Web UI..."
systemctl start deluge-web

echo "Configuring Deluge..."

CORECONF="$HOME_DIR/.config/deluge/core.conf"

if [ -f "$CORECONF" ]; then
    sed -i 's|"download_location":.*|"download_location": "'"$DOWNLOAD_DIR"'",|' "$CORECONF"
fi

echo "Enabling ltConfig plugin..."
sudo -u "$DELUGE_USER" deluge-console "plugin -e ltConfig" >/dev/null 2>&1 || true

echo "Restarting services..."
systemctl restart deluged
systemctl restart deluge-web

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================="
echo "INSTALLATION VERIFIED"
echo "================================="

if systemctl is-active --quiet deluged; then
echo "Deluge daemon: OK"
else
echo "Deluge daemon: FAIL"
fi

if systemctl is-active --quiet deluge-web; then
echo "WebUI: OK"
else
echo "WebUI: FAIL"
fi

if [ -d "$DOWNLOAD_DIR" ]; then
echo "Download folder: OK"
else
echo "Download folder: FAIL"
fi

echo ""
echo "Download path: $DOWNLOAD_DIR"
echo "WebUI: http://$IP:8112"
echo "Password: deluge"
echo ""
