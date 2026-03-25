# Patch: Moodle Completion Enhancements

**Date**: 2026-03-23
**Container**: Moodle (`90bbc46bc607`)
**Plugin path**: `/var/www/html/local/myddleware/`

## Changes

### 1. Rename `id` → `userid_courseid` in `get_course_completion_percentage`

**Why**: Moodle REST pipeline treats any parameter named `id` as PARAM_INT regardless of function-specific definition. Composite values like `24315_89` were rejected with "expecting int type". GitHub maintainer approved rename.

**Files changed**:
- `externallib.php`: 6 occurrences renamed in `_parameters()`, function signature, and body
- Also set `$id = 0` (not `$id = $userid_courseid`) to prevent passing composite value to `get_users_completion()`

### 2. New method `get_course_completion_percentage_by_country`

**Why**: In a multi-country environment (ARG, ROC, MEX, URY, COL, PER), each Salesforce instance only needs completions for ITS users. Without country filter, a Moodle→SF rule generates thousands of errors for records not found.

**How it works**:
- Accepts `time_modified` (INT) and `country_filter` (TEXT, required)
- Filters completions by custom profile field (e.g. `arg=1`) via JOIN to `user_info_data`/`user_info_field`
- Returns same structure as original: id, userid, courseid, percentage, completed_activities, total_activities, overall_status, timemodified, error

**Files changed**:
- `externallib.php`: New method (~150 lines) added before closing `}`
- `db/services.php`: Function registered in `$functions` and `$services`
- `version.php`: Bumped from `2025061805` to `2025061806`

### 3. Version bump + upgrade

After applying, run:
```bash
sudo docker exec <moodle_container> php /var/www/html/admin/cli/upgrade.php --non-interactive
```

## Myddleware connector changes (in repo, not patch)

These changes are committed directly to the repo:

- `src/Solutions/moodle.php`:
  - `required_fields`: `userid_courseid` + new module entry
  - `get_modules()`: new module in source list
  - `setParameters()`: renamed parameter + `country_filter` from ruleParams
  - `getFieldsParamUpd()`: country dropdown in rule UI
  - `group_custom_fields`: full support ported from moodle_custom (6 changes)

- `src/Solutions/lib/moodle/metadata.php`: field definitions for new module

- `src/Solutions/salesforce.php`: `Junction_Curso_Contacto__c` in `FieldsDuplicate`

- `config/packages/doctrine.yaml`: `use_savepoints: true`

## DB configuration required

After deploying Myddleware code changes, add `group_custom_fields` to the standard moodle connector:
```sql
INSERT INTO connectorparam (conn_id, name, value)
SELECT id, 'group_custom_fields', 'arg,roc,mex,ury,col,per'
FROM connector WHERE sol_id = 'moodle'
AND id NOT IN (SELECT conn_id FROM connectorparam WHERE name = 'group_custom_fields');
```

## Verification

| Test | Command | Expected |
|------|---------|----------|
| Moodle API | `&wsfunction=local_myddleware_get_course_completion_percentage_by_country&country_filter=arg&time_modified=0` | Array with completions only for ARG users |
| Moodle API | `&wsfunction=local_myddleware_get_course_completion_percentage&userid_courseid=31433_86` | Completion data for specific user/course |
| Myddleware UI | Create rule with source module "Get course completion percentage by country" | Country dropdown visible in rule params |
