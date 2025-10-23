#!/bin/bash
# Script to create a Kafka topic with proper configuration

set -e

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <topic-name> [partitions] [replication-factor]"
    echo "Example: $0 my-topic 6 3"
    exit 1
fi

TOPIC_NAME=$1
PARTITIONS=${2:-6}
REPLICATION_FACTOR=${3:-3}

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found. Please copy env.template to .env and configure it."
    exit 1
fi

KAFKA_CONTAINER="kafka-1"
BOOTSTRAP_SERVER="kafka-1:9092"

echo "======================================"
echo "Creating Kafka Topic"
echo "======================================"
echo "Topic Name: ${TOPIC_NAME}"
echo "Partitions: ${PARTITIONS}"
echo "Replication Factor: ${REPLICATION_FACTOR}"
echo "======================================"

# Create admin client properties if not exists
docker exec ${KAFKA_CONTAINER} bash -c "cat > /tmp/admin.properties << 'EOF'
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${KAFKA_ADMIN_USERNAME}\" password=\"${KAFKA_ADMIN_PASSWORD}\";
EOF"

# Create topic
docker exec ${KAFKA_CONTAINER} /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server ${BOOTSTRAP_SERVER} \
    --create \
    --topic ${TOPIC_NAME} \
    --partitions ${PARTITIONS} \
    --replication-factor ${REPLICATION_FACTOR} \
    --config min.insync.replicas=2 \
    --config compression.type=snappy \
    --config retention.ms=604800000 \
    --command-config /tmp/admin.properties

echo ""
echo "Topic '${TOPIC_NAME}' created successfully!"
echo ""

# Describe the topic
docker exec ${KAFKA_CONTAINER} /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server ${BOOTSTRAP_SERVER} \
    --describe \
    --topic ${TOPIC_NAME} \
    --command-config /tmp/admin.properties

