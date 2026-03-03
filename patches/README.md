# Myddleware Patches

This folder contains local hotfixes applied on top of the upstream Myddleware image/code.

## Applied patches

### 2026-02-04 — moodle.php getRuleMode override removed
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
