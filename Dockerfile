FROM eclipse-temurin:21-jre-jammy

# Set Kafka version
ENV KAFKA_VERSION=4.1.0 \
    SCALA_VERSION=2.13 \
    KAFKA_HOME=/opt/kafka \
    PATH=$PATH:/opt/kafka/bin

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    netcat \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Download and extract Kafka
RUN wget -q https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O /tmp/kafka.tgz && \
    mkdir -p ${KAFKA_HOME} && \
    tar -xzf /tmp/kafka.tgz -C ${KAFKA_HOME} --strip-components=1 && \
    rm /tmp/kafka.tgz

# Create necessary directories
RUN mkdir -p ${KAFKA_HOME}/data/kafka-logs && \
    mkdir -p ${KAFKA_HOME}/data/kraft-combined-logs && \
    mkdir -p ${KAFKA_HOME}/config/custom && \
    mkdir -p ${KAFKA_HOME}/secrets

# Create kafka user and set permissions
RUN groupadd -r kafka && \
    useradd -r -g kafka kafka && \
    chown -R kafka:kafka ${KAFKA_HOME}

# Copy configuration files
COPY config/ ${KAFKA_HOME}/config/custom/
COPY scripts/ ${KAFKA_HOME}/scripts/

# Copy plaintext.properties to main config directory
COPY config/plaintext.properties ${KAFKA_HOME}/config/

# Make scripts executable
RUN chmod +x ${KAFKA_HOME}/scripts/*.sh && \
    chown -R kafka:kafka ${KAFKA_HOME}

WORKDIR ${KAFKA_HOME}

# Note: We'll switch to kafka user in the startup script after fixing permissions

# Expose ports
# 9092: SASL_PLAINTEXT internal
# 9093: SASL_SSL external
# 9094: Controller (KRaft)
EXPOSE 9092 9093 9094

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD ${KAFKA_HOME}/scripts/healthcheck.sh || exit 1

# Default command
CMD ["/opt/kafka/scripts/start-kafka.sh"]

