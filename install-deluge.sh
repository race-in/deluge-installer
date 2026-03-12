#!/usr/bin/env bash

set -e

echo "================================="
echo "Deluge Production Installer"
echo "================================="

# Detect existing Deluge
if command -v deluge >/dev/null 2>&1; then
    echo "Existing Deluge installation detected."
    read -p "Do you want to remove it? (y/n): " CLEAN

    if [ "$CLEAN" = "y" ]; then
        echo "Cleaning old installation..."

        pkill deluged 2>/dev/null || true
        pkill deluge-web 2>/dev/null || true

        rm -rf /usr/local/bin/deluge*
        rm -rf /usr/local/lib/python*/dist-packages/deluge*
        rm -rf /usr/local/lib/python*/dist-packages/libtorrent*
        rm -rf ~/.config/deluge
        rm -rf /root/.config/deluge
    fi
fi

read -p "Enter the user that will run Deluge: " DELUGE_USER

if id "$DELUGE_USER" >/dev/null 2>&1; then
    echo "User exists: $DELUGE_USER"
else
    echo "User does not exist."
    read -p "Create user $DELUGE_USER ? (y/n): " CREATEUSER

    if [ "$CREATEUSER" = "y" ]; then
        useradd -m "$DELUGE_USER"
    else
        echo "Please create the user manually and rerun."
        exit 1
    fi
fi

HOME_DIR=$(eval echo "~$DELUGE_USER")

echo "Updating system..."
apt update -y

echo "Installing dependencies..."
apt install -y python3 python3-pip git wget curl

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
wget -O "$PLUGIN_DIR/ltConfig-2.0.0.egg" https://github.com/ratanakvlun/deluge-ltconfig/releases/download/v2.0.0/ltConfig-2.0.0.egg

chown -R "$DELUGE_USER:$DELUGE_USER" "$HOME_DIR/.config"

echo "Creating systemd services..."

cat <<EOT > /etc/systemd/system/deluged.service
[Unit]
Description=Deluge Daemon
After=network.target

[Service]
User=$DELUGE_USER
ExecStart=/usr/local/bin/deluged -d
Restart=always

[Install]
WantedBy=multi-user.target
EOT

cat <<EOT > /etc/systemd/system/deluge-web.service
[Unit]
Description=Deluge Web UI
After=deluged.service

[Service]
User=$DELUGE_USER
ExecStart=/usr/local/bin/deluge-web
Restart=always

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable deluged
systemctl enable deluge-web

echo "Starting Deluge..."
systemctl start deluged
sleep 5
systemctl start deluge-web

echo "Enabling ltConfig plugin..."

sudo -u "$DELUGE_USER" python3 - <<PY
import json, os
conf="$HOME_DIR/.config/deluge/core.conf"

if os.path.exists(conf):
    data=json.load(open(conf))
else:
    data={}

plugins=data.get("enabled_plugins",[])

if "ltConfig" not in plugins:
    plugins.append("ltConfig")

data["enabled_plugins"]=plugins

json.dump(data,open(conf,"w"),indent=2)
print("ltConfig enabled.")
PY

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
