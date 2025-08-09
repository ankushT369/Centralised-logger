import json
import os
from datetime import datetime, timedelta
from kafka import KafkaConsumer

KAFKA_SERVER = 'localhost:9092'
TOPIC = 'microservices-logs'
LATE_LOG_THRESHOLD = timedelta(seconds=5)  # Consider logs older than 5s as late

class LogProcessor:
    def __init__(self):
        self.consumer = KafkaConsumer(
            TOPIC,
            bootstrap_servers=KAFKA_SERVER,
            value_deserializer=lambda x: json.loads(x.decode('utf-8')),
            auto_offset_reset='earliest'
        )
        self.current_bucket = None
        self.bucket_logs = []
        
    def get_bucket_name(self, timestamp):
        dt = datetime.strptime(timestamp, "%H:%M:%S.%f")
        return f"logs_{dt.hour}_{dt.minute}.json"
    
    def process_log(self, log):
        bucket_name = self.get_bucket_name(log['timestamp'])
        
        # Rotate bucket if needed
        if bucket_name != self.current_bucket:
            self.flush_bucket()
            self.current_bucket = bucket_name
            self.bucket_logs = []
            print(f"\n=== NEW BUCKET: {bucket_name} ===")
        
        self.bucket_logs.append(log)
        print(f"Processed: {log['timestamp']} | {log['service']} | Seq: {log['sequence']}")
        
    def flush_bucket(self):
        if not self.current_bucket or not self.bucket_logs:
            return
            
        # Sort logs by timestamp
        self.bucket_logs.sort(key=lambda x: x['timestamp'])
        
        # Save to file
        with open(self.current_bucket, 'w') as f:
            json.dump(self.bucket_logs, f, indent=2)
        
        print(f"\n=== FLUSHED BUCKET {self.current_bucket} ===")
        for log in self.bucket_logs:
            print(f"  {log['timestamp']} | {log['service']} | Seq: {log['sequence']}")
        
    def handle_late_log(self, log):
        print(f"\n!!! LATE LOG: {log['timestamp']} | Current time: {datetime.now().strftime('%H:%M:%S.%f')[:-3]}")
        with open("late_logs.json", 'a') as f:
            f.write(json.dumps(log) + "\n")
    
    def run(self):
        print("Log processor started. Waiting for logs...")
        try:
            for message in self.consumer:
                log = message.value
                log_time = datetime.strptime(log['timestamp'], "%H:%M:%S.%f")
                current_time = datetime.now()
                
                if current_time - log_time > LATE_LOG_THRESHOLD:
                    self.handle_late_log(log)
                else:
                    self.process_log(log)
                    
        except KeyboardInterrupt:
            print("\nShutting down...")
            self.flush_bucket()
            
if __name__ == "__main__":
    processor = LogProcessor()
    processor.run()
