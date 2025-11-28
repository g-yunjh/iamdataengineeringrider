# 1. Base Image: 가벼운 Python 3.9
FROM python:3.9-slim

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 시스템 패키지 설치 (Postgres 연동용)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 4. Python 라이브러리 설치
# duckdb: 데이터 처리
# sqlalchemy, psycopg2: DB 연결
# requests: API 호출
# schedule: 스케줄러
RUN pip install --no-cache-dir \
    requests \
    pandas \
    duckdb \
    sqlalchemy \
    psycopg2-binary \
    schedule \
    python-dotenv

# 5. 소스코드 복사
COPY . /app

# 6. 실행 명령어
CMD ["python", "scripts/run_scheduler.py"]