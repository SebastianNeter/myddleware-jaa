#!/usr/bin/env bash
set -euo pipefail

# Defaults (podés overridear por env)
APP_CONT="${APP_CONT:-myddleware-myddleware-1}"
DB_CONT="${DB_CONT:-myddleware-mysql-1}"
DB_NAME="${DB_NAME:-myddleware}"

patch_precheck_containers() {
  docker ps --format '{{.Names}}' | grep -qx "$APP_CONT" || { echo "ERROR: no existe container APP_CONT=$APP_CONT"; exit 10; }
  docker ps --format '{{.Names}}' | grep -qx "$DB_CONT"  || { echo "ERROR: no existe container DB_CONT=$DB_CONT"; exit 11; }
}

# Copia un árbol de assets del patch al container.
# Convención:
#   patches/<PATCH_ID>/assets/<lo-que-sea>  -->  /var/www/html/public/build/<lo-que-sea>
patch_apply_assets() {
  local patch_dir="$1"
  local assets_dir="$patch_dir/assets"
  local container_root="/var/www/html/public/build"

  if [ ! -d "$assets_dir" ]; then
    echo "== assets: no hay carpeta assets/ (OK, skip) =="
    return 0
  fi

  echo "== assets: copiando desde $assets_dir a $container_root =="

  # Copiamos archivo por archivo preservando path relativo
  # (sin necesitar rsync dentro del container)
  local f rel dst_dir dst
  while IFS= read -r -d '' f; do
    rel="${f#$assets_dir/}"
    dst_dir="$(dirname "$rel")"
    dst="$container_root/$rel"

    # Creamos dir destino en el container
    docker exec "$APP_CONT" bash -lc "mkdir -p \"$(printf '%q' "$container_root/$dst_dir")\""

    # Copiamos el archivo al destino final
    docker cp "$f" "$APP_CONT:$dst"

  done < <(find "$assets_dir" -type f -print0)

  # Debug rápido: listamos lo copiado
  docker exec "$APP_CONT" bash -lc "echo '--- assets en container (muestra) ---'; find \"$container_root\" -maxdepth 4 -type f | tail -n 20"
  echo "== assets: OK =="
}
