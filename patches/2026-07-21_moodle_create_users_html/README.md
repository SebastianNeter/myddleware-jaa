# Patch 2026-07-21 --- Myddleware user creation → local_myddleware_create_users (HTML email)

File: /var/www/html/src/Solutions/moodle.php (createData(), case 'users')

## Why
Al crear usuarios, Myddleware llama a `core_user_create_users` con `createpassword=true`.
Moodle core manda entonces el mail de credenciales como TEXTO PLANO, y como la plantilla
está en HTML, al alumno le llega el código HTML crudo.

## Fix
En `createData()` case 'users', cambiar:

    $functionname = 'core_user_create_users';

por:

    $functionname = 'local_myddleware_create_users';

`local_myddleware_create_users` es una función WS del plugin `local_myddleware` (lado Moodle,
ya deployada y verificada) que crea el usuario igual que el core PERO manda el mail de
credenciales en HTML (reusando local_adminreset). Aplica a TODAS las altas de Myddleware
(ARG + ROC).

## Aplicar
Desde el server:
    cd ~/myddleware-jaa
    bash patches/2026-07-21_moodle_create_users_html/apply.sh

(No rebuild. Modifica el contenedor corriendo + docker restart. Mantiene imagen + Premium.)

## Rollback
El apply deja un backup dentro del container:
    docker exec myddleware-jaa-myddleware-1 cp -a /var/www/html/src/Solutions/moodle.php.bak.<TS> /var/www/html/src/Solutions/moodle.php
    docker restart myddleware-jaa-myddleware-1

O revertir el string (local_myddleware_create_users → core_user_create_users) y restart.

## Dependencia
Requiere que el plugin `local_myddleware` (lado Moodle) exponga `local_myddleware_create_users`.
Ya está deployado/registrado en prod (2026-07-21). Ver Engram: moodle/spec-mail-credenciales-html.
