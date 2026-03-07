# Fix: TypeError en DocumentManager::insertDataTable() con PHP 8

## Fecha
2026-03-06

## Archivo modificado
`src/Manager/DocumentManager.php` — función `insertDataTable()` (~línea 1512)

## Problema

### Síntoma
La Regla 5 (group_members → Junction_Curso_Contacto__c) crashea al ejecutarse,
dejando el job en estado `Start` indefinidamente y bloqueando la regla con `read_job_lock`.

El log mostraba:
```
[2026-03-07T00:56:37] php.WARNING: Warning: Undefined variable $dataInsert at DocumentManager.php:1569
[2026-03-07T00:56:37] console.CRITICAL: Error thrown while running command "myddleware:synchro ..."
  Message: "array_key_exists(): Argument #2 ($array) must be of type array, null given"
  at DocumentManager.php:1569
```

### Causa raíz

En `insertDataTable()`, el array `$dataInsert` no se inicializa explícitamente.
Se "crea" implícitamente cuando el primer campo real ejecuta `$dataInsert[$key] = $value`.

Sin embargo, si **todos** los `ruleFields` tienen `source_field_name = 'my_value'`,
el loop salta todos los campos con `continue` (línea 1517) y `$dataInsert` queda indefinido.

Luego el loop de filtros (línea 1567–1573) llama:
```php
if (!array_key_exists($ruleFilter['target'], $dataInsert)) { // $dataInsert es null → TypeError
```

**PHP 7**: `array_key_exists(key, null)` era solo un E_WARNING (devolvía false) y
`null[$key] = $value` usaba auto-vivification → el código funcionaba silenciosamente.

**PHP 8**: `array_key_exists(key, null)` lanza `TypeError` fatal → el proceso muere.

### Por qué solo afecta a Regla 5

| Regla | ¿Tiene campos reales (no my_value)? | ¿Tiene filtros? | ¿Crashea? |
|-------|-------------------------------------|-----------------|-----------|
| R1    | Sí (Email__c, FirstName__c, ...)    | Sí              | No        |
| R2    | Sí (sf_contact_id, id)              | Sí              | No        |
| R3    | Sí (courseid__c, userid__c)         | Sí              | No        |
| R4    | Sí (groupid__c, userid__c)          | Sí              | No        |
| **R5**| **No — solo my_value**             | **Sí (userid)** | **Sí**    |

## Fix aplicado

Inicializar `$dataInsert = []` explícitamente antes de los loops,
entre la asignación de `$fields` y el loop principal de campos.

Ver `fix.patch` para el diff exacto.

### Para revertir

```bash
cd /ruta/al/proyecto
git diff src/Manager/DocumentManager.php   # ver cambio actual
git checkout src/Manager/DocumentManager.php   # descartar cambio (revert)
```

O aplicando el patch al revés:
```bash
patch -R src/Manager/DocumentManager.php < patches/2026-03-06_fix_dataInsert_php8/fix.patch
```

## Impacto

- **Mínimo**: se agrega una sola línea que inicializa `$dataInsert = []`.
- No afecta el comportamiento de reglas que ya funcionan (sus campos reales
  ya inicializaban `$dataInsert` en la primera iteración del loop).
- Solo cambia el comportamiento del edge case: reglas con **todos** los campos
  como `my_value` + al menos un filtro.
