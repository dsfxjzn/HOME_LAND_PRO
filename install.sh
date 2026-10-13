#!/usr/bin/env bash
set -euo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Run as root"; exit 1; }
apt-get update
apt-get install -y lua5.4 lua-socket lua-sec lua-cjson ca-certificates
APP=/opt/homeland
install -d -m 0750 "$APP"
if [[ -f "$APP/data.json" ]]; then cp -a "$APP/data.json" "$APP/data.json.backup.$(date +%Y%m%d%H%M%S)"; fi
install -m 0640 bot.lua "$APP/bot.lua"
touch "$APP/data.json"; chmod 0600 "$APP/data.json"
[[ -s /etc/homeland.env ]] && chmod 0600 /etc/homeland.env || echo "Create /etc/homeland.env with BOT_TOKEN and DATA_FILE before starting."
cat > /etc/systemd/system/homeland.service <<'UNIT'
[Unit]
Description=HOME LAND PRO Telegram Bot
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
User=root
WorkingDirectory=/opt/homeland
EnvironmentFile=/etc/homeland.env
ExecStart=/usr/bin/lua5.4 /opt/homeland/bot.lua
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ReadWritePaths=/opt/homeland
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable homeland
echo "Updated files and service. Review config, then: systemctl restart homeland"
