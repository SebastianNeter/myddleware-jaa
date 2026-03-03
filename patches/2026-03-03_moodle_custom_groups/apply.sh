#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="$PATCH_DIR/files"

APP_CONT="${APP_CONT:-myddleware-myddleware-1}"
DB_CONT="${DB_CONT:-myddleware-mysql-1}"
DB_NAME="${DB_NAME:-myddleware}"

echo "== Patch dir: $PATCH_DIR"
echo "== App container: $APP_CONT"
echo "== DB container:  $DB_CONT"
echo "== DB name:       $DB_NAME"
echo

echo "== 1) Verifico que existan los archivos requeridos =="
for f in moodle_custom.php; do
  if [ ! -f "$FILES_DIR/$f" ]; then
    echo "ERROR: falta $FILES_DIR/$f"
    exit 2
  fi
done
if [ ! -f "$PATCH_DIR/01_solution_moodle_custom.sql" ]; then
  echo "ERROR: falta $PATCH_DIR/01_solution_moodle_custom.sql"
  exit 2
fi
echo "OK"
echo

echo "== 2) Copio archivos al container =="
docker cp "$FILES_DIR/moodle_custom.php" "$APP_CONT:/var/www/html/src/Solutions/moodle_custom.php"

# opcionales (solo si existen en el patch)
if [ -f "$FILES_DIR/SolutionManager.php" ]; then
  docker cp "$FILES_DIR/SolutionManager.php" "$APP_CONT:/var/www/html/src/Manager/SolutionManager.php"
fi
if [ -f "$FILES_DIR/FluxController.php" ]; then
  docker cp "$FILES_DIR/FluxController.php" "$APP_CONT:/var/www/html/src/Controller/FluxController.php"
fi
echo "OK"
echo

echo "== 3) Icono para moodle_custom (moodle_custom.png) =="
docker exec -it "$APP_CONT" bash -lc '
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

echo "== 4) DB: asegurar row solution moodle_custom =="
# Estrategia: si MYSQL_ROOT_PASSWORD existe en el container de mysql, lo usamos.
# Si no existe, frenamos y pedimos que lo pases como env var al ejecutar.
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

# Ejecutamos SQL
docker exec -i "$DB_CONT" bash -lc "mysql -uroot -p\"$MYSQL_ROOT_PASSWORD\" \"$DB_NAME\"" < "$PATCH_DIR/01_solution_moodle_custom.sql"
echo "OK"
echo

echo "== 5) Cache prod + restart app =="
docker exec -it "$APP_CONT" bash -lc "cd /var/www/html && php bin/console cache:clear --env=prod"
docker restart "$APP_CONT" >/dev/null
echo "OK"
echo

echo "PATCH APLICADO OK"
