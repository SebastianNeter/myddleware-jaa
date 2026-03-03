#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="$PATCH_DIR/files"

APP_CONT="${APP_CONT:-myddleware-myddleware-1}"
DB_CONT="${DB_CONT:-myddleware-mysql-1}"
DB_NAME="${DB_NAME:-myddleware}"

TS="$(date +%F_%H%M%S)"

echo "== Patch dir: $PATCH_DIR"
echo "== App container: $APP_CONT"
echo "== DB container:  $DB_CONT"
echo "== DB name:       $DB_NAME"
echo

echo "== 0) Precheck containers =="
docker ps --format '{{.Names}}' | grep -qx "$APP_CONT" || { echo "ERROR: no existe container $APP_CONT"; exit 10; }
docker ps --format '{{.Names}}' | grep -qx "$DB_CONT"  || { echo "ERROR: no existe container $DB_CONT"; exit 11; }
echo "OK"
echo

echo "== 1) Verifico que existan los archivos requeridos =="
[ -f "$FILES_DIR/moodle_custom.php" ] || { echo "ERROR: falta $FILES_DIR/moodle_custom.php"; exit 2; }
[ -f "$PATCH_DIR/01_solution_moodle_custom.sql" ] || { echo "ERROR: falta $PATCH_DIR/01_solution_moodle_custom.sql"; exit 2; }
echo "OK"
echo

echo "== 2) Backup + Copio moodle_custom.php al container =="
docker exec "$APP_CONT" bash -lc "
set -e
DST='/var/www/html/src/Solutions/moodle_custom.php'
BK=\"/var/www/html/src/Solutions/moodle_custom.php.bak.$TS\"
if [ -f \"\$DST\" ]; then
  cp -a \"\$DST\" \"\$BK\"
  echo \"Backup: \$BK\"
else
  echo \"WARN: no existía \$DST (raro, pero sigo)\"
fi
"
docker cp "$FILES_DIR/moodle_custom.php" "$APP_CONT:/var/www/html/src/Solutions/moodle_custom.php"
echo "OK"
echo

echo "== 2.1) Validación rápida (syntax + presencia de cambios esperados) =="
docker exec "$APP_CONT" bash -lc "
set -e
php -l /var/www/html/src/Solutions/moodle_custom.php >/dev/null
grep -n \"in_array(\\\$param\\['module'\\], \\['courses','groups'\\])\" /var/www/html/src/Solutions/moodle_custom.php >/dev/null
grep -n \"\\\$attributeValue = (in_array(\\\$param\\['module'\\], \\['courses','groups'\\]) ? 'valueraw' : 'value');\" /var/www/html/src/Solutions/moodle_custom.php >/dev/null
echo 'OK: syntax + strings esperadas presentes'
"
echo "OK"
echo

echo "== 3) Icono para moodle_custom (moodle_custom.png) =="
docker exec "$APP_CONT" bash -lc '
set -e
SRC="/var/www/html/public/build/images/solution/moodle.png"
DST="/var/www/html/public/build/images/solution/moodle_custom.png"
if [ ! -f "$SRC" ]; then
  echo "ERROR: no existe $SRC"
  exit 2
fi
cp -f "$SRC" "$DST"
ls -lah "$DST"
'
echo "OK"
echo

echo "== 4) DB: asegurar row solution moodle_custom (idempotente) =="
MYSQL_ROOT_PASSWORD_IN_CONT="$(docker exec "$DB_CONT" bash -lc 'printf "%s" "${MYSQL_ROOT_PASSWORD:-}"' || true)"

if [ -n "$MYSQL_ROOT_PASSWORD_IN_CONT" ]; then
  MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD_IN_CONT"
elif [ -n "${MYSQL_ROOT_PASSWORD:-}" ]; then
  : # ya viene del entorno del host
else
  echo "ERROR: no pude obtener MYSQL_ROOT_PASSWORD."
  echo "Solución: ejecutá así:"
  echo "  MYSQL_ROOT_PASSWORD='TU_PASSWORD' bash $PATCH_DIR/apply.sh"
  exit 3
fi

docker exec -i "$DB_CONT" bash -lc "mysql -uroot -p\"$MYSQL_ROOT_PASSWORD\" \"$DB_NAME\"" < "$PATCH_DIR/01_solution_moodle_custom.sql"
echo "OK"
echo

echo "== 5) Cache prod + restart app =="
docker exec "$APP_CONT" bash -lc "cd /var/www/html && php bin/console cache:clear --env=prod"
docker restart "$APP_CONT" >/dev/null
echo "OK"
echo

echo "== DONE =="
echo "Backup quedó dentro del container: /var/www/html/src/Solutions/moodle_custom.php.bak.$TS"
