#!/usr/bin/env bash

### This software is (unintentionally and unavoidably) anti-bossware, so use at own risk.  ###
### These scripts stop Perimeter81 crashing your DNS resolver every 5 minutes.             ###
### Unfortunately, it has to circumvent corporate surveillance features in order to do so. ###

set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

SRC_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TARGET_DIR=/usr/local/sbin
DISPATCHER_DIR=/etc/NetworkManager/dispatcher.d

install -m 0755 "$SRC_DIR/p81-split-dns" "$TARGET_DIR/p81-split-dns"
install -m 0755 "$SRC_DIR/p81-routes" "$TARGET_DIR/p81-routes"
install -m 0755 "$SRC_DIR/p81-drop-tproxy" "$TARGET_DIR/p81-drop-tproxy"

cat >"$DISPATCHER_DIR/60-p81-fixer" <<'EOF'
#!/bin/bash
# Re-apply split DNS and keep TPROXY scrubber daemon alive.
/usr/local/sbin/p81-drop-tproxy --daemon >/dev/null 2>&1 || true
exec /usr/local/sbin/p81-split-dns --nm "$@"
EOF

chmod 0755 "$DISPATCHER_DIR/60-p81-fixer"

echo "Installed:"
echo "  /usr/local/sbin/p81-split-dns"
echo "  /usr/local/sbin/p81-routes"
echo "  /usr/local/sbin/p81-drop-tproxy"
echo "  /etc/NetworkManager/dispatcher.d/60-p81-fixer"
