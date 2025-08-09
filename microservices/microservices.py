import time
import random
import json
from datetime import datetime
from kafka import KafkaProducer

# Configuration
KAFKA_SERVER = 'localhost:9092'
TOPIC = 'microservices-logs'
SERVICES = ['m1', 'm2', 'm3', 'm4']

def generate_log(service_name):
    return {
        "timestamp": datetime.now().strftime("%H:%M:%S.%f")[:-3],  # Include milliseconds
        "service": service_name,
        "message": f"Action {random.randint(1, 100)} executed",
        "sequence": random.randint(1, 1000)  # Simulate random processing order
    }

def run_service(service_name):
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_SERVER,
        value_serializer=lambda x: json.dumps(x).encode('utf-8')
    )
    
    print(f"Service {service_name} started producing logs...")
    
    while True:
        log = generate_log(service_name)
        producer.send(TOPIC, value=log)
        print(f"{service_name} -> {log['timestamp']} | Seq: {log['sequence']} | {log['message']}")
        time.sleep(random.uniform(0.1, 2))  # More aggressive random delays

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python microservice.py <service_name>")
        sys.exit(1)
    run_service(sys.argv[1])
