# 가벼운 Python 이미지
FROM python:3.9-slim

WORKDIR /app

# 필수 시스템 패키지 (컴파일러, DB 드라이버 등)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 파이썬 라이브러리 설치
# duckdb: 초경량 분석용 DB
# confluent-kafka: Kafka 연동
# psycopg2-binary: Postgres(Supabase) 연동
# schedule: 스케줄러
RUN pip install --no-cache-dir \
    requests \
    pandas \
    duckdb \
    confluent-kafka \
    psycopg2-binary \
    sqlalchemy \
    schedule \
    python-dotenv

# 전체 코드 복사
COPY . /app

# 컨테이너 실행 시 스케줄러 가동
CMD ["python", "scripts/run_scheduler.py"]