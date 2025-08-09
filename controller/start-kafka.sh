#!/bin/bash
# This Script installs and starts the Zookeeper and Kafka then creates a topic
# and host taken from config.yaml

# Install openjdk and Kafka
KAFKA_VERSION="3.8.0"
SCALA_VERSION="2.13"
KAFKA_DIR="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
KAFKA_TGZ="${KAFKA_DIR}.tgz"
KAFKA_URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_TGZ}"

# Topic name
TOPIC_NAME="microservices-logs"

# Check Java
if ! java -version &>/dev/null; then
    echo "Java not found. Installing OpenJDK 17..."
    sudo apt update
    sudo apt install openjdk-17-jdk -y
else 
    echo "Java already installed"
fi

# Check Kafka in current directory
if [ ! -d "./${KAFKA_DIR}" ]; then
    echo "[INFO] Kafka not found in current directory. Downloading..."
    wget "$KAFKA_URL"
    echo "[INFO] Extracting Kafka..."
    tar -xvzf "$KAFKA_TGZ"
else
    echo "[INFO] Kafka already present in current directory."
fi

# Move into Kafka directory
cd "./${KAFKA_DIR}" || exit 1

# Wait for 5 seconds
echo "Starting kafka in 5 seconds..."
sleep 5

# Launch echo
echo "Lauching kafka..."

# Start Zookeeper (it's not necessary to know what zookeeper is)
# if pgrep -f "zookeeper" >/dev/null; then
#    echo "Zookeeper already running."
# else
#    nohup bin/zookeeper-server-start.sh config/zookeeper.properties > zookeeper.log 2>&1 &
#    sleep 5
#    echo "Zookeeper started."
# fi
# Start Zookeeper
nohup bin/zookeeper-server-start.sh config/zookeeper.properties > zookeeper.log 2>&1 &

# Wait until Zookeeper is ready
echo "Waiting for Zookeeper to start..."
while ! nc -z localhost 2181; do
    sleep 1
done
echo "Zookeeper started."


# Start Kafka (it is the main kafka app)
if pgrep -f "kafka.Kafka" >/dev/null; then
    echo "Kafka already running."
else
    nohup bin/kafka-server-start.sh config/server.properties > kafka.log 2>&1 &
    sleep 5
    echo "Kafka started."
fi

# Wait for Kafka to be ready (max 20s)
MAX_WAIT=10
for i in $(seq 1 $MAX_WAIT); do
    if bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
        echo "Kafka is ready."
        break
    fi
    sleep 2
done

if ! bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
    echo "[WARN] Kafka did not become ready after $((MAX_WAIT * 2)) seconds."
fi


# Create topic if missing
bin/kafka-topics.sh --bootstrap-server localhost:9092 \
    --create --if-not-exists --topic "$TOPIC_NAME" \
    --partitions 1 --replication-factor 1
