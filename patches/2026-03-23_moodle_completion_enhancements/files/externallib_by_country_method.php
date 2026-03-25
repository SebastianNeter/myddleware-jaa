    /**
     * Returns description of method parameters for get_course_completion_percentage_by_country.
     */
    public static function get_course_completion_percentage_by_country_parameters() {
        return new external_function_parameters(
            array(
                'time_modified' => new external_value(PARAM_INT, 'completions modified after this timestamp', VALUE_DEFAULT, 0),
                'country_filter' => new external_value(PARAM_TEXT, 'Country profile field shortname (arg, roc, mex, ury, col, per)', VALUE_REQUIRED),
            )
        );
    }

    /**
     * Return course completion percentage filtered by user country profile field.
     */
    public static function get_course_completion_percentage_by_country($timemodified, $country_filter) {
        global $DB;

        $params = self::validate_parameters(
            self::get_course_completion_percentage_by_country_parameters(),
            array('time_modified' => $timemodified, 'country_filter' => $country_filter)
        );

        $context = \context_system::instance();
        self::validate_context($context);

        // Get completions filtered by country profile field
        $sql = "SELECT cmc.id, cmc.userid, cmc.timemodified, cm.course AS courseid
                FROM {course_modules_completion} cmc
                INNER JOIN {course_modules} cm ON cm.id = cmc.coursemoduleid
                INNER JOIN {user_info_data} uid ON uid.userid = cmc.userid
                INNER JOIN {user_info_field} uif ON uif.id = uid.fieldid
                WHERE cmc.timemodified > :timemodified
                  AND uif.shortname = :country_filter
                  AND uid.data = '1'
                ORDER BY cmc.timemodified ASC";

        $records = $DB->get_records_sql($sql, array(
            'timemodified' => $params['time_modified'],
            'country_filter' => $params['country_filter'],
        ));

        // Deduplicate: keep newest completion per user/course pair
        $selectedcompletions = array();
        foreach ($records as $record) {
            $key = $record->userid . '_' . $record->courseid;
            if (!isset($selectedcompletions[$key]) || $record->timemodified > $selectedcompletions[$key]->timemodified) {
                $selectedcompletions[$key] = $record;
            }
        }

        $completions = array();
        foreach ($selectedcompletions as $key => $record) {
            try {
                $course = $DB->get_record('course', array('id' => $record->courseid), '*', MUST_EXIST);
                $completion = new \completion_info($course);

                if (!$completion->is_enabled()) {
                    $completions[] = array(
                        'id' => $key,
                        'userid' => (int)$record->userid,
                        'courseid' => (int)$record->courseid,
                        'timemodified' => (int)$record->timemodified,
                        'percentage' => 0.0,
                        'completed_activities' => 0,
                        'total_activities' => 0,
                        'overall_status' => 'not_enabled',
                        'error' => '',
                    );
                    continue;
                }

                $iscomplete = $completion->is_course_complete($record->userid);
                $modinfo = get_fast_modinfo($course, $record->userid);
                $activities = $completion->get_activities();
                $total = count($activities);
                $completed = 0;

                foreach ($activities as $activity) {
                    $activitycompletion = $completion->get_data($activity, false, $record->userid);
                    if (in_array($activitycompletion->completionstate, array(COMPLETION_COMPLETE, COMPLETION_COMPLETE_PASS))) {
                        $completed++;
                    }
                }

                $percentage = ($total > 0) ? round(($completed / $total) * 100, 2) : 0.0;
                $status = $iscomplete ? 'complete' : ($completed > 0 ? 'in_progress' : 'not_started');

                $completions[] = array(
                    'id' => $key,
                    'userid' => (int)$record->userid,
                    'courseid' => (int)$record->courseid,
                    'timemodified' => (int)$record->timemodified,
                    'percentage' => $percentage,
                    'completed_activities' => $completed,
                    'total_activities' => $total,
                    'overall_status' => $status,
                    'error' => '',
                );
            } catch (\Exception $e) {
                $completions[] = array(
                    'id' => $key,
                    'userid' => (int)$record->userid,
                    'courseid' => (int)$record->courseid,
                    'timemodified' => (int)$record->timemodified,
                    'percentage' => 0.0,
                    'completed_activities' => 0,
                    'total_activities' => 0,
                    'overall_status' => 'error',
                    'error' => $e->getMessage(),
                );
            }
        }

        return $completions;
    }

    /**
     * Returns description of method result value for get_course_completion_percentage_by_country.
     */
    public static function get_course_completion_percentage_by_country_returns() {
        return new external_multiple_structure(
            new external_single_structure(
                array(
                    'id' => new external_value(PARAM_TEXT, 'Composite ID (userid_courseid)'),
                    'userid' => new external_value(PARAM_INT, 'User ID'),
                    'courseid' => new external_value(PARAM_INT, 'Course ID'),
                    'timemodified' => new external_value(PARAM_INT, 'Last modification timestamp'),
                    'percentage' => new external_value(PARAM_FLOAT, 'Completion percentage'),
                    'completed_activities' => new external_value(PARAM_INT, 'Number of completed activities'),
                    'total_activities' => new external_value(PARAM_INT, 'Total number of activities'),
                    'overall_status' => new external_value(PARAM_TEXT, 'Overall completion status'),
                    'error' => new external_value(PARAM_TEXT, 'Error message if any'),
                )
            )
        );
    }
