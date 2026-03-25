#!/usr/bin/env bash

set -e

LOG_FILE="/var/log/myddleware-startup.log"
mkdir -p /var/log
{
  echo "===== Myddleware Docker Startup $(date '+%Y-%m-%d %H:%M:%S') ====="

  mkdir -p var/cache var/log
  chmod -R 700 var/cache
  chown -R www-data:www-data var/cache
  chmod -R 700 var/log
  chown -R www-data:www-data var/log
  echo "[OK] Directory permissions set"

  ## Generate .env for Symfony from container environment variables
  ## (The .env file is gitignored; we generate it at runtime from docker-compose env vars)
  echo "[START] Generating .env from environment..."
  cat > /var/www/html/.env << ENVEOF
APP_ENV=${APP_ENV:-prod}
APP_DEBUG=${APP_DEBUG:-0}
APP_SECRET=${APP_SECRET:-changeme_set_a_real_secret}
DATABASE_URL=${DATABASE_URL:-mysql://root:secret@mysql:3306/myddleware?serverVersion=8.0}
CORS_ALLOW_ORIGIN=${CORS_ALLOW_ORIGIN:-^https?://(localhost|127\\.0\\.0\\.1)(:[0-9]+)?$}
MYDDLEWARE_VERSION=${MYDDLEWARE_VERSION:-dev}
ENVEOF
  echo "[OK] .env generated"

  ## Extend Hosts
  echo "[START] Updating hosts file..."
  if [ -f hosts ]; then
    cat hosts >> /etc/hosts 2>&1
    echo "[OK] Hosts file updated"
  else
    echo "[WARN] No hosts file found"
  fi

  ## Note: rsyslog is not used in Docker (requires systemd)
  ## Cron logs directly to /var/log/myddleware-cron.log instead
  echo "[INFO] Rsyslog not needed (cron logs directly to file)"

  ## Start cron daemon with logging
  echo "[START] Starting cron daemon..."
  if service cron start >> /tmp/cron-start.log 2>&1; then
    echo "[OK] Cron daemon started"
  else
    echo "[ERROR] Cron daemon failed to start"
    cat /tmp/cron-start.log
  fi

  ## Enable cron daemon logging
  echo "[START] Enabling cron daemon logging..."
  # Use sed to enable debug logging if available
  if [ -f /etc/default/cron ]; then
    sed -i 's/^#EXTRA_OPTS.*/EXTRA_OPTS="-L 2"/' /etc/default/cron || true
  fi

  ## Reload/verify cron to pick up configuration files
  echo "[START] Reloading cron daemon..."
  sleep 1
  service cron reload 2>/dev/null || true

  ## Verify cron configuration
  echo "[VERIFY] Cron configuration..."
  echo "Cron daemon status:"
  service cron status || echo "[WARN] Cron status check failed"

  echo "Checking /etc/cron.d/ directory:"
  ls -la /etc/cron.d/

  echo "Cron file contents:"
  cat /etc/cron.d/myddleware || echo "[WARN] Myddleware cron file not found"

  echo "Cron file permissions:"
  ls -la /etc/cron.d/myddleware || echo "[WARN] Myddleware cron file not found"

  echo "Cron daemon process:"
  pgrep -l cron || echo "[WARN] No cron process found"

  sleep 2
  echo "[OK] Cron daemon initialized"
  echo "===== Starting Apache ====="

} | tee -a "$LOG_FILE"

## Start Apache
echo "====[ START APACHE ]===="
apache2-foreground "$@"
