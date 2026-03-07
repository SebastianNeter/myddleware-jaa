# Hotfix: ID compuesto en `group_members` para reglas bidireccionales

## Fecha
2026-03-06

## Archivo modificado
`src/Solutions/moodle.php`

## Problema

Las reglas bidireccionales que usan `group_members` como source no encuentran
el registro correspondiente en la regla opuesta. El lookup bidireccional
(`DocumentManager::checkRecordExist`) compara `Rule5.source_id` con
`Rule4.target_id` y no matchean porque usan formatos de ID diferentes:

| Operacion | Metodo | ID generado | Ejemplo |
|-----------|--------|-------------|---------|
| READ (source) | `formatRecord()` | PK interno de Moodle | `26733` |
| CREATE (target) | `createData()` | `groupid_userid` | `1231_24302` |
| UPDATE (target) | `updateData()` | `groupid_userid` | `1231_24302` |

Como consecuencia, el bidireccional falla: `target_id` queda NULL, el documento
se clasifica como tipo `C` (create) en vez de `U` (update), y Salesforce
rechaza la creacion por campos faltantes.

## Causa raiz

El API de Moodle (`core_group_add_group_members`) no retorna ID al crear.
El codigo construye `groupid_userid` como workaround. Pero el API de lectura
(`local_myddleware_get_group_members_by_date`) retorna el PK interno como `id`.

## Fix aplicado

### Cambio 1: `required_fields` (linea 46)
Se agregan `groupid` y `userid` como campos requeridos para que siempre
esten disponibles en la respuesta del API durante lectura:

```php
// Antes:
'group_members' => ['id', 'timeadded'],
// Despues:
'group_members' => ['id', 'groupid', 'userid', 'timeadded'],
```

### Cambio 2: `formatRecord()` (linea ~577)
Se construye el ID compuesto al final de `formatRecord`, igualando el formato
que `createData`/`updateData` ya usan:

```php
if ($param['module'] === 'group_members' && !empty($row['groupid']) && !empty($row['userid'])) {
    $row['id'] = $row['groupid'] . '_' . $row['userid'];
}
```

## Impacto

- Solo afecta al modulo `group_members` durante lectura (source)
- No afecta otros modulos (`users`, `courses`, `groups`, etc.)
- No afecta operaciones de escritura (target)
- `createData`/`updateData` no se modifican (ya usaban el compuesto)

## Nota: moodle_custom.php

Si el conector se cambia de `moodle` a `moodle_custom`, este mismo fix debe
aplicarse en `moodle_custom.php` ya que ese archivo sobreescribe tanto
`required_fields` como `formatRecord()`.

## Para revertir

```bash
git checkout src/Solutions/moodle.php
docker cp src/Solutions/moodle.php myddleware-jaa-myddleware-1:/var/www/html/src/Solutions/moodle.php
docker exec myddleware-jaa-myddleware-1 bash -lc "cd /var/www/html && php bin/console cache:clear --env=prod"
```
