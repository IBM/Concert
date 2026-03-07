#!/bin/bash

# Script to toggle privileged flag on all 3 VMs
# Usage: ./toggle_privileged.sh [remediate|create-issue]
# Password should be exported as: export SERVER_PASSWORD="password"

SERVERS=("9.30.205.88" "9.30.146.45" "9.30.79.62")

# Get password from environment variable
if [ -z "$SERVER_PASSWORD" ]; then
    echo "Error: SERVER_PASSWORD environment variable not set"
    exit 1
fi

# Get action (remediate or create-issue)
if [ -z "$1" ]; then
    echo "Usage: $0 [remediate|create-issue]"
    echo ""
    echo "  remediate    - Set privileged=false (fix security issue)"
    echo "  create-issue - Set privileged=true (demonstrate security issue)"
    exit 1
fi

ACTION="$1"

if [ "$ACTION" = "remediate" ]; then
    FROM_VALUE="true"
    TO_VALUE="false"
    ACTION_DESC="REMEDIATING security issue"
    METRIC_CHANGE="num_runtime_running_as_root should DECREASE"
elif [ "$ACTION" = "create-issue" ]; then
    FROM_VALUE="false"
    TO_VALUE="true"
    ACTION_DESC="CREATING security issue for demo"
    METRIC_CHANGE="num_runtime_running_as_root should INCREASE"
else
    echo "Error: Invalid argument '$ACTION'"
    echo "Use 'remediate' or 'create-issue'"
    exit 1
fi

echo "=========================================="
echo "$ACTION_DESC"
echo "Setting privileged=$TO_VALUE on all servers"
echo "=========================================="

for SERVER in "${SERVERS[@]}"; do
    echo ""
    echo "Processing server: $SERVER"
    echo "---"
    
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << ENDSSH
        echo "Updating context.xml..."
        sed -i 's/privileged="$FROM_VALUE"/privileged="$TO_VALUE"/g' /opt/tomcat/conf/context.xml
        
        echo "Restarting Tomcat..."
        systemctl restart tomcat
        
        echo "✓ Changed privileged to $TO_VALUE on \$(hostname)"
ENDSSH
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully updated $SERVER"
    else
        echo "✗ Failed to update $SERVER"
    fi
done

echo ""
echo "=========================================="
echo "Update complete on all servers!"
echo "privileged is now set to: $TO_VALUE"
echo ""
echo "Run discovery workflow to verify:"

echo "=========================================="

