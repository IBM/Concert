#!/bin/bash

# Script to toggle maxThreads in server.xml for pct_thread_usage demo
# Usage: ./toggle_thread_usage.sh [remediate|create-issue]
# Password should be exported as: export SERVER_PASSWORD="password"

SERVER="9.30.146.45"

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
    echo "  remediate    - Set maxThreads=100 (fix: lower thread usage %)"
    echo "  create-issue - Set maxThreads=50 (issue: higher thread usage %)"
    exit 1
fi

ACTION="$1"

if [ "$ACTION" = "remediate" ]; then
    FROM_VALUE="50"
    TO_VALUE="100"
    ACTION_DESC="REMEDIATING thread usage issue"
    METRIC_CHANGE="pct_thread_usage should DECREASE"
elif [ "$ACTION" = "create-issue" ]; then
    FROM_VALUE="100"
    TO_VALUE="50"
    ACTION_DESC="CREATING thread usage issue for demo"
    METRIC_CHANGE="pct_thread_usage should INCREASE"
else
    echo "Error: Invalid argument '$ACTION'"
    echo "Use 'remediate' or 'create-issue'"
    exit 1
fi

echo "=========================================="
echo "$ACTION_DESC"
echo "Setting maxThreads=$TO_VALUE on server $SERVER"
echo "=========================================="

echo ""
echo "Processing server: $SERVER"
echo "---"

sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << ENDSSH
    echo "Updating server.xml..."
    sed -i 's/maxThreads="$FROM_VALUE"/maxThreads="$TO_VALUE"/g' /opt/tomcat/conf/server.xml
    
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
    
    echo "Restarting Tomcat..."
    systemctl restart tomcat
    
    echo "Waiting for Tomcat to start..."
    sleep 10
    
    echo "✓ Changed maxThreads to $TO_VALUE on \$(hostname)"
ENDSSH

if [ $? -eq 0 ]; then
    echo "✓ Successfully updated $SERVER"
else
    echo "✗ Failed to update $SERVER"
fi

echo ""
echo "=========================================="
echo "Update complete!"
echo "maxThreads is now set to: $TO_VALUE"
echo ""
echo "Run discovery workflow to verify"
echo "=========================================="