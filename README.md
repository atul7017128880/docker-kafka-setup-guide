## Docker Kafka Setup Guide

Follow these steps to quickly set up a secure Kafka environment with Docker:

### 1. (Optional) Configure Docker Compose

Edit the `docker-compose.yml` file if you want to adjust ports or other service settings.

---

### 2. Automatically Generate Credentials and Configs

You can automatically generate a secure `.env` file and JAAS config for Kafka authentication by running:

```sh
./setup-passwords.sh
```

- This script creates strong random passwords for your admin, broker, and app users.
- It generates the required `.env` file and updates `config/kafka_server_jaas.conf` to match.
- If a `.env` file already exists, you'll be asked whether you want to replace it.

> **Tip:** Using `setup-passwords.sh` is the easiest and most secure way to set up your configuration. You do **not** need to manually edit passwords unless you have custom requirements.

---

#### If you prefer to configure manually:

##### Edit JAAS Authentication

Update the contents of `config/kafka_server_jaas.conf` with your chosen credentials:

```conf
KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="broker"
    password="YOUR_PASSWORD";
};

KafkaClient {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="broker"
    password="YOUR_PASSWORD";
};

Client {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="broker"
    password="YOUR_PASSWORD";
};
```
> **Note:** Replace `"YOUR_PASSWORD"` with a secure password. This should match the value for `KAFKA_BROKER_PASSWORD` in your `.env` file.

##### Edit Environment Variables

Populate the `.env` file with your cluster and user credentials:

```env
# Kafka Cluster Configuration
KAFKA_CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk

# SASL/SCRAM Authentication
KAFKA_ADMIN_USERNAME=admin
KAFKA_ADMIN_PASSWORD=SecureAdmin123
KAFKA_BROKER_USERNAME=broker
KAFKA_BROKER_PASSWORD=SecureBroker456
KAFKA_APP_USERNAME=app_user
KAFKA_APP_PASSWORD=SecureApp789

# Kafka UI
UI_ADMIN_USERNAME=kafka-ui
UI_ADMIN_PASSWORD=SecureUI123
```
> **Tip:** Use strong, unique passwords. The usernames and passwords here must match those specified in your JAAS config and Docker Compose.

---

### 3. Run the Setup Script

Start the Kafka services and apply your configuration by running:

```sh
./SETUP.sh
```

---

You should now have a running Kafka environment with authentication set up. For most users, `./setup-passwords.sh` provides a simple, secure starting point!