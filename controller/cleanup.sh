#!/bin/bash
# Stops microservices, Kafka, and Zookeeper, and deletes topic

KAFKA_VERSION="3.8.0"
SCALA_VERSION="2.13"
KAFKA_DIR="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
TOPIC_NAME="microservices-logs"

echo "Stopping microservices..."
pkill -f "python.*microservices.py"

if [ -d "$KAFKA_DIR" ]; then
    cd "$KAFKA_DIR" || exit 1

    # Wait until Kafka responds or timeout after 10s
    for i in {1..5}; do
        if bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done

    echo "Deleting Kafka topic: $TOPIC_NAME"
    bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic "$TOPIC_NAME"

    echo "Stopping Kafka..."
    pkill -f "kafka.Kafka"

    echo "Stopping Zookeeper..."
    pkill -f "zookeeper"

    cd ..
else
    echo "[WARN] Kafka directory not found, skipping Kafka cleanup."
fi

echo "Cleanup completed."

