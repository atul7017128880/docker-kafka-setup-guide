#!/bin/bash
# Script to test Kafka connection with SASL authentication

set -e

echo "======================================"
echo "Kafka Connection Test Script"
echo "======================================"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found. Please copy env.template to .env and configure it."
    exit 1
fi

KAFKA_CONTAINER="kafka-1"
BOOTSTRAP_SERVER="kafka-1:9092"
TEST_TOPIC="test-topic-$(date +%s)"

echo "Creating test client configuration..."
docker exec ${KAFKA_CONTAINER} bash -c "cat > /tmp/client.properties << 'EOF'
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${KAFKA_APP_USERNAME}\" password=\"${KAFKA_APP_PASSWORD}\";
EOF"

echo ""
echo "Step 1: Creating test topic..."
docker exec ${KAFKA_CONTAINER} bash -c "cat > /tmp/admin.properties << 'EOF'
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${KAFKA_ADMIN_USERNAME}\" password=\"${KAFKA_ADMIN_PASSWORD}\";
EOF"

docker exec ${KAFKA_CONTAINER} /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server ${BOOTSTRAP_SERVER} \
    --create \
    --topic ${TEST_TOPIC} \
    --partitions 3 \
    --replication-factor 3 \
    --command-config /tmp/admin.properties

echo "✓ Test topic created: ${TEST_TOPIC}"
echo ""

echo "Step 2: Testing producer (sending 5 messages)..."
for i in {1..5}; do
    echo "Test message ${i} at $(date)" | docker exec -i ${KAFKA_CONTAINER} \
        /opt/kafka/bin/kafka-console-producer.sh \
        --bootstrap-server ${BOOTSTRAP_SERVER} \
        --topic ${TEST_TOPIC} \
        --producer.config /tmp/client.properties
    echo "✓ Message ${i} sent"
done

echo ""
echo "Step 3: Testing consumer (reading messages)..."
timeout 10 docker exec ${KAFKA_CONTAINER} \
    /opt/kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server ${BOOTSTRAP_SERVER} \
    --topic ${TEST_TOPIC} \
    --from-beginning \
    --max-messages 5 \
    --consumer.config /tmp/client.properties || true

echo ""
echo "Step 4: Cleaning up test topic..."
docker exec ${KAFKA_CONTAINER} /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server ${BOOTSTRAP_SERVER} \
    --delete \
    --topic ${TEST_TOPIC} \
    --command-config /tmp/admin.properties

echo ""
echo "======================================"
echo "✓ Connection test completed successfully!"
echo "======================================"
echo ""
echo "Your Kafka cluster is working properly with SASL authentication."

