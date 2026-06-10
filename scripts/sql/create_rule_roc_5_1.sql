-- =============================================================================
-- ROC 5.1 — Moodle new group members -> SF Intermediacion_a_Moodle__c
-- Created 2026-06-10. Template: ROC 4.1 (rule 6a10971f55b21, created 2026-05-22).
--
-- Source: connector 2 (Moodle Prod), module get_roc_group_enrolments
--         (plugin v2.5.0 local_myddleware_get_roc_group_enrolments — by-date on
--         groups_members.timeadded, group customfield filter, excludes users
--         with myddleware_origin='myddleware', any enrolment method)
-- Target: connector 7 (SF ROC Prod), object Intermediaci_n_a_Moodle__c
--         (staging table — the existing SF record-triggered flow creates
--         Contact / Contact-en-AE / Contact-en-Grupo from each row)
--
-- SAFETY:
--   * rule starts active=0 and cron starts enable=0 — nothing runs on insert
--   * datereference must be bumped to NOW() right before activation (Fase 9)
--   * limit=150 (SF SOAP 200-record hard limit + flow surge protection)
-- =============================================================================

-- 1) Rule group --------------------------------------------------------------
INSERT INTO rulegroup (id, created_by, modified_by, name, date_created, date_modified, description, deleted)
VALUES (
    '6a29eef45ae50', 1, 1,
    'ROC 5.x — Moodle New Group Members to SF Intermediacion',
    NOW(), NOW(),
    'Detects users added to ROC-flagged Moodle groups outside Myddleware (manual operator adds, self-enrol) and stages them into Intermediacion_a_Moodle__c for the SF flow to process.',
    0
);

-- 2) Rule (inactive) ---------------------------------------------------------
INSERT INTO rule (id, conn_id_source, conn_id_target, created_by, modified_by, group_id,
                  date_created, date_modified, module_source, module_target,
                  active, deleted, name, name_slug, read_job_lock)
VALUES (
    '6a29eef4b56ef', 2, 7, 1, 1, '6a29eef45ae50',
    NOW(), NOW(), 'get_roc_group_enrolments', 'Intermediaci_n_a_Moodle__c',
    0, 0,
    '[ROC] 5.1 Moodle NewGroupMembers to SF Intermediacion (C)',
    'roc_5_1_moodle_newgroupmembers_to_sf_intermediacion_c',
    ''
);

-- 3) Rule params -------------------------------------------------------------
INSERT INTO ruleparam (rule_id, name, value) VALUES
('6a29eef4b56ef', 'description', 'Stage new ROC group members (added outside Myddleware) into SF Intermediacion_a_Moodle__c. Source webservice: local_myddleware_get_roc_group_enrolments (by-date on groups_members.timeadded, excludes myddleware_origin users). The SF flow on Intermediacion creates Contact/AE/Group records.'),
('6a29eef4b56ef', 'limit', '150'),
('6a29eef4b56ef', 'delete', '60'),
('6a29eef4b56ef', 'datereference', NOW()),
('6a29eef4b56ef', 'mode', 'C'),
('6a29eef4b56ef', 'group_country_filter', 'roc');

-- 4) Rule fields (25) — plugin flat output -> Intermediacion_a_Moodle__c -----
INSERT INTO rulefield (rule_id, target_field_name, source_field_name, formula) VALUES
('6a29eef4b56ef', 'Id_de_usuario__c',                  'user_id',               NULL),
('6a29eef4b56ef', 'Nombre_del_usuario__c',             'user_firstname',        NULL),
('6a29eef4b56ef', 'Apellido_del_usuario__c',           'user_lastname',         NULL),
('6a29eef4b56ef', 'Correo_electr_nico_del_usuario__c', 'user_email',            NULL),
('6a29eef4b56ef', 'nombre_de_usuario__c',              'user_username',         NULL),
('6a29eef4b56ef', 'Tiempo_de_creaci_n_usuario__c',     'user_timecreated',      NULL),
('6a29eef4b56ef', 'Id_de_grupo__c',                    'group_id',              NULL),
('6a29eef4b56ef', 'Nombre_del_grupo__c',               'group_name',            NULL),
('6a29eef4b56ef', 'Descripci_n_del_grupo__c',          'group_description',     NULL),
('6a29eef4b56ef', 'N_mero_id_de_grupo__c',             'group_idnumber',        NULL),
('6a29eef4b56ef', 'Id_de_curso__c',                    'course_id',             NULL),
('6a29eef4b56ef', 'Nombre_completo_curso__c',          'course_fullname',       NULL),
('6a29eef4b56ef', 'Nombre_corto_curso__c',             'course_shortname',      NULL),
('6a29eef4b56ef', 'N_mero_id_de_curso__c',             'course_idnumber',       NULL),
('6a29eef4b56ef', 'Curso_visible__c',                  'course_visible',        NULL),
('6a29eef4b56ef', 'Id_de_rol__c',                      'role_id',               NULL),
('6a29eef4b56ef', 'Nombre_del_rol__c',                 'role_shortname',        NULL),
('6a29eef4b56ef', 'Rol_del_usuario__c',                'role_shortname',        NULL),
('6a29eef4b56ef', 'M_todo_de_inscripci_n__c',          'enrol_method',          NULL),
('6a29eef4b56ef', 'Tiempo_de_creaci_n_rol__c',         'enrol_timecreated',     NULL),
('6a29eef4b56ef', 'Tiempo_de_inicio_rol__c',           'enrol_timestart',       NULL),
('6a29eef4b56ef', 'Tiempo_de_finalizaci_n_rol__c',     'enrol_timeend',         NULL),
('6a29eef4b56ef', 'Porcentaje__c',                     'completion_percentage', NULL),
('6a29eef4b56ef', 'Actividades_completas__c',          'completion_completed',  NULL),
('6a29eef4b56ef', 'Total_de_actividades__c',           'completion_total',      NULL);

-- 5) Cron job (disabled) -----------------------------------------------------
INSERT INTO cron_job (command, arguments, description, running_instances, max_instances,
                      number, period, last_use, next_run, enable, created_at, updated_at)
VALUES (
    'myddleware:synchro', '6a29eef45ae50',
    'ROC 5.1 New Group Members to SF Intermediacion',
    0, 1, 1, '*/30 * * * *', NULL, NOW(), 0, NOW(), NOW()
);

-- 6) Verification ------------------------------------------------------------
SELECT 'RULE' AS what, id, name, active, deleted, module_source, module_target, group_id
FROM rule WHERE id = '6a29eef4b56ef';

SELECT 'PARAMS' AS what, name, LEFT(value, 60) AS value
FROM ruleparam WHERE rule_id = '6a29eef4b56ef' ORDER BY name;

SELECT 'FIELDS' AS what, COUNT(*) AS rulefield_count
FROM rulefield WHERE rule_id = '6a29eef4b56ef';

SELECT 'CRON' AS what, id, arguments, period, enable
FROM cron_job WHERE arguments = '6a29eef45ae50';
