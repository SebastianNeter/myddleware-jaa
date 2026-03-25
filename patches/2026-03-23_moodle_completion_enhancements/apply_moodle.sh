#!/bin/bash
# Patch: Moodle Completion Enhancements
# Target: Moodle container plugin /var/www/html/local/myddleware/
#
# This script applies:
# 1. Rename id → userid_courseid in get_course_completion_percentage
# 2. New method get_course_completion_percentage_by_country
# 3. Register function in services.php
# 4. Bump version.php
#
# Usage: Run commands via SSM on the Moodle EC2 instance
# Container ID may change — verify with: sudo docker ps | grep moodle

set -e

MOODLE_CONTAINER="${1:-90bbc46bc607}"
PLUGIN_PATH="/var/www/html/local/myddleware"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

echo "=== Moodle Completion Enhancements Patch ==="
echo "Container: $MOODLE_CONTAINER"
echo "Plugin: $PLUGIN_PATH"
echo ""

# Step 1: Backup
echo "--- Step 1: Backing up files ---"
sudo docker exec "$MOODLE_CONTAINER" cp "$PLUGIN_PATH/externallib.php" "$PLUGIN_PATH/externallib.php.bak.$TIMESTAMP"
sudo docker exec "$MOODLE_CONTAINER" cp "$PLUGIN_PATH/db/services.php" "$PLUGIN_PATH/db/services.php.bak.$TIMESTAMP"
sudo docker exec "$MOODLE_CONTAINER" cp "$PLUGIN_PATH/version.php" "$PLUGIN_PATH/version.php.bak.$TIMESTAMP"
echo "Backups created with timestamp $TIMESTAMP"

# Step 2: Create PHP patch script on host, copy to container, execute
echo ""
echo "--- Step 2: Apply externallib.php changes ---"
echo "Create patch script at /tmp/patch_externallib.php and run:"
echo "  sudo docker cp /tmp/patch_externallib.php $MOODLE_CONTAINER:/tmp/"
echo "  sudo docker exec $MOODLE_CONTAINER php /tmp/patch_externallib.php"
echo ""
echo "The patch script should:"
echo "  a) Rename 'id' → 'userid_courseid' (6 occurrences in get_course_completion_percentage)"
echo "  b) Change \$id = \$userid_courseid → \$id = 0"
echo "  c) Insert new method from files/externallib_by_country_method.php before closing }"
echo ""

# Step 3: services.php
echo "--- Step 3: Register in services.php ---"
echo "Add to \$functions array:"
echo "  'local_myddleware_get_course_completion_percentage_by_country' => ["
echo "      'classname'   => 'local_myddleware_external',"
echo "      'methodname'  => 'get_course_completion_percentage_by_country',"
echo "      'classpath'   => 'local/myddleware/externallib.php',"
echo "      'description' => 'Return completion percentage filtered by user country profile field',"
echo "      'type'        => 'read',"
echo "  ],"
echo ""
echo "Add to \$services['Myddleware service']['functions']:"
echo "  'local_myddleware_get_course_completion_percentage_by_country',"
echo ""

# Step 4: version.php
echo "--- Step 4: Bump version ---"
echo "  sudo docker exec $MOODLE_CONTAINER sed -i 's/2025061805/2025061806/' $PLUGIN_PATH/version.php"
echo ""

# Step 5: Upgrade
echo "--- Step 5: Run Moodle upgrade ---"
echo "  sudo docker exec $MOODLE_CONTAINER php /var/www/html/admin/cli/upgrade.php --non-interactive"
echo ""

echo "=== Patch instructions complete ==="
echo "Verify with:"
echo "  curl 'https://<moodle_url>/webservice/rest/server.php?wstoken=<token>&wsfunction=local_myddleware_get_course_completion_percentage_by_country&moodlewsrestformat=json&country_filter=arg&time_modified=0'"
