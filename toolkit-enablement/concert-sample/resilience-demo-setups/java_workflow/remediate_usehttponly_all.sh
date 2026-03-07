#!/bin/bash

# Script to toggle useHttpOnly flag on all 3 VMs
# Usage: ./toggle_usehttponly.sh [remediate|create-issue]
# Password should be exported as: export SERVER_PASSWORD="password"

SERVERS=("9.30.205.88" "9.30.146.45" "9.30.79.62")

# Get password from environment variable
if [ -z "$SERVER_PASSWORD" ]; then
    echo "Error: SERVER_PASSWORD environment variable not set"
    echo "Please run: export SERVER_PASSWORD='password'"
    exit 1
fi

# Get action (remediate or create-issue)
if [ -z "$1" ]; then
    echo "Usage: $0 [remediate|create-issue]"
    echo ""
    echo "  remediate    - Set useHttpOnly=false (fix: num_http_only = 0)"
    echo "  create-issue - Set useHttpOnly=true (issue: num_http_only increases)"
    exit 1
fi

ACTION="$1"

if [ "$ACTION" = "remediate" ]; then
    FROM_VALUE="true"
    TO_VALUE="false"
    ACTION_DESC="REMEDIATING security issue"
    METRIC_CHANGE="num_http_only should be 0"
elif [ "$ACTION" = "create-issue" ]; then
    FROM_VALUE="false"
    TO_VALUE="true"
    ACTION_DESC="CREATING security issue for demo"
    METRIC_CHANGE="num_http_only should INCREASE"
else
    echo "Error: Invalid argument '$ACTION'"
    echo "Use 'remediate' or 'create-issue'"
    exit 1
fi

echo "=========================================="
echo "$ACTION_DESC"
echo "Setting useHttpOnly=$TO_VALUE on all servers"
echo "=========================================="

for SERVER in "${SERVERS[@]}"; do
    echo ""
    echo "Processing server: $SERVER"
    echo "---"
    
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << ENDSSH
        echo "Updating context.xml..."
        sed -i 's/useHttpOnly="$FROM_VALUE"/useHttpOnly="$TO_VALUE"/g' /opt/tomcat/conf/context.xml
        
        echo "Restarting Tomcat..."
        systemctl restart tomcat
        
        echo "✓ Changed useHttpOnly to $TO_VALUE on \$(hostname)"
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
echo "useHttpOnly is now set to: $TO_VALUE"
echo ""
echo "Run discovery workflow to verify:"
echo "=========================================="

