#!/usr/bin/env bash

set -e

echo "================================="
echo "Deluge Production Installer"
echo "================================="

read -p "Enter the user that will run Deluge: " DELUGE_USER

if id "$DELUGE_USER" >/dev/null 2>&1; then
    echo "User exists: $DELUGE_USER"
else
    echo "User does not exist"
    read -p "Create user $DELUGE_USER ? (y/n): " CREATE

    if [ "$CREATE" = "y" ]; then
        useradd -m "$DELUGE_USER"
    else
        echo "Please create the user manually."
        exit 1
    fi
fi

HOME_DIR=$(eval echo "~$DELUGE_USER")

echo "Updating system..."
apt update -y

echo "Installing dependencies..."
apt install -y python3 python3-pip wget curl

echo "Allow pip system install..."
pip3 config set global.break-system-packages true

echo "Installing libtorrent..."
pip3 install libtorrent

echo "Installing Deluge..."
pip3 install deluge

PLUGIN_DIR="$HOME_DIR/.config/deluge/plugins"

echo "Creating plugin directory..."
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

echo "Stopping any existing services..."
systemctl stop deluged 2>/dev/null || true
systemctl stop deluge-web 2>/dev/null || true
systemctl stop deluged@$DELUGE_USER 2>/dev/null || true

echo "Enabling services..."
systemctl enable deluged >/dev/null 2>&1 || true
systemctl enable deluge-web >/dev/null 2>&1 || true

echo "Starting Deluge daemon..."
systemctl start deluged

echo "Waiting for daemon..."
sleep 6

echo "Starting Web UI..."
systemctl start deluge-web

echo "Enabling ltConfig plugin..."
sudo -u "$DELUGE_USER" deluge-console "plugin -e ltConfig" >/dev/null 2>&1 || true

systemctl restart deluged
systemctl restart deluge-web

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================="
echo "INSTALLATION COMPLETE"
echo "================================="
echo ""
echo "Deluge running as: $DELUGE_USER"
echo "WebUI: http://$IP:8112"
echo "Password: deluge"
echo ""
