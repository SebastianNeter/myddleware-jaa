-- =============================================================================
-- ARG 5.1 — Moodle new group members -> SF ARG Intermediacion_a_Moodle__c
-- Mirror of ROC 5.1 (rule 6a29eef4b56ef). Created 2026-06-12.
--
-- Source: connector 2 (Moodle Prod), module get_roc_group_enrolments with
--         group_country_filter='arg' (plugin v2.5.1 per-country anti-loop:
--         excludes users whose myddleware_origin = 'arg', i.e. users created
--         by the ARG circuit itself; ROC-created and manual users qualify)
-- Target: connector 3 (SF ARG prod), object Intermediaci_n_a_Moodle__c
--
-- PREREQUISITE (verify before activation): the ARG org must have the
-- Intermediaci_n_a_Moodle__c object AND the record-triggered flow that
-- processes staged rows. Without the flow, rows insert but nothing happens.
--
-- SAFETY: rule active=0, cron enable=0. datereference must be bumped to NOW()
-- right before activation.
-- =============================================================================

-- 1) Rule group --------------------------------------------------------------
INSERT INTO rulegroup (id, created_by, modified_by, name, date_created, date_modified, description, deleted)
VALUES (
    '6a2b513b781f6', 1, 1,
    'ARG 5.x — Moodle New Group Members to SF Intermediacion',
    NOW(), NOW(),
    'Detects users added to ARG-flagged Moodle groups outside the ARG Myddleware circuit (manual operator adds, self-enrol, ROC-created users joining ARG groups) and stages them into Intermediacion_a_Moodle__c in the SF ARG org.',
    0
);

-- 2) Rule (inactive) ---------------------------------------------------------
INSERT INTO rule (id, conn_id_source, conn_id_target, created_by, modified_by, group_id,
                  date_created, date_modified, module_source, module_target,
                  active, deleted, name, name_slug, read_job_lock)
VALUES (
    '6a2b513bdca96', 2, 3, 1, 1, '6a2b513b781f6',
    NOW(), NOW(), 'get_roc_group_enrolments', 'Intermediaci_n_a_Moodle__c',
    0, 0,
    '[ARG] 5.1 NewGroupMembers to SF Intermed (C)',
    'arg_5_1_newgroupmembers_to_sf_intermed_c',
    ''
);

-- 3) Rule params -------------------------------------------------------------
INSERT INTO ruleparam (rule_id, name, value) VALUES
('6a2b513bdca96', 'description', 'Stage new ARG group members (added outside the ARG Myddleware circuit) into SF ARG Intermediacion_a_Moodle__c. Source webservice: local_myddleware_get_roc_group_enrolments with group_country_filter=arg (per-country anti-loop). The SF flow on Intermediacion creates Contact/AE/Group records.'),
('6a2b513bdca96', 'limit', '150'),
('6a2b513bdca96', 'delete', '60'),
('6a2b513bdca96', 'datereference', NOW()),
('6a2b513bdca96', 'mode', 'C'),
('6a2b513bdca96', 'group_country_filter', 'arg');

-- 4) Rule fields (25) — identical mapping to ROC 5.1 -------------------------
INSERT INTO rulefield (rule_id, target_field_name, source_field_name, formula) VALUES
('6a2b513bdca96', 'Id_de_usuario__c',                  'user_id',               NULL),
('6a2b513bdca96', 'Nombre_del_usuario__c',             'user_firstname',        NULL),
('6a2b513bdca96', 'Apellido_del_usuario__c',           'user_lastname',         NULL),
('6a2b513bdca96', 'Correo_electr_nico_del_usuario__c', 'user_email',            NULL),
('6a2b513bdca96', 'nombre_de_usuario__c',              'user_username',         NULL),
('6a2b513bdca96', 'Tiempo_de_creaci_n_usuario__c',     'user_timecreated',      NULL),
('6a2b513bdca96', 'Id_de_grupo__c',                    'group_id',              NULL),
('6a2b513bdca96', 'Nombre_del_grupo__c',               'group_name',            NULL),
('6a2b513bdca96', 'Descripci_n_del_grupo__c',          'group_description',     NULL),
('6a2b513bdca96', 'N_mero_id_de_grupo__c',             'group_idnumber',        NULL),
('6a2b513bdca96', 'Id_de_curso__c',                    'course_id',             NULL),
('6a2b513bdca96', 'Nombre_completo_curso__c',          'course_fullname',       NULL),
('6a2b513bdca96', 'Nombre_corto_curso__c',             'course_shortname',      NULL),
('6a2b513bdca96', 'N_mero_id_de_curso__c',             'course_idnumber',       NULL),
('6a2b513bdca96', 'Curso_visible__c',                  'course_visible',        NULL),
('6a2b513bdca96', 'Id_de_rol__c',                      'role_id',               NULL),
('6a2b513bdca96', 'Nombre_del_rol__c',                 'role_shortname',        NULL),
('6a2b513bdca96', 'Rol_del_usuario__c',                'role_shortname',        NULL),
('6a2b513bdca96', 'M_todo_de_inscripci_n__c',          'enrol_method',          NULL),
('6a2b513bdca96', 'Tiempo_de_creaci_n_rol__c',         'enrol_timecreated',     NULL),
('6a2b513bdca96', 'Tiempo_de_inicio_rol__c',           'enrol_timestart',       NULL),
('6a2b513bdca96', 'Tiempo_de_finalizaci_n_rol__c',     'enrol_timeend',         NULL),
('6a2b513bdca96', 'Porcentaje__c',                     'completion_percentage', NULL),
('6a2b513bdca96', 'Actividades_completas__c',          'completion_completed',  NULL),
('6a2b513bdca96', 'Total_de_actividades__c',           'completion_total',      NULL);

-- 5) Cron job (disabled) -----------------------------------------------------
INSERT INTO cron_job (command, arguments, description, running_instances, max_instances,
                      number, period, last_use, next_run, enable, created_at, updated_at)
VALUES (
    'myddleware:synchro', '6a2b513b781f6',
    'ARG 5.1 New Group Members to SF Intermediacion',
    0, 1, 1, '*/30 * * * *', NULL, NOW(), 0, NOW(), NOW()
);

-- 6) Verification ------------------------------------------------------------
SELECT 'RULE' AS what, id, name, active, deleted, module_source, module_target
FROM rule WHERE id = '6a2b513bdca96';

SELECT 'PARAMS' AS what, name, LEFT(value, 50) AS value
FROM ruleparam WHERE rule_id = '6a2b513bdca96' ORDER BY name;

SELECT 'FIELDS' AS what, COUNT(*) AS rulefield_count
FROM rulefield WHERE rule_id = '6a2b513bdca96';

SELECT 'CRON' AS what, id, arguments, period, enable
FROM cron_job WHERE arguments = '6a2b513b781f6';
