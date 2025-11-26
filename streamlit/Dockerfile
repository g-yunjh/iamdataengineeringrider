FROM python:3.9-slim

WORKDIR /app

# 필수 라이브러리 설치 (지도 시각화용 pydeck, DB연동용 psycopg2)
RUN pip install streamlit pandas pydeck psycopg2-binary sqlalchemy

CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0"]