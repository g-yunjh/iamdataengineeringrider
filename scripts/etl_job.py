import os
import requests
import pandas as pd
import duckdb
from sqlalchemy import create_engine
from datetime import datetime

# 서울시 따릉이 API URL (1~1000건 조회)
API_KEY = os.getenv("SEOUL_API_KEY")
START = 1
END = 1000
URL = f"http://openapi.seoul.go.kr:8088/{API_KEY}/json/bikeList/{START}/{END}/"

def run_etl():
    print(f"[{datetime.now()}] ETL Job Started...")

    # 1. API 호출 (Extract)
    try:
        response = requests.get(URL, timeout=10)
        data = response.json()
        
        if 'rentBikeStatus' not in data:
            print("Error: API 응답 형식이 올바르지 않습니다.")
            return

        rows = data['rentBikeStatus']['row']
        df = pd.DataFrame(rows)
        
        # 컬럼 타입 변환 (문자열 -> 숫자)
        df['parkingBikeTotCnt'] = pd.to_numeric(df['parkingBikeTotCnt'])
        df['stationLatitude'] = pd.to_numeric(df['stationLatitude'])
        df['stationLongitude'] = pd.to_numeric(df['stationLongitude'])
        
    except Exception as e:
        print(f"API Error: {e}")
        return

    # 2. DuckDB로 데이터 변환 (Transform)
    # Spark 대신 DuckDB SQL을 사용해 메모리 효율적으로 처리
    con = duckdb.connect(database=':memory:')
    con.register('bike_df', df)

    # 쿼리: 자전거가 3대 미만인 '부족' 대여소만 필터링
    query = """
    SELECT 
        stationId as station_id,
        stationName as station_name,
        stationLatitude::FLOAT as lat,
        stationLongitude::FLOAT as lon,
        parkingBikeTotCnt::INT as bike_count,
        CURRENT_TIMESTAMP as updated_at
    FROM bike_df
    WHERE parkingBikeTotCnt < 3
    """
    transformed_df = con.execute(query).df()
    
    print(f"DuckDB Processed: {len(transformed_df)} stations found (Low Battery).")

    # 3. Supabase(Postgres)에 적재 (Load)
    # 기존 데이터를 덮어쓰거나(replace) 추가(append)
    db_url = os.getenv("SUPABASE_DB_URL")
    if not db_url:
        print("Error: SUPABASE_DB_URL is missing.")
        return

    try:
        engine = create_engine(db_url)
        # 'bike_status' 테이블에 저장 (매번 최신 상태로 갱신하기 위해 replace 사용)
        transformed_df.to_sql('bike_status', engine, if_exists='replace', index=False)
        print("Successfully uploaded to Supabase!")
    except Exception as e:
        print(f"DB Error: {e}")

if __name__ == "__main__":
    run_etl()