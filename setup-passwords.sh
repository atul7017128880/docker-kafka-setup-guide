#!/bin/bash

ENV_FILE=".env"
JAAS_FILE="config/kafka_server_jaas.conf"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
  read -p ".env file already exists. Do you want to replace it? (y/n): " choice
  case "$choice" in
    y|Y ) echo "Replacing .env file...";;
    * ) echo "Aborting. .env file not changed."; exit 0;;
  esac
fi

# Function to generate a Kafka Cluster ID like MkU3OEVBNTcwNTJENDM2Qk (22 chars Base64)
generate_cluster_id() {
  head -c 16 /dev/urandom | base64 | tr -d "=+/" | head -c 22
}

# Function to generate a secure random password (16 chars: letters + numbers)
generate_password() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

# Generate Cluster ID and passwords
KAFKA_CLUSTER_ID=$(generate_cluster_id)
KAFKA_ADMIN_PASSWORD=$(generate_password)
KAFKA_BROKER_PASSWORD=$(generate_password)
KAFKA_APP_PASSWORD=$(generate_password)
UI_ADMIN_PASSWORD=$(generate_password)

# Create .env file
cat <<EOF > "$ENV_FILE"
# Kafka Cluster Configuration
KAFKA_CLUSTER_ID=$KAFKA_CLUSTER_ID

# SASL/SCRAM Authentication
KAFKA_ADMIN_USERNAME=admin
KAFKA_ADMIN_PASSWORD=$KAFKA_ADMIN_PASSWORD
KAFKA_BROKER_USERNAME=broker
KAFKA_BROKER_PASSWORD=$KAFKA_BROKER_PASSWORD
KAFKA_APP_USERNAME=app_user
KAFKA_APP_PASSWORD=$KAFKA_APP_PASSWORD

# Kafka UI
UI_ADMIN_USERNAME=kafka-ui
UI_ADMIN_PASSWORD=$UI_ADMIN_PASSWORD
EOF

echo ".env file generated with new passwords and cluster ID!"

# Update kafka_server_jaas.conf
if [ ! -d "$(dirname "$JAAS_FILE")" ]; then
  mkdir -p "$(dirname "$JAAS_FILE")"
fi

cat <<EOF > "$JAAS_FILE"
KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="broker"
    password="$KAFKA_BROKER_PASSWORD";
};

KafkaClient {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="broker"
    password="$KAFKA_BROKER_PASSWORD";
};

Client {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="broker"
    password="$KAFKA_BROKER_PASSWORD";
};
EOF

echo "config/kafka_server_jaas.conf updated with new broker password!"
