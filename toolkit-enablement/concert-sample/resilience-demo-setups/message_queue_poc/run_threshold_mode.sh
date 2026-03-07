#!/bin/bash
# Run Threshold Mode Simulator

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Starting THRESHOLD Mode Simulator${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Setup virtual environment
VENV_DIR="venv"
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create virtual environment${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source "$VENV_DIR/bin/activate"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to activate virtual environment${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Install dependencies if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install -q -r requirements.txt
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install dependencies${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${YELLOW}No requirements.txt found, skipping dependency installation${NC}"
fi

echo ""

# Kill any existing simulators
echo -e "${YELLOW}Stopping any existing simulators...${NC}"
pkill -f unified_threshold_simulator 2>/dev/null || true
sleep 2

# Clean up old queues
echo -e "${YELLOW}Cleaning up old queues...${NC}"
./cleanup_queues.sh

# Start simulator
echo -e "${GREEN}Starting threshold mode simulator...${NC}"
python unified_threshold_simulator.py --mode threshold --queue threshold_all_metrics &
SIMULATOR_PID=$!

echo ""
echo -e "${GREEN}✓ Simulator started (PID: ${SIMULATOR_PID})${NC}"
echo ""
echo -e "${YELLOW}Waiting 15 seconds for metrics to build up...${NC}"
sleep 15

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Current Metrics${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check metrics
echo '{"host":"9.46.252.85","queue":"threshold_all_metrics","dlq":"threshold_all_metrics_dlq","port":15672,"vhost":"/","username":"guest","password":"guest","format":"pretty"}' | \
    python get_advanced_metrics.py --json

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Simulator is running in background${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}PID: ${SIMULATOR_PID}${NC}"
echo ""
echo -e "To stop: ${GREEN}kill ${SIMULATOR_PID}${NC}"
echo -e "To check metrics again: ${GREEN}./check_unified_threshold.sh${NC}"
echo ""

