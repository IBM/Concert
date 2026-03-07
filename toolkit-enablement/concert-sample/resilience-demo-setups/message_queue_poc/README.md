# Message Queue Unified Threshold Simulator

A comprehensive RabbitMQ simulator and metrics fetcher for testing message queue behavior under different load conditions. This tool simulates both **threshold-breaching** (overload) and **normal/healthy** system scenarios to validate monitoring thresholds and system behavior.

## Overview

This simulator tests all 7 critical message queue metrics defined in the IBM Concert message queue library:

1. **consumer_utilisation** - Percentage of time consumers are busy processing messages
2. **dlq_queue_depth** - Number of messages in the Dead Letter Queue
3. **message_ack_rate** - Messages acknowledged per minute
4. **message_delivery_rate** - Messages delivered to consumers per minute
5. **num_consumers** - Number of active consumers
6. **publish_rate** - Messages published per minute
7. **queue_depth** - Current number of messages in the queue

## Files

| File | Description |
|------|-------------|
| [`unified_threshold_simulator.py`](unified_threshold_simulator.py) | Main simulator with configurable threshold/normal modes |
| [`get_advanced_metrics.py`](get_advanced_metrics.py) | Fetches all 7 metrics from RabbitMQ Management API. This script will be used in workflow to get the value of the metrics|
| [`run_threshold_mode.sh`](run_threshold_mode.sh) | Shell script to run threshold-breaching scenario |
| [`run_normal_mode.sh`](run_normal_mode.sh) | Shell script to run normal/healthy scenario |
| [`cleanup_queues.sh`](cleanup_queues.sh) | Cleanup script to delete simulator queues |

## Prerequisites

### System Requirements

- **Python**: 3.6 or higher
- **RabbitMQ**: 3.8 or higher (running and accessible)
- **curl**: For cleanup script
- **bash**: For shell scripts

### Python Environment Setup

#### 1. Create Virtual Environment

```bash
# Navigate to the project directory
cd /message_queue_poc

# Create a virtual environment
python3 -m venv venv

# Activate the virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
# venv\Scripts\activate
```

#### 2. Install Required Packages

```bash
# Upgrade pip (recommended)
pip install --upgrade pip

# Install required packages
pip install pika requests

```

#### 3. Verify Installation

```bash
# Check installed packages
pip list | grep -E "pika|requests"

# Expected output:
# pika            1.3.x
# requests        2.31.x
```

### RabbitMQ Setup

#### 1. Install RabbitMQ as a service
docker run -d --name rabbitmq   -p 5672:5672   -p 15672:15672   rabbitmq:3.13-management

#### 2. Verify Installation and Connectivity    
Ensure RabbitMQ is running and accessible:
- RabbitMQ is running
- The Python script can connect to RabbitMQ
- The Python script can send and receive messages from RabbitMQ

### Make Scripts Executable

```bash
# Make shell scripts executable
chmod +x run_threshold_mode.sh
chmod +x run_normal_mode.sh
chmod +x cleanup_queues.sh
```

### Verify Setup

```bash
# Test the metrics fetcher
python get_advanced_metrics.py --help

# Test the simulator
python unified_threshold_simulator.py --help
```

## Quick Start

### 1. Run Threshold Mode (Overload Scenario)

Simulates a system under stress where thresholds are breached:

```bash
./run_threshold_mode.sh
```

**Expected Behavior:**
- Queue depth exceeds 1000 messages within ~6 seconds
- Publish rate: ~12,000 msg/min (breaches >10,000 threshold)
- Consumers cannot keep up with producers
- 5% message rejection rate → DLQ accumulation
- 3 consumers with 0.1s processing delay

### 2. Run Normal Mode (Healthy Scenario)

Simulates a well-balanced, healthy system:

```bash
./run_normal_mode.sh
```

**Expected Behavior:**
- Queue depth stays stable at 0-100 messages
- Publish rate: ~10,800 msg/min (above threshold but manageable)
- Consumers keep up perfectly with producers
- 0% message rejection rate → no DLQ accumulation
- 20 consumers with 0.004s processing delay (25x faster than threshold mode)

### 3. Fetch Current Metrics

While the simulator is running, This script will be used in workflow to get the value of the metrics

```bash
# Pretty formatted output
python get_advanced_metrics.py --format pretty

# JSON output (default)
python get_advanced_metrics.py

# Using JSON input
echo '{"host":"9.46.252.85","queue":"threshold_all_metrics","dlq":"threshold_all_metrics_dlq","port":15672,"vhost":"/","username":"guest","password":"guest","format":"pretty"}' | \
    python get_advanced_metrics.py --json
```

### 4. Cleanup

Stop simulators and clean up queues:

```bash
# Kill running simulators
pkill -f unified_threshold_simulator

# Clean up queues
./cleanup_queues.sh
```

## Simulator Modes Comparison

| Aspect | Threshold Mode | Normal Mode |
|--------|---------------|-------------|
| **Purpose** | Breach thresholds | Healthy operation |
| **Publish Rate** | 200 msg/sec (12,000/min) | 180 msg/sec (10,800/min) |
| **Consumers** | 3 | 20 |
| **Processing Delay** | 0.1s per message | 0.004s per message |
| **Consumer Capacity** | 30 msg/sec total | 5,000 msg/sec total |
| **Rejection Rate** | 5% | 0% |
| **Queue Depth** | Grows continuously (>1000) | Stable (0-100) |
| **DLQ Depth** | Accumulates (50-150) | Zero |
| **Consumer Utilization** | 60-80% | ~35% |

## Configuration Parameters

### Unified Threshold Simulator

#### Connection Parameters
```bash
--host          RabbitMQ host (default: 9.46.252.85)
--port          AMQP port (default: 5672)
--vhost         Virtual host (default: /)
--username      Username (default: guest)
--password      Password (default: guest)
```

#### Queue Parameters
```bash
--queue         Queue name (default: threshold_all_metrics)
--mode          Simulation mode: threshold or normal (default: threshold)
```

#### JSON Input Support
```bash
--json          Read configuration from stdin as JSON
```

**Example:**
```bash
echo '{"host":"9.46.252.85","queue":"my_queue","mode":"normal"}' | \
    python unified_threshold_simulator.py --json
```

### Metrics Fetcher

#### Connection Parameters
```bash
--host          RabbitMQ host (default: 9.46.252.85)
--port          Management API port (default: 15672)
--vhost         Virtual host (default: /)
--username      Username (default: guest)
--password      Password (default: guest)
```

#### Queue Parameters
```bash
--queue         Main queue name (default: threshold_all_metrics)
--dlq           Dead letter queue name (default: threshold_all_metrics_dlq)
```

#### Output Options
```bash
--format        Output format: json or pretty (default: json)
--json          Read configuration from stdin as JSON
--json-file     Read configuration from JSON file
```

## Usage Examples

### Running Simulator with Custom Configuration

```bash
# Threshold mode with custom queue
python unified_threshold_simulator.py --mode threshold --queue my_test_queue

# Normal mode with custom host
python unified_threshold_simulator.py --mode normal --host 192.168.1.100 --queue my_queue

# Using JSON configuration
echo '{"host":"9.46.252.85","queue":"custom_queue","mode":"threshold"}' | \
    python unified_threshold_simulator.py --json
```

### Fetching Metrics with Different Methods

```bash
# Method 1: Named arguments
python get_advanced_metrics.py --host 9.46.252.85 --queue threshold_all_metrics --format pretty

# Method 2: Positional arguments
python get_advanced_metrics.py 9.46.252.85 threshold_all_metrics

# Method 3: JSON from stdin
echo '{"host":"9.46.252.85","queue":"threshold_all_metrics","format":"pretty"}' | \
    python get_advanced_metrics.py --json

# Method 4: JSON from file
python get_advanced_metrics.py --json-file config.json
```

## Monitoring and Analysis

### Key Metrics to Watch

1. **Queue Depth Trend**
   - **Threshold Mode**: Should grow continuously, exceeding 1000
   - **Normal Mode**: Should remain stable at 0-100

2. **Publish vs Ack Rate**
   - **Threshold Mode**: Publish rate >> Ack rate (imbalance)
   - **Normal Mode**: Publish rate ≈ Ack rate (balanced)

3. **DLQ Accumulation**
   - **Threshold Mode**: Grows due to 5% rejection rate
   - **Normal Mode**: Stays at zero (no rejections)

4. **Consumer Utilization**
   - **Threshold Mode**: 60-80% (consumers working hard but can't keep up)
   - **Normal Mode**: ~35% (consumers working efficiently with capacity to spare)

## Troubleshooting

### Queue Fills Up Quickly
**Symptoms**: Queue depth grows rapidly, consumers can't keep up

**Solutions**:
- Increase number of consumers
- Decrease consumer processing time
- Reduce publish rate
- Check for consumer errors or bottlenecks

### High DLQ Depth
**Symptoms**: Dead letter queue accumulating messages

**Solutions**:
- Investigate message processing failures
- Review error logs
- Check message format/validation
- Reduce rejection rate in testing scenarios

### Low Consumer Utilization
**Symptoms**: Consumers idle most of the time

**Solutions**:
- Increase publish rate
- Reduce number of consumers
- Optimize consumer processing time

### Connection Errors
**Symptoms**: Cannot connect to RabbitMQ

**Solutions**:
- Verify RabbitMQ is running: `systemctl status rabbitmq-server`
- Check host and port configuration
- Verify credentials (username/password)
- Ensure network connectivity
- Check firewall rules

### Metrics Not Updating
**Symptoms**: Metrics show zero or stale values

**Solutions**:
- Ensure simulator is running: `ps aux | grep unified_threshold_simulator`
- Wait 10-15 seconds for metrics to stabilize
- Check RabbitMQ Management API is accessible
- Verify queue names match between simulator and metrics fetcher

## Integration with IBM Concert

This simulator aligns with the IBM Concert message queue library requirements defined in:
- [`api/data-models/reference-data/g_fwk/message_queue/message_queue_library.json`](../../../api/data-models/reference-data/g_fwk/message_queue/message_queue_library.json)
- [`api/data-models/reference-data/g_fwk/message_queue/input_data_keys.json`](../../../api/data-models/reference-data/g_fwk/message_queue/input_data_keys.json)
- [`api/data-models/reference-data/g_fwk/message_queue/externals_en.json`](../../../api/data-models/reference-data/g_fwk/message_queue/externals_en.json)

Sample custom library PR : https://github.ibm.com/roja/roja-py-utils/pull/3802


### Queue Configuration

- **Max Length**: 10,000 messages (high capacity for testing)
- **Durability**: Enabled (messages persist across restarts)
- **Dead Letter Exchange**: Configured for rejected messages
- **Message TTL**: 5 seconds (threshold mode only, for DLQ testing)

### Thread Safety

- Each producer and consumer runs in a separate thread
- Connections are thread-local (one per thread)
- Graceful shutdown on Ctrl+C

## Best Practices

1. **Always cleanup** between test runs to ensure clean state
2. **Wait 10-15 seconds** after starting simulator before checking metrics
3. **Monitor both modes** to understand the full spectrum of behavior
4. **Use JSON input** for automated/scripted scenarios
5. **Check logs** (stderr) for detailed simulation progress
6. **Stop simulators** properly using `pkill` or Ctrl+C

## License

Internal IBM tool for Concert platform testing and validation.
