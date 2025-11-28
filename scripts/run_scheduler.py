import schedule
import time
import subprocess
import os

def job_collect_realtime():
    print("[Job] 수집 시작: 실시간 따릉이 데이터")
    # 별도 스크립트를 실행하거나 로직을 여기에 작성
    subprocess.run(["python", "scripts/collect_realtime.py"])

def job_daily_stats():
    print("[Job] 집계 시작: 일일 통계 (DuckDB)")
    subprocess.run(["python", "scripts/process_daily.py"])

# 스케줄 등록 (10분마다 실행)
schedule.every(10).minutes.do(job_collect_realtime)

# 매일 밤 12시에 통계 집계
schedule.every().day.at("00:00").do(job_daily_stats)

print("🚀 경량화 스케줄러가 시작되었습니다...")

while True:
    schedule.run_pending()
    time.sleep(1)