#!/usr/bin/env bash
set -euo pipefail

# Patch: 2026-07-21_moodle_create_users_html
# Qué hace: enruta la creación de usuarios de Myddleware a la función WS
#   local_myddleware_create_users (que manda el mail de credenciales en HTML),
#   en vez de core_user_create_users (que lo manda como texto plano / código crudo).
# Cómo: cambio quirúrgico de 1 línea en createData() case 'users' de moodle.php,
#   aplicado DENTRO del contenedor corriendo (sin rebuild → no toca imagen ni Premium).
# Rollback: restaurar el .bak que deja este patch + docker restart (ver final).

APP_CONT="${APP_CONT:-myddleware-jaa-myddleware-1}"
TS="$(date +%F_%H%M%S)"
F="/var/www/html/src/Solutions/moodle.php"

echo "== 0) Precheck container =="
docker ps --format '{{.Names}}' | grep -qx "$APP_CONT" || { echo "ERROR: no existe $APP_CONT"; exit 10; }
echo "OK"

echo "== 1) Backup dentro del container =="
docker exec "$APP_CONT" bash -lc "cp -a '$F' '$F.bak.$TS' && echo 'backup: $F.bak.$TS'"

echo "== 2) Aplicar cambio (str-replace guardado: exactamente 1 match) =="
docker exec "$APP_CONT" php -r '
$f = "/var/www/html/src/Solutions/moodle.php";
$s = file_get_contents($f);
$old = "\$functionname = \x27core_user_create_users\x27;";
$new = "\$functionname = \x27local_myddleware_create_users\x27;";
$n = substr_count($s, $old);
echo "matches=$n\n";
if ($n === 1) { file_put_contents($f, str_replace($old, $new, $s)); echo "APPLIED\n"; }
else { echo "ABORT: se esperaba 1 match, archivo intacto\n"; exit(1); }
'

echo "== 3) php -l + verify =="
docker exec "$APP_CONT" bash -lc "php -l '$F' >/dev/null && echo 'syntax OK'"
docker exec "$APP_CONT" bash -lc "grep -n \"local_myddleware_create_users\" '$F'"

echo "== 4) cache:clear (prod) =="
docker exec "$APP_CONT" bash -lc "cd /var/www/html && php bin/console cache:clear --env=prod"

echo "== 5) docker restart (mismo contenedor; NO rebuild/recreate; mantiene Premium) =="
docker restart "$APP_CONT" >/dev/null
echo "OK"

echo "== DONE =="
echo "Rollback: docker exec $APP_CONT cp -a '$F.bak.$TS' '$F' && docker restart $APP_CONT"
