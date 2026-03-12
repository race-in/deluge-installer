# Deluge Production Installer

Automated installer for **Deluge + libtorrent + ltConfig plugin** with systemd services and auto-start on reboot.

Repository: https://github.com/race-in/deluge-installer

---

## Features

* Automatic Deluge installation
* Automatic libtorrent installation
* ltConfig plugin auto install
* ltConfig plugin auto enable
* systemd service creation
* Auto start on reboot
* Automatic server IP detection
* Simple one-command installer

---

## Supported Systems

* Debian 11
* Debian 12
* Debian 13

Root access required.

---

# Quick Install (Recommended)

Copy and paste this command:

```bash
bash <(curl -s https://raw.githubusercontent.com/race-in/deluge-installer/main/install-deluge.sh)
```

The script will automatically:

* Install Deluge
* Install libtorrent
* Install ltConfig plugin
* Enable plugin
* Create systemd services
* Start Deluge

---

# Manual Installation

Clone repository

```bash
git clone https://github.com/race-in/deluge-installer.git
```

Enter directory

```bash
cd deluge-installer
```

Make script executable

```bash
chmod +x install-deluge.sh
```

Run installer

```bash
sudo ./install-deluge.sh
```

---

# Web Interface

After installation open:

```
http://SERVER-IP:8112
```

Default password:

```
deluge
```

---

# Service Management

Start Deluge

```bash
systemctl start deluged
```

Stop Deluge

```bash
systemctl stop deluged
```

Restart Deluge

```bash
systemctl restart deluged
```

Check service status

```bash
systemctl status deluged
```

---

# File Locations

Deluge configuration

```
~/.config/deluge/
```

Plugin directory

```
~/.config/deluge/plugins/
```

Systemd service files

```
/etc/systemd/system/deluged.service
/etc/systemd/system/deluge-web.service
```

---

# Troubleshooting

Restart services

```bash
systemctl restart deluged
systemctl restart deluge-web
```

Check logs

```bash
journalctl -u deluged -f
```

---

# Uninstall

Stop services

```bash
systemctl stop deluged
systemctl stop deluge-web
```

Remove packages

```bash
pip3 uninstall deluge libtorrent
```

Remove configuration (optional)

```bash
rm -rf ~/.config/deluge
```

---

# License

MIT License
