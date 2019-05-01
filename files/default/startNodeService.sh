#!/bin/sh

# The OOB start/stop node scripts don't explicitly set up the
# profile name as a variable we can access

PROFILE_NAME=$(echo ${WAS_USER_SCRIPT} | awk -F '/' '{print $(NF-2)}')
NODE_NAME=${PROFILE_NAME}_node
sudo systemctl start ${NODE_NAME}
