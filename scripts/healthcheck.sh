#!/bin/bash
# Health check script for Kafka broker

KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}

# Check if Kafka process is running
if ! pgrep -f "kafka.Kafka" > /dev/null; then
    echo "Kafka process not running"
    exit 1
fi

# Check if broker is responding (using metadata request)
# We use a simple approach - checking if the process is listening on the broker port
if ! nc -z localhost 9092 2>/dev/null; then
    echo "Kafka broker port 9092 not accessible"
    exit 1
fi

echo "Kafka broker is healthy"
exit 0

