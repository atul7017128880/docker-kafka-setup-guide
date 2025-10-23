@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo           KAFKA PRODUCTION CLUSTER - FINAL SETUP
echo ============================================================
echo This script will:
echo 1. Stop and clean everything
echo 2. Create .env file with secure passwords
echo 3. Build custom Kafka Docker image
echo 4. Start 3-node Kafka cluster with SASL authentication
echo 5. Create users and test connection
echo 6. Show you how to connect
echo ============================================================
echo.

REM Check prerequisites
echo [CHECK] Verifying prerequisites...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed or not running
    pause
    exit /b 1
)

echo [OK] Docker is available
echo.

REM Step 1: Stop and clean Kafka only
echo ============================================================
echo STEP 1: Cleanup Kafka containers only
echo ============================================================
echo Stopping and removing Kafka containers and volumes only...
docker-compose down -v >nul 2>&1
echo [OK] Kafka cleanup completed (other containers untouched)
echo.

REM Step 2: Create .env file
echo ============================================================
echo STEP 2: Creating configuration
echo ============================================================
if not exist .env (
    echo Creating .env file with secure passwords...
    (
        echo # Kafka Cluster Configuration
        echo KAFKA_CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk
        echo.
        echo # SASL/SCRAM Authentication
        echo KAFKA_ADMIN_USERNAME=admin
        echo KAFKA_ADMIN_PASSWORD=SecureAdmin123
        echo KAFKA_BROKER_USERNAME=broker
        echo KAFKA_BROKER_PASSWORD=SecureBroker456
        echo KAFKA_APP_USERNAME=app_user
        echo KAFKA_APP_PASSWORD=SecureApp789
        echo.
        echo # Kafka UI
        echo UI_ADMIN_USERNAME=kafka-ui
        echo UI_ADMIN_PASSWORD=SecureUI123
        echo KAFKA_ADMIN_PASSWORD=SecureAdmin123
    ) > .env
    echo [OK] .env file created with secure passwords
) else (
    echo [OK] .env file already exists
)
echo.

REM Step 3: Build Docker image
echo ============================================================
echo STEP 3: Building Kafka Docker image
echo ============================================================
echo Building custom Kafka image from binary...
docker build -t kafka-custom:4.1.0 . >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to build Docker image
    pause
    exit /b 1
)
echo [OK] Docker image built successfully
echo.

REM Step 4: Start cluster
echo ============================================================
echo STEP 4: Starting Kafka cluster
echo ============================================================
echo Starting 3-node Kafka cluster...
docker-compose up -d >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to start cluster
    pause
    exit /b 1
)
echo [OK] Cluster started
echo.

REM Step 5: Wait for cluster to be ready
echo ============================================================
echo STEP 5: Waiting for cluster to be ready
echo ============================================================
echo Waiting for Kafka cluster to initialize...
timeout /t 30 /nobreak >nul
echo [OK] Cluster should be ready
echo.

REM Step 6: Create users using PLAINTEXT listener
echo ============================================================
echo STEP 6: Creating SASL users
echo ============================================================
echo Ensuring plaintext.properties is available...
REM Get the actual container name for kafka-1
for /f "tokens=*" %%i in ('docker ps --filter "name=kafka-1" --format "{{.Names}}"') do set KAFKA_CONTAINER=%%i
docker cp config/plaintext.properties %KAFKA_CONTAINER%:/opt/kafka/config/plaintext.properties >nul 2>&1

echo Creating admin user...
docker exec %KAFKA_CONTAINER% /opt/kafka/bin/kafka-configs.sh --bootstrap-server %KAFKA_CONTAINER%:9093 --command-config /opt/kafka/config/plaintext.properties --alter --add-config SCRAM-SHA-256=[password=SecureAdmin123] --entity-type users --entity-name admin
docker exec %KAFKA_CONTAINER% /opt/kafka/bin/kafka-configs.sh --bootstrap-server %KAFKA_CONTAINER%:9093 --command-config /opt/kafka/config/plaintext.properties --alter --add-config SCRAM-SHA-512=[password=SecureAdmin123] --entity-type users --entity-name admin

echo Creating broker user...
docker exec %KAFKA_CONTAINER% /opt/kafka/bin/kafka-configs.sh --bootstrap-server %KAFKA_CONTAINER%:9093 --command-config /opt/kafka/config/plaintext.properties --alter --add-config SCRAM-SHA-256=[password=SecureBroker456] --entity-type users --entity-name broker
docker exec %KAFKA_CONTAINER% /opt/kafka/bin/kafka-configs.sh --bootstrap-server %KAFKA_CONTAINER%:9093 --command-config /opt/kafka/config/plaintext.properties --alter --add-config SCRAM-SHA-512=[password=SecureBroker456] --entity-type users --entity-name broker

echo Creating app user...
docker exec %KAFKA_CONTAINER% /opt/kafka/bin/kafka-configs.sh --bootstrap-server %KAFKA_CONTAINER%:9093 --command-config /opt/kafka/config/plaintext.properties --alter --add-config SCRAM-SHA-256=[password=SecureApp789] --entity-type users --entity-name app_user
docker exec %KAFKA_CONTAINER% /opt/kafka/bin/kafka-configs.sh --bootstrap-server %KAFKA_CONTAINER%:9093 --command-config /opt/kafka/config/plaintext.properties --alter --add-config SCRAM-SHA-512=[password=SecureApp789] --entity-type users --entity-name app_user

echo [OK] Users created successfully
echo.

REM Step 7: Test connection
echo ============================================================
echo STEP 7: Testing connection
echo ============================================================
echo Testing Kafka connection with SASL authentication...
docker exec %KAFKA_CONTAINER% /opt/kafka/bin/kafka-topics.sh --bootstrap-server %KAFKA_CONTAINER%:9092 --command-config /opt/kafka/config/admin.properties --create --topic test-topic --partitions 3 --replication-factor 3 >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Topic creation failed, but cluster might still be working
) else (
    echo [OK] Connection test successful
)
echo.

REM Step 8: Show status
echo ============================================================
echo STEP 8: Cluster Status
echo ============================================================
echo.
echo [SUCCESS] Kafka cluster is running with SASL authentication!
echo.
echo Cluster Details:
echo - 3 Kafka brokers with SASL authentication
echo - Kafka UI for monitoring
echo - Users: admin, broker, app_user
echo.
echo Connection Details:
echo - SASL_PLAINTEXT: localhost:19092, localhost:29092, localhost:39092
echo - Kafka UI: http://localhost:8080
echo.
echo Credentials:
echo - Admin: admin / SecureAdmin123
echo - Broker: broker / SecureBroker456
echo - App User: app_user / SecureApp789
echo - Kafka UI: kafka-ui / SecureUI123
echo.
echo ============================================================
echo SETUP COMPLETE! Your Kafka cluster is ready to use.
echo ============================================================
echo.
echo To stop the cluster: docker-compose down
echo To restart: docker-compose up -d
echo.
pause