import schedule
import time
import subprocess
import os
from datetime import datetime

def job():
    print(f"\n[Scheduler] Running ETL Job at {datetime.now()}")
    # etl_job.py 실행
    subprocess.run(["python", "scripts/etl_job.py"])

# 10분마다 실행
schedule.every(10).minutes.do(job)

print("🚀 Seoul Bike Worker Started...")
print("Waiting for the next schedule...")

# 최초 실행 (기다리지 않고 바로 한 번 실행)
job()

while True:
    schedule.run_pending()
    time.sleep(1)