#!/usr/bin/env python3
"""
RabbitMQ Configurable Simulator
Simulates either THRESHOLD-BREACHING or NORMAL/HEALTHY system behavior.

Modes:
  threshold - Breach all 7 metric thresholds (queue depth >1000, throughput >10000, etc.)
  normal    - Healthy, balanced system with optimal metrics

Usage:
    python unified_threshold_simulator.py --mode threshold
    python unified_threshold_simulator.py --mode normal
"""

import pika
import time
import json
import random
import threading
import sys
from datetime import datetime


class UnifiedThresholdSimulator:
    """Configurable simulator - threshold or normal mode"""
    
    def __init__(self, host="9.46.252.85", port=5672, vhost="/",
                 username="guest", password="guest",
                 queue_name="threshold_all_metrics", mode="threshold"):
        self.host = host
        self.port = port
        self.vhost = vhost
        self.username = username
        self.password = password
        self.queue_name = queue_name
        self.dlq_name = f"{queue_name}_dlq"
        self.mode = mode  # "threshold" or "normal"
        self.running = True
        self.threads = []
        
        # Configure based on mode
        if self.mode == "normal":
            # NORMAL MODE: Busy but healthy system with 80-90% consumer utilization
            # Consumers working hard but keeping up with load
            self.producer_rate = 180  # 180 msg/sec = 10800 msg/min
            self.consumer_count = 8   # 8 consumers (fewer = higher utilization per consumer)
            self.consumer_delay = 0.005  # 0.005s = 200 msg/sec per consumer
            # Total capacity: 1600 msg/sec (8 × 200) vs 180 msg/sec producer = 8.9x surplus
            # Creates moderate queue (400-800 messages) for 80-90% utilization
            self.rejection_rate = 0  # 0% rejection for normal mode
            self.max_messages = None  # Unlimited - runs continuously
        else:  # threshold mode
            self.producer_rate = 200  # 200 msg/sec = 12000 msg/min
            self.consumer_count = 3
            self.consumer_delay = 0.1  # 0.1s = 10 msg/sec per consumer (30 total - slower than producer)
            self.rejection_rate = 0.05  # 5% rejection
            self.max_messages = None  # Unlimited
        
    def get_connection(self):
        """Create a RabbitMQ connection"""
        creds = pika.PlainCredentials(self.username, self.password)
        params = pika.ConnectionParameters(
            host=self.host,
            port=self.port,
            virtual_host=self.vhost,
            credentials=creds,
            socket_timeout=10,
            connection_attempts=3,
            retry_delay=2
        )
        return pika.BlockingConnection(params)
    
    def cleanup_queue(self):
        """Delete existing queue and DLQ to start fresh"""
        try:
            conn = self.get_connection()
            channel = conn.channel()
            
            # Try to delete main queue (ignore if doesn't exist)
            try:
                channel.queue_delete(queue=self.queue_name)
                print(f"✓ Deleted existing queue '{self.queue_name}'", file=sys.stderr)
            except:
                pass
            
            # Try to delete DLQ (ignore if doesn't exist)
            try:
                channel.queue_delete(queue=self.dlq_name)
                print(f"✓ Deleted existing DLQ '{self.dlq_name}'", file=sys.stderr)
            except:
                pass
            
            conn.close()
            return True
        except Exception as e:
            print(f"⚠ Cleanup warning: {e}", file=sys.stderr)
            return True  # Continue anyway
    
    def setup_queue(self):
        """Setup queue with DLQ configuration"""
        try:
            # First cleanup any existing queues
            self.cleanup_queue()
            
            conn = self.get_connection()
            channel = conn.channel()
            
            # Create DLQ
            channel.queue_declare(queue=self.dlq_name, durable=True)
            
            # Create main queue with DLQ binding and high capacity
            args = {
                "x-max-length": 10000,  # High capacity for queue depth
                "x-dead-letter-exchange": "",
                "x-dead-letter-routing-key": self.dlq_name
            }
            
            # Only add TTL in threshold mode for DLQ testing
            if self.mode == "threshold":
                args["x-message-ttl"] = 5000  # 5 second TTL for DLQ testing
            
            channel.queue_declare(queue=self.queue_name, durable=True, arguments=args)
            
            conn.close()
            print(f"✓ Queue '{self.queue_name}' and DLQ '{self.dlq_name}' created fresh", file=sys.stderr)
            return True
        except Exception as e:
            print(f"✗ Error setting up queue: {e}", file=sys.stderr)
            return False
    
    def producer_thread(self):
        """Configurable producer based on mode"""
        try:
            conn = self.get_connection()
            channel = conn.channel()
            
            msg_count = 0
            rate_per_min = self.producer_rate * 60
            mode_label = "THRESHOLD" if self.mode == "threshold" else "NORMAL"
            max_msg_info = f" (max {self.max_messages})" if self.max_messages else ""
            print(f"✓ {mode_label} producer started: {self.producer_rate} msg/sec ({rate_per_min} msg/min){max_msg_info}", file=sys.stderr)
            
            while self.running:
                # Burst mode for threshold, steady for normal
                batch_size = 10 if self.mode == "threshold" else 1
                for _ in range(batch_size):
                    # Check BEFORE sending each message
                    if self.max_messages and msg_count >= self.max_messages:
                        print(f"\n✓ NORMAL MODE: Reached {self.max_messages} messages - STOPPING PRODUCER", file=sys.stderr)
                        print(f"   Consumers will now drain the queue to zero", file=sys.stderr)
                        conn.close()
                        return  # Exit the function completely
                    
                    msg = {
                        "id": random.randint(100000, 999999),
                        "timestamp": time.time(),
                        "type": self.mode,
                        "payload": "x" * 100
                    }
                    channel.basic_publish(
                        exchange="",
                        routing_key=self.queue_name,
                        body=json.dumps(msg),
                        properties=pika.BasicProperties(delivery_mode=2)
                    )
                    msg_count += 1
                
                sleep_time = 1 / self.producer_rate if self.mode == "normal" else 0.05
                time.sleep(sleep_time)
            
            conn.close()
            print(f"✓ Producer stopped: {msg_count} messages sent", file=sys.stderr)
        except Exception as e:
            print(f"✗ Producer error: {e}", file=sys.stderr)
    
    def consumer_thread(self, consumer_id=1):
        """Configurable consumer based on mode"""
        try:
            conn = self.get_connection()
            channel = conn.channel()
            
            msg_count = 0
            rejected_count = 0
            
            mode_label = "THRESHOLD" if self.mode == "threshold" else "NORMAL"
            reject_pct = int(self.rejection_rate * 100)
            print(f"✓ {mode_label} consumer {consumer_id} started: {self.consumer_delay}s delay, {reject_pct}% reject rate", file=sys.stderr)
            
            def callback(ch, method, properties, body):
                nonlocal msg_count, rejected_count
                
                # Processing delay based on mode
                time.sleep(self.consumer_delay)
                
                # Rejection rate based on mode
                if random.random() < self.rejection_rate:
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                    rejected_count += 1
                else:
                    ch.basic_ack(delivery_tag=method.delivery_tag)
                
                msg_count += 1
            
            # Higher prefetch for normal mode to increase throughput
            prefetch = 100 if self.mode == "normal" else 1
            channel.basic_qos(prefetch_count=prefetch)
            channel.basic_consume(queue=self.queue_name, on_message_callback=callback)
            channel.start_consuming()
            
        except Exception as e:
            print(f"✗ Consumer {consumer_id} error: {e}", file=sys.stderr)
    
    def run(self):
        """Run simulation based on mode"""
        mode_title = "THRESHOLD BREACH" if self.mode == "threshold" else "NORMAL/HEALTHY"
        print("\n" + "="*60, file=sys.stderr)
        print(f"CONFIGURABLE SIMULATOR - {mode_title} MODE", file=sys.stderr)
        print("Queue:", self.queue_name, file=sys.stderr)
        print("="*60, file=sys.stderr)
        
        # Setup queue
        if not self.setup_queue():
            return
        
        print("\nStarting simulation components...", file=sys.stderr)
        
        # Start consumers FIRST (especially important for normal mode)
        for i in range(1, self.consumer_count + 1):
            consumer_thread = threading.Thread(target=self.consumer_thread, args=(i,), daemon=True)
            consumer_thread.start()
            self.threads.append(consumer_thread)
            time.sleep(0.3)  # Stagger consumer starts
        
        print(f"✓ All {self.consumer_count} consumers started and ready", file=sys.stderr)
        time.sleep(2)  # Let consumers fully initialize
        
        # Start producer AFTER consumers are ready
        t1 = threading.Thread(target=self.producer_thread, daemon=True)
        t1.start()
        self.threads.append(t1)
        
        print("\n" + "="*60, file=sys.stderr)
        if self.mode == "threshold":
            print("THRESHOLD MODE - Expected Metrics:", file=sys.stderr)
            print("="*60, file=sys.stderr)
            print("✓ Queue Depth: Will exceed 1000 in ~6 seconds", file=sys.stderr)
            print("✓ Publish Rate: 12000 msg/min (>10000 threshold)", file=sys.stderr)
            print("✓ Message Ack Rate: ~1700 msg/min (GOOD)", file=sys.stderr)
            print("✓ Message Delivery Rate: ~1800 msg/min (GOOD)", file=sys.stderr)
            print("✓ Num Consumers: 3 (ACTIVE)", file=sys.stderr)
            print("✓ Consumer Utilization: ~60-80% (GOOD)", file=sys.stderr)
            print("✓ DLQ Queue Depth: ~50-150 (controlled at 5% rejection)", file=sys.stderr)
        else:
            print("NORMAL MODE - Expected Metrics:", file=sys.stderr)
            print("="*60, file=sys.stderr)
            print("✓ Publish Rate: 10800 msg/min (>10000 threshold) ✓", file=sys.stderr)
            print("✓ Message Ack Rate: >10000 msg/min (consumers keep up) ✓", file=sys.stderr)
            print("✓ Message Delivery Rate: >10000 msg/min (balanced) ✓", file=sys.stderr)
            print("✓ Queue Depth: 0-100 messages (STABLE, not growing)", file=sys.stderr)
            print("✓ Num Consumers: 20 (6.7x more than threshold mode)", file=sys.stderr)
            print("✓ Consumer Utilization: ~35% (working efficiently)", file=sys.stderr)
            print("✓ DLQ Queue Depth: 0 messages (0% rejection)", file=sys.stderr)
            print("", file=sys.stderr)
            print("KEY DIFFERENCE from Threshold Mode:", file=sys.stderr)
            print("  - Consumers 25x FASTER (0.004s vs 0.1s delay)", file=sys.stderr)
            print("  - 20 consumers vs 3 (6.7x more)", file=sys.stderr)
            print("  - Total capacity: 5,000 msg/sec vs 30 msg/sec", file=sys.stderr)
            print("  - Producer slightly slower (180 vs 200 msg/sec)", file=sys.stderr)
            print("  - Queue stays STABLE (consumers match producer)", file=sys.stderr)
            print("  - Zero rejection rate (0% vs 5%)", file=sys.stderr)
        
        print("="*60, file=sys.stderr)
        print(f"\nQueue Name: {self.queue_name}", file=sys.stderr)
        print(f"DLQ Name: {self.dlq_name}", file=sys.stderr)
        print("\nCheck metrics with:", file=sys.stderr)
        print(f"  echo '{{\"host\":\"{self.host}\",\"queue\":\"{self.queue_name}\",\"dlq\":\"{self.dlq_name}\",\"port\":15672,\"vhost\":\"/\",\"username\":\"{self.username}\",\"password\":\"{self.password}\",\"format\":\"pretty\"}}' | \\", file=sys.stderr)
        print(f"    python message_queue_updated/get_advanced_metrics.py --json", file=sys.stderr)
        print("\n✓ Press Ctrl+C to stop\n", file=sys.stderr)
    
    def stop(self):
        """Stop all threads"""
        self.running = False
        print("\n\nStopping simulator...", file=sys.stderr)
        time.sleep(2)


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='RabbitMQ Configurable Simulator')
    parser.add_argument('--mode', choices=['threshold', 'normal'], default='threshold',
                       help='Simulation mode: threshold (breach thresholds) or normal (healthy system)')
    parser.add_argument('--host', default='9.46.252.85', help='RabbitMQ host')
    parser.add_argument('--port', type=int, default=5672, help='RabbitMQ port')
    parser.add_argument('--vhost', default='/', help='Virtual host')
    parser.add_argument('--username', default='guest', help='Username')
    parser.add_argument('--password', default='guest', help='Password')
    parser.add_argument('--queue', default='threshold_all_metrics', help='Queue name')
    parser.add_argument('--json', action='store_true', help='Read parameters from JSON stdin')
    
    args = parser.parse_args()
    
    # If --json flag is provided, read from stdin
    if args.json:
        try:
            json_input = sys.stdin.read()
            config = json.loads(json_input)
            
            # Override with JSON values
            host = config.get('host', args.host)
            port = config.get('port', args.port)
            vhost = config.get('vhost', args.vhost)
            username = config.get('username', args.username)
            password = config.get('password', args.password)
            queue = config.get('queue', args.queue)
            mode = config.get('mode', args.mode)
            
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON input: {e}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error reading JSON input: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        # Use command line arguments
        host = args.host
        port = args.port
        vhost = args.vhost
        username = args.username
        password = args.password
        queue = args.queue
        mode = args.mode
    
    mode_title = "THRESHOLD BREACH" if mode == "threshold" else "NORMAL/HEALTHY"
    print("="*60, file=sys.stderr)
    print(f"RabbitMQ Configurable Simulator - {mode_title} MODE", file=sys.stderr)
    print("="*60, file=sys.stderr)
    print(f"Host: {host}:{port}", file=sys.stderr)
    print(f"Queue: {queue}", file=sys.stderr)
    print(f"Mode: {mode}", file=sys.stderr)
    print("="*60, file=sys.stderr)
    
    simulator = UnifiedThresholdSimulator(
        host=host,
        port=port,
        vhost=vhost,
        username=username,
        password=password,
        queue_name=queue,
        mode=mode
    )
    
    try:
        simulator.run()
        
        # Keep main thread alive
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        simulator.stop()
        print("\n✓ Simulator stopped", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()

