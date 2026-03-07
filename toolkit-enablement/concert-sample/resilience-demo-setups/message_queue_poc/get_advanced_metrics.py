#!/usr/bin/env python3
"""
RabbitMQ Advanced Metrics Fetcher
Fetches all 7 metrics for the message queue library:
- consumer_utilisation
- dlq_queue_depth
- message_ack_rate
- message_delivery_rate
- num_consumers
- publish_rate
- queue_depth

Supports multiple input methods:
1. Positional arguments: script.py host queue [port] [vhost] [username] [password] [dlq]
2. Named arguments: script.py --host HOST --queue QUEUE
3. JSON input: echo '{"host":"...","queue":"..."}' | script.py --json
4. JSON file: script.py --json-file config.json
"""

import requests
from requests.auth import HTTPBasicAuth
import json
import sys
import argparse


def get_queue_metrics(host, port, vhost, queue, dlq, username, password):
    """Fetch comprehensive queue metrics from RabbitMQ Management API"""
    base_url = f"http://{host}:{port}"
    
    # URL encode vhost if needed
    vhost_encoded = vhost.replace('/', '%2F')
    
    main_queue_url = f"{base_url}/api/queues/{vhost_encoded}/{queue}"
    dlq_url = f"{base_url}/api/queues/{vhost_encoded}/{dlq}"
    
    try:
        # Fetch main queue metrics
        main_res = requests.get(main_queue_url, auth=HTTPBasicAuth(username, password), timeout=5)
        if main_res.status_code != 200:
            return {"error": f"Failed to fetch main queue metrics. Status: {main_res.status_code}"}
        
        main_data = main_res.json()
        
        # Fetch DLQ metrics
        dlq_res = requests.get(dlq_url, auth=HTTPBasicAuth(username, password), timeout=5)
        dlq_depth = 0
        if dlq_res.status_code == 200:
            dlq_data = dlq_res.json()
            dlq_depth = dlq_data.get("messages", 0)
        
        # Extract metrics
        message_stats = main_data.get("message_stats", {})
        
        # Get rates (messages per second from API, convert to per minute)
        publish_rate_per_sec = message_stats.get("publish_details", {}).get("rate", 0)
        deliver_rate_per_sec = message_stats.get("deliver_details", {}).get("rate", 0)
        ack_rate_per_sec = message_stats.get("ack_details", {}).get("rate", 0)
        
        # Convert to per minute
        publish_rate = round(publish_rate_per_sec * 60, 2)
        message_delivery_rate = round(deliver_rate_per_sec * 60, 2)
        message_ack_rate = round(ack_rate_per_sec * 60, 2)
        
        # Get consumer information
        num_consumers = main_data.get("consumers", 0)
        
        # Calculate consumer utilization
        # Better heuristic based on queue depth and delivery rate
        consumer_utilisation = 0.0
        if num_consumers > 0:
            queue_depth = main_data.get("messages", 0)
            if deliver_rate_per_sec > 0:
                # Calculate utilization based on queue backlog and processing rate
                # If queue is growing (>100 messages), consumers are highly utilized
                # If queue is stable/empty (<100 messages), consumers have spare capacity
                
                per_consumer_rate = deliver_rate_per_sec / num_consumers
                
                if queue_depth > 1000:
                    # Large backlog = consumers working at max capacity
                    consumer_utilisation = min(95.0, 85.0 + (queue_depth / 1000) * 5)
                elif queue_depth > 100:
                    # Moderate backlog = high utilization
                    consumer_utilisation = 70.0 + (queue_depth / 100) * 10
                else:
                    # Low/no backlog = consumers keeping up easily
                    # Base utilization on actual processing rate
                    # Assume max capacity is ~50 msg/sec per consumer for 100% util
                    consumer_utilisation = min(75.0, (per_consumer_rate / 50.0) * 100)
            else:
                consumer_utilisation = 0.0
        
        # Get queue depth
        queue_depth = main_data.get("messages", 0)
        
        # Return all 7 metrics plus metadata
        metrics = {
            "consumer_utilisation": str(round(consumer_utilisation, 2)), # we need to revisit this metric
            "dlq_queue_depth": str(dlq_depth),
            "message_ack_rate": str(message_ack_rate),
            "message_delivery_rate": str(message_delivery_rate),
            "num_consumers": str(num_consumers),
            "publish_rate": str(publish_rate),
            "queue_depth": str(queue_depth)
        }
        
        return metrics
        
    except requests.exceptions.RequestException as e:
        return {"error": f"Request exception: {str(e)}"}
    except Exception as e:
        return {"error": f"Exception occurred: {str(e)}"}


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='RabbitMQ Advanced Metrics Fetcher')
    
    parser.add_argument('--host', default='9.46.252.85', help='RabbitMQ host')
    parser.add_argument('--port', type=int, default=15672, help='Management API port')
    parser.add_argument('--vhost', default='/', help='Virtual host')
    parser.add_argument('--queue', default='threshold_all_metrics', help='Main queue name')
    parser.add_argument('--dlq', default='threshold_all_metrics_dlq', help='Dead letter queue name')
    parser.add_argument('--username', default='guest', help='Username')
    parser.add_argument('--password', default='guest', help='Password')
    parser.add_argument('--format', choices=['json', 'pretty'], default='json', help='Output format')
    parser.add_argument('--json', action='store_true', help='Read JSON config from stdin')
    parser.add_argument('--json-file', help='Read JSON config from file')
    
    return parser.parse_args()


def load_config_from_json(json_input):
    """Load configuration from JSON string or file"""
    try:
        config = json.loads(json_input) if isinstance(json_input, str) else json.load(json_input)
        
        # Set defaults for missing fields
        return {
            'host': config.get('host', '9.46.252.85'),
            'port': config.get('port', 15672),
            'vhost': config.get('vhost', '/'),
            'queue': config.get('queue', 'demo_queue_advanced'),
            'dlq': config.get('dlq', config.get('queue', 'demo_queue_advanced') + '_dlq'),
            'username': config.get('username', 'guest'),
            'password': config.get('password', 'guest'),
            'format': config.get('format', 'json')
        }
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error loading config: {e}", file=sys.stderr)
        sys.exit(1)


def format_output(metrics, format_type='json'):
    """Format metrics output"""
    if format_type == 'pretty':
        if 'error' in metrics:
            return f"Error: {metrics['error']}"
        
        output = "\n" + "="*60 + "\n"
        output += "Message Queue Metrics\n"
        output += "="*60 + "\n"
        output += f"Consumer Utilisation:    {metrics['consumer_utilisation']}%\n"
        output += f"DLQ Queue Depth:         {metrics['dlq_queue_depth']}\n"
        output += f"Message Ack Rate:        {metrics['message_ack_rate']} msg/min\n"
        output += f"Message Delivery Rate:   {metrics['message_delivery_rate']} msg/min\n"
        output += f"Number of Consumers:     {metrics['num_consumers']}\n"
        output += f"Publish Rate:            {metrics['publish_rate']} msg/min\n"
        output += f"Queue Depth:             {metrics['queue_depth']}\n"
        output += "="*60 + "\n"
        return output
    else:
        return json.dumps(metrics, indent=2)


if __name__ == "__main__":
    # Parse arguments first to check for JSON input flags
    args = parse_arguments()
    
    # Determine input method
    if args.json:
        # Read JSON from stdin
        try:
            json_input = sys.stdin.read()
            config = load_config_from_json(json_input)
        except Exception as e:
            print(f"Error reading from stdin: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.json_file:
        # Read JSON from file
        try:
            with open(args.json_file, 'r') as f:
                config = load_config_from_json(f.read())
        except FileNotFoundError:
            print(f"Error: File not found: {args.json_file}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error reading file: {e}", file=sys.stderr)
            sys.exit(1)
    elif len(sys.argv) > 1 and not sys.argv[1].startswith('--'):
        # Positional argument mode (like get_queue_metrics.py)
        # Usage: script.py host queue [port] [vhost] [username] [password] [dlq]
        config = {
            'host': sys.argv[1] if len(sys.argv) > 1 else "9.46.252.85",
            'queue': sys.argv[2] if len(sys.argv) > 2 else "demo_queue_advanced",
            'port': int(sys.argv[3]) if len(sys.argv) > 3 else 15672,
            'vhost': sys.argv[4] if len(sys.argv) > 4 else "%2F",
            'username': sys.argv[5] if len(sys.argv) > 5 else "guest",
            'password': sys.argv[6] if len(sys.argv) > 6 else "guest",
            'dlq': sys.argv[7] if len(sys.argv) > 7 else f"{sys.argv[2]}_dlq" if len(sys.argv) > 2 else "demo_queue_advanced_dlq",
            'format': 'json'
        }
    else:
        # Named argument mode (argparse)
        config = {
            'host': args.host,
            'port': args.port,
            'vhost': args.vhost,
            'queue': args.queue,
            'dlq': args.dlq,
            'username': args.username,
            'password': args.password,
            'format': args.format
        }
    
    # Decode vhost if it's URL encoded
    if config['vhost'] == "%2F":
        config['vhost'] = "/"
    
    # Fetch metrics
    metrics = get_queue_metrics(
        config['host'],
        config['port'],
        config['vhost'],
        config['queue'],
        config['dlq'],
        config['username'],
        config['password']
    )
    
    # Output metrics
    print(format_output(metrics, config['format']))
    
    # Exit with appropriate code
    sys.exit(0 if "error" not in metrics else 1)


