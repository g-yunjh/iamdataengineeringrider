version: '3.8'

x-airflow-common: &airflow-common
  image: apache/airflow:2.9.1
  environment:
    - AIRFLOW__CORE__EXECUTOR=LocalExecutor
    - AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres:5432/airflow_db
    - AIRFLOW__CORE__LOAD_EXAMPLES=false
  volumes:
    - ./dags:/opt/airflow/dags
    - ./scripts:/opt/airflow/scripts
    - ./data:/opt/airflow/data
  depends_on:
    postgres:
      condition: service_healthy

services:
  # 1. Database (DW & Airflow Meta)
  postgres:
    image: postgres:13
    container_name: bike_postgres
    environment:
      - POSTGRES_USER=airflow
      - POSTGRES_PASSWORD=airflow
      - POSTGRES_DB=airflow_db
    ports:
      - "5432:5432"
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "airflow"]
      interval: 5s
      retries: 5

  # 2. Object Storage (MinIO - Data Lake)
  minio:
    image: minio/minio:latest
    container_name: bike_minio
    ports:
      - "9000:9000" # API Port
      - "9001:9001" # Console Port
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: password123
    volumes:
      - ./minio_data:/data
    command: server /data --console-address ":9001"

  # 3. Message Broker (Kafka)
  zookeeper:
    image: bitnami/zookeeper:latest
    container_name: bike_zookeeper
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
    ports:
      - "2181:2181"

  kafka:
    image: bitnami/kafka:latest
    container_name: bike_kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
      - ALLOW_PLAINTEXT_LISTENER=yes

  # 4. Airflow
  airflow-webserver:
    <<: *airflow-common
    command: webserver
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:8080/health"]
      interval: 10s
      retries: 5

  airflow-scheduler:
    <<: *airflow-common
    command: scheduler

  airflow-init:
    <<: *airflow-common
    command: version
    environment:
      - AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres:5432/airflow_db
    command: >
      bash -c "airflow db init &&
      airflow users create --username admin --password admin --firstname Data --lastname Engineer --role Admin --email admin@example.com"

  # 5. Spark (Master & Worker)
  spark-master:
    image: bitnami/spark:3.5
    container_name: bike_spark_master
    environment:
      - SPARK_MODE=master
    ports:
      - "8081:8080"
      - "7077:7077"

  spark-worker:
    image: bitnami/spark:3.5
    container_name: bike_spark_worker
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
    depends_on:
      - spark-master

  # 6. Visualization (Streamlit)
  streamlit:
    build: ./streamlit
    container_name: bike_dashboard
    ports:
      - "8501:8501"
    volumes:
      - ./streamlit:/app
    depends_on:
      - postgres