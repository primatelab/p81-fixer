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
LOCAL_DIR=/etc/Perimeter81/fixer
LOCAL_DOMAINS=$LOCAL_DIR/localdomains
HELPER_LIMITS=$LOCAL_DIR/helper-limits

install -m 0755 "$SRC_DIR/p81-split-dns" "$TARGET_DIR/p81-split-dns"
install -m 0755 "$SRC_DIR/p81-routes" "$TARGET_DIR/p81-routes"
install -m 0755 "$SRC_DIR/p81-drop-tproxy" "$TARGET_DIR/p81-drop-tproxy"
install -m 0755 "$SRC_DIR/p81-watch-helper" "$TARGET_DIR/p81-watch-helper"

cat >"$DISPATCHER_DIR/60-p81-fixer" <<'EOF'
#!/bin/bash
# Re-apply split DNS and keep the fixer daemons alive.
/usr/local/sbin/p81-drop-tproxy --daemon >/dev/null 2>&1 || true
/usr/local/sbin/p81-watch-helper --daemon >/dev/null 2>&1 || true
exec /usr/local/sbin/p81-split-dns --nm "$@"
EOF

chmod 0755 "$DISPATCHER_DIR/60-p81-fixer"

install -d -m 0755 "$LOCAL_DIR"
if [[ ! -e "$LOCAL_DOMAINS" ]]; then
  cat >"$LOCAL_DOMAINS" <<'EOF'
# Extra DNS suffixes pinned to the p81 link, in addition to the live policy.
# One suffix per line. A leading ~ is optional. Blank lines and # comments are ignored.
EOF
  chmod 0644 "$LOCAL_DOMAINS"
fi
if [[ ! -e "$HELPER_LIMITS" ]]; then
  cat >"$HELPER_LIMITS" <<'EOF'
# Kill p81daemonhelper when it crosses either limit.
# rss_mb is resident memory. cpu_pct is one core, sustained for cpu_strikes
# samples taken interval seconds apart.
rss_mb=1024
cpu_pct=80
cpu_strikes=3
interval=5
EOF
  chmod 0644 "$HELPER_LIMITS"
fi

/usr/local/sbin/p81-watch-helper --daemon || true

echo "Installed:"
echo "  /usr/local/sbin/p81-split-dns"
echo "  /usr/local/sbin/p81-routes"
echo "  /usr/local/sbin/p81-drop-tproxy"
echo "  /usr/local/sbin/p81-watch-helper"
echo "  /etc/NetworkManager/dispatcher.d/60-p81-fixer"
echo "  $LOCAL_DOMAINS"
echo "  $HELPER_LIMITS"
