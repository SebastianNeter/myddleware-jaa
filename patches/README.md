# Myddleware Patches

This folder contains local hotfixes applied on top of the upstream Myddleware image/code.

## Applied patches

### 2026-02-04 --- moodle.php getRuleMode override removed
File: /var/www/html/src/Solutions/moodle.php

Why:
- In the Rule UI, "Mode" for Moodle target module "groups" only showed "Create data only".
- This prevented selecting the default modes and caused inconsistent behavior.

Fix:
- Remove Moodle connector override of getRuleMode() so it delegates to the base Solution::getRuleMode().

Patch file:
- patches/patch_moodle_getRuleMode_2026-02-04.diff

## Re-apply after an upgrade
1) Copy patch into container:
   docker compose cp patches/patch_moodle_getRuleMode_2026-02-04.diff myddleware:/tmp/

2) Apply patch:
   docker compose exec myddleware sh -lc 'patch -p0 < /tmp/patch_moodle_getRuleMode_2026-02-04.diff'

3) Validate syntax:
   docker compose exec myddleware sh -lc 'php -l /var/www/html/src/Solutions/moodle.php'

4) Reset opcache + reload apache:
   docker compose exec myddleware sh -lc 'php -r "opcache_reset();" >/dev/null 2>&1 || true; service apache2 reload || service apache2 restart'

---

## Estándar de Assets en Patches

### Objetivo
Permitir que un patch incluya assets (por ejemplo íconos PNG) y que se instalen automáticamente al aplicar el patch.

### Convenciones de carpetas

#### 1) files/
Uso: archivos que el `apply.sh` del patch copia explícitamente.

Ejemplo:
patches/<PATCH_ID>/files/moodle_custom.php  
patches/<PATCH_ID>/files/moodle_custom.png  

Caso típico:
Si existe `files/moodle_custom.png`, el patch lo copia a:

/var/www/html/public/build/images/solution/moodle_custom.png

---

#### 2) assets/
Uso: copiar automáticamente un árbol de assets preservando estructura.

Regla:

patches/<PATCH_ID>/assets/<ruta_relativa>

se copia a

/var/www/html/public/build/<ruta_relativa>

Ejemplo:

Repo:
patches/<PATCH_ID>/assets/images/solution/moodle_custom.png

Container:
/var/www/html/public/build/images/solution/moodle_custom.png

Esto lo ejecuta automáticamente `patch_apply_assets` desde:

patches/apply_patch.sh

---

### Aplicar un patch

Desde el servidor:
cd ~/myddleware-jaa
patches/apply_patch.sh <PATCH_ID>

---

### Notas

--� El nombre del icono debe coincidir con el nombre de la solution.  
  Ejemplo: `moodle_custom` -�� `moodle_custom.png`.

--� Si el icono no aparece inmediatamente, suele ser cache del navegador.  
  Hacer hard refresh o abrir en incógnito.

EOF+
cat <<'EOF' >> patches/README.md

---

## Estándar de Assets en Patches

### Objetivo
Permitir que un patch incluya assets (por ejemplo íconos PNG) y que se instalen automáticamente al aplicar el patch.

### Convenciones de carpetas

#### 1) files/
Uso: archivos que el `apply.sh` del patch copia explícitamente.

Ejemplo:
patches/<PATCH_ID>/files/moodle_custom.php  
patches/<PATCH_ID>/files/moodle_custom.png  

Caso típico:
Si existe `files/moodle_custom.png`, el patch lo copia a:

/var/www/html/public/build/images/solution/moodle_custom.png

---

#### 2) assets/
Uso: copiar automáticamente un árbol de assets preservando estructura.

Regla:

patches/<PATCH_ID>/assets/<ruta_relativa>

se copia a

/var/www/html/public/build/<ruta_relativa>

Ejemplo:

Repo:
patches/<PATCH_ID>/assets/images/solution/moodle_custom.png

Container:
/var/www/html/public/build/images/solution/moodle_custom.png

Esto lo ejecuta automáticamente `patch_apply_assets` desde:

patches/apply_patch.sh

---

### Aplicar un patch

Desde el servidor:
cd ~/myddleware-jaa
patches/apply_patch.sh <PATCH_ID>

---

### Notas

--� El nombre del icono debe coincidir con el nombre de la solution.  
  Ejemplo: `moodle_custom` -�� `moodle_custom.png`.

--� Si el icono no aparece inmediatamente, suele ser cache del navegador.  
  Hacer hard refresh o abrir en incógnito.


---

## Estándar de Assets en Patches

### Objetivo
Permitir que un patch incluya assets (por ejemplo íconos PNG) y que se instalen automáticamente al aplicar el patch.

### Convenciones de carpetas

#### 1) assets/
Uso: copiar automáticamente un árbol de assets preservando estructura.

Regla:
- Repo: `patches/<PATCH_ID>/assets/<ruta_relativa>`
- Container: `/var/www/html/public/build/<ruta_relativa>`

Ejemplo (ícono de solution):
- Repo: `patches/<PATCH_ID>/assets/images/solution/moodle_custom.png`
- Container: `/var/www/html/public/build/images/solution/moodle_custom.png`

Esto lo instala automáticamente `patch_apply_assets` cuando corrés:
`patches/apply_patch.sh <PATCH_ID>`

#### 2) files/
Uso: archivos que el `apply.sh` del patch copia explícitamente (hotfixes de PHP/SQL/etc).

Ejemplo:
- `patches/<PATCH_ID>/files/moodle_custom.php`

Recomendación:
- Usar `assets/` para imágenes (íconos, etc.)
- Usar `files/` para código/SQL que el patch aplica con lógica propia.

### Aplicar un patch
Desde el servidor:
- `cd ~/myddleware-jaa`
- `patches/apply_patch.sh <PATCH_ID>`

### Notas
- El nombre del icono debe coincidir con el nombre de la solution: `moodle_custom` → `moodle_custom.png`.
- Si el icono no aparece inmediatamente, suele ser cache del navegador: hard refresh o incógnito.

