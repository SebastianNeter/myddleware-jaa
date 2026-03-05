#!/usr/bin/env bash
set -euo pipefail

PATCH_ID="${1:-}"
[ -n "$PATCH_ID" ] || { echo "Uso: patches/apply_patch.sh <PATCH_ID>"; exit 1; }

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$PATCH_ID"

[ -d "$PATCH_DIR" ] || { echo "ERROR: no existe patch dir: $PATCH_DIR"; exit 2; }

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/patchlib.sh"

echo "== Patch: $PATCH_ID =="
echo "== Patch dir: $PATCH_DIR =="
echo "== APP_CONT=$APP_CONT DB_CONT=$DB_CONT DB_NAME=$DB_NAME =="
echo

echo "== 0) Precheck containers =="
patch_precheck_containers
echo "OK"
echo

if [ -f "$PATCH_DIR/apply.sh" ]; then
  echo "== 1) Ejecutando apply.sh del patch =="
  bash "$PATCH_DIR/apply.sh"
  echo "OK"
  echo
else
  echo "== 1) No hay apply.sh en el patch (skip) =="
  echo
fi

echo "== 2) Aplicando assets del patch (si hay) =="
patch_apply_assets "$PATCH_DIR"
echo

echo "== 3) Cache prod + restart app =="
docker exec "$APP_CONT" bash -lc "cd /var/www/html && php bin/console cache:clear --env=prod"
docker restart "$APP_CONT" >/dev/null
echo "OK"
echo

echo "== DONE patch $PATCH_ID =="
