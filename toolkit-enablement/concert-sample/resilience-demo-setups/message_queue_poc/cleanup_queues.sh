#!/bin/bash
# Cleanup all simulator queues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Cleaning Up Simulator Queues${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# RabbitMQ connection details
HOST="9.46.252.85"
PORT="15672"
USER="guest"
PASS="guest"
VHOST="%2F"

# Array of queue names to delete
queues=(
    "threshold_all_metrics"
    "threshold_all_metrics_dlq"
)

# Function to delete a queue and its DLQ
delete_queue() {
    local queue=$1
    local dlq="${queue}_dlq"
    
    echo -e "${YELLOW}Deleting: $queue${NC}"
    
    # Delete main queue
    response=$(curl -s -o /dev/null -w "%{http_code}" -u $USER:$PASS \
        -X DELETE "http://$HOST:$PORT/api/queues/$VHOST/$queue")
    
    if [ "$response" = "204" ] || [ "$response" = "404" ]; then
        echo -e "${GREEN}  ✓ Main queue deleted (or didn't exist)${NC}"
    else
        echo -e "${RED}  ✗ Failed to delete main queue (HTTP $response)${NC}"
    fi
    
    # Delete DLQ
    response=$(curl -s -o /dev/null -w "%{http_code}" -u $USER:$PASS \
        -X DELETE "http://$HOST:$PORT/api/queues/$VHOST/$dlq")
    
    if [ "$response" = "204" ] || [ "$response" = "404" ]; then
        echo -e "${GREEN}  ✓ DLQ deleted (or didn't exist)${NC}"
    else
        echo -e "${RED}  ✗ Failed to delete DLQ (HTTP $response)${NC}"
    fi
    
    echo ""
}

# Delete all queues
for queue in "${queues[@]}"; do
    delete_queue "$queue"
done

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}You can now start fresh with:${NC}"
echo -e "  ${GREEN}python unified_threshold_simulator.py --mode threshold${NC}"
echo -e "  ${GREEN}python unified_threshold_simulator.py --mode normal${NC}"

