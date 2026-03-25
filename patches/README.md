# Myddleware Patches

This folder contains local hotfixes applied on top of the upstream Myddleware image/code.

## Applied patches

### 2026-02-04 — moodle.php getRuleMode override removed

**File**: `/var/www/html/src/Solutions/moodle.php`

**Why**: In the Rule UI, "Mode" for Moodle target module "groups" only showed "Create data only". This prevented selecting the default modes and caused inconsistent behavior.

**Fix**: Remove Moodle connector override of `getRuleMode()` so it delegates to the base `Solution::getRuleMode()`.

**Patch file**: `patches/patch_moodle_getRuleMode_2026-02-04.diff`

---

### 2026-03-03 — moodle_custom connector (groups + icon)

**Directory**: `patches/2026-03-03_moodle_custom_groups/`

**Why**: Added `moodle_custom` connector with group custom fields support and custom icon.

**Note**: Group custom fields support has been ported to the standard `moodle` connector. The `moodle_custom` connector is deprecated — rules have been migrated to standard `moodle`.

---

### 2026-03-23 — Moodle completion enhancements

**Directory**: `patches/2026-03-23_moodle_completion_enhancements/`

**Target**: Moodle plugin container (`/var/www/html/local/myddleware/`)

**Changes**:
1. **Rename `id` → `userid_courseid`** in `get_course_completion_percentage` — fixes Moodle REST pipeline rejecting composite IDs
2. **New method `get_course_completion_percentage_by_country`** — filters completions by user country profile field for multi-country SF sync
3. **services.php** — register new function
4. **version.php** — bump to `2025061806`

**Companion repo changes** (committed directly, not patch):
- `src/Solutions/moodle.php`: connector support for both changes + group_custom_fields port
- `src/Solutions/lib/moodle/metadata.php`: field definitions for new module
- `src/Solutions/salesforce.php`: `Junction_Curso_Contacto__c` in `FieldsDuplicate`
- `config/packages/doctrine.yaml`: `use_savepoints: true`

---

## Re-apply after an upgrade

### getRuleMode patch
```bash
docker compose cp patches/patch_moodle_getRuleMode_2026-02-04.diff myddleware:/tmp/
docker compose exec myddleware sh -lc 'patch -p0 < /tmp/patch_moodle_getRuleMode_2026-02-04.diff'
docker compose exec myddleware sh -lc 'php -l /var/www/html/src/Solutions/moodle.php'
```

### Completion enhancements (Moodle container)
See `patches/2026-03-23_moodle_completion_enhancements/README.md`

---

## Patch conventions

### Directory structure
```
patches/<PATCH_ID>/
├── README.md          # Documentation
├── apply.sh           # Apply script for Myddleware container
├── apply_moodle.sh    # Apply script for Moodle container (if applicable)
├── files/             # Code snippets/hotfixes copied explicitly by apply script
└── assets/            # Auto-copied to /var/www/html/public/build/ preserving structure
```

### Applying a patch
```bash
cd ~/myddleware-jaa
patches/apply_patch.sh <PATCH_ID>
```

### Notes
- Icon names must match solution name: `moodle_custom` → `moodle_custom.png`
- If icons don't appear, hard refresh or use incognito
