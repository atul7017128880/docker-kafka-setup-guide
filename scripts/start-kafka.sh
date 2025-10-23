#!/bin/bash
set -e

echo "======================================"
echo "Starting Kafka Bootstrap Process"
echo "======================================"
echo "Node ID: ${KAFKA_NODE_ID}"
echo "Cluster ID: ${KAFKA_CLUSTER_ID}"
echo "Process Roles: ${KAFKA_PROCESS_ROLES}"
echo "======================================"

KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}
CONFIG_DIR="${KAFKA_HOME}/config/custom"
DATA_DIR="${KAFKA_HOME}/data/kraft-combined-logs"
METADATA_DIR="${DATA_DIR}"

# Fix permissions for data directory (required for Docker volumes)
echo "Setting up data directory permissions..."
mkdir -p "${DATA_DIR}"
chown -R kafka:kafka "${KAFKA_HOME}/data"
chmod -R 755 "${KAFKA_HOME}/data"

# Export KAFKA_OPTS for JAAS configuration
export KAFKA_OPTS="-Djava.security.auth.login.config=${KAFKA_HOME}/config/kafka_server_jaas.conf"

# Generate server.properties from template with environment variable substitution
echo "Generating server.properties from environment variables..."
cat > "${CONFIG_DIR}/server.properties" << EOF
# Server Basics
process.roles=${KAFKA_PROCESS_ROLES}
node.id=${KAFKA_NODE_ID}
controller.quorum.voters=${KAFKA_CONTROLLER_QUORUM_VOTERS}

# Listeners
listeners=${KAFKA_LISTENERS}
advertised.listeners=${KAFKA_ADVERTISED_LISTENERS}
listener.security.protocol.map=${KAFKA_LISTENER_SECURITY_PROTOCOL_MAP}
inter.broker.listener.name=${KAFKA_INTER_BROKER_LISTENER_NAME}
controller.listener.names=${KAFKA_CONTROLLER_LISTENER_NAMES}

# Socket Settings
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

# SASL Configuration
sasl.mechanism.inter.broker.protocol=${KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL}
sasl.enabled.mechanisms=${KAFKA_SASL_ENABLED_MECHANISMS}

listener.name.sasl_plaintext.scram-sha-512.sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required;
listener.name.sasl_plaintext.scram-sha-256.sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required;

# Authorization disabled - SASL authentication still required
# To enable authorization, uncomment these lines:
# super.users=${KAFKA_SUPER_USERS}
# authorizer.class.name=org.apache.kafka.metadata.authorizer.StandardAuthorizer
# allow.everyone.if.no.acl.found=true

# Log Configuration
log.dirs=${KAFKA_LOG_DIRS}
num.partitions=${KAFKA_NUM_PARTITIONS}
default.replication.factor=${KAFKA_DEFAULT_REPLICATION_FACTOR}
min.insync.replicas=${KAFKA_MIN_INSYNC_REPLICAS}
auto.create.topics.enable=${KAFKA_AUTO_CREATE_TOPICS_ENABLE}

# Internal Topics
offsets.topic.replication.factor=${KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR}
transaction.state.log.replication.factor=${KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR}
transaction.state.log.min.isr=${KAFKA_TRANSACTION_STATE_LOG_MIN_ISR}

# Log Flush Policy
log.flush.interval.messages=10000
log.flush.interval.ms=1000

# Log Retention
log.retention.hours=${KAFKA_LOG_RETENTION_HOURS}
log.retention.bytes=1073741824
log.segment.bytes=${KAFKA_LOG_SEGMENT_BYTES}
log.retention.check.interval.ms=${KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS}

# Group Coordinator
group.initial.rebalance.delay.ms=${KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS}

# Performance
num.network.threads=8
num.io.threads=8
num.replica.fetchers=4
replica.fetch.min.bytes=1
replica.fetch.wait.max.ms=500
compression.type=snappy

# Metadata
metadata.log.dir=${KAFKA_LOG_DIRS}
EOF

echo "Configuration file generated successfully."

# Check if metadata directory exists and is initialized
if [ ! -d "${METADATA_DIR}/meta.properties" ] && [ ! -f "${METADATA_DIR}/meta.properties" ]; then
    echo "Formatting storage directory for KRaft..."
    gosu kafka "${KAFKA_HOME}/bin/kafka-storage.sh" format \
        -t "${KAFKA_CLUSTER_ID}" \
        -c "${CONFIG_DIR}/server.properties"
    echo "Storage directory formatted successfully."
else
    echo "Storage directory already formatted. Skipping format step."
fi

# Wait for other brokers to be available (simple coordination)
if [ "${KAFKA_NODE_ID}" != "1" ]; then
    echo "Waiting for primary broker to be ready..."
    sleep 20
fi

echo "Starting Kafka server..."
# Switch to kafka user and start server
exec gosu kafka "${KAFKA_HOME}/bin/kafka-server-start.sh" "${CONFIG_DIR}/server.properties"

