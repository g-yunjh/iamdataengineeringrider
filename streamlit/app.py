import streamlit as st
import pandas as pd
import pydeck as pdk
from sqlalchemy import create_engine
import os

# 페이지 설정
st.set_page_config(page_title="따릉이 실시간 관제", layout="wide")

# 제목
st.title("🚲 서울시 따릉이 부족 대여소 현황")
st.markdown("OCI Cloud Worker가 수집하고 Supabase에 적재한 데이터를 실시간으로 보여줍니다.")

# DB 연결 (Streamlit Cloud의 Secrets 기능 사용 예정)
# 로컬 테스트 시에는 os.getenv로 .env를 읽거나 직접 입력
DB_URL = st.secrets.get("SUPABASE_DB_URL") or os.getenv("SUPABASE_DB_URL")

@st.cache_data(ttl=60)  # 60초마다 캐시 갱신
def load_data():
    if not DB_URL:
        return pd.DataFrame()
    try:
        engine = create_engine(DB_URL)
        query = "SELECT * FROM bike_status"
        df = pd.read_sql(query, engine)
        return df
    except Exception as e:
        st.error(f"DB 연결 오류: {e}")
        return pd.DataFrame()

# 데이터 로드
df = load_data()

# 메트릭 표시
col1, col2 = st.columns(2)
col1.metric("자전거 부족 대여소 수", f"{len(df)}개")
col2.metric("기준 시간", df['updated_at'].iloc[0].strftime('%H:%M:%S')) if not df.empty else None

# 지도 시각화 (Pydeck)
if not df.empty:
    layer = pdk.Layer(
        "ScatterplotLayer",
        df,
        get_position='[lon, lat]',
        get_color='[255, 0, 0, 160]',  # 빨간색
        get_radius=100,
        pickable=True,
    )

    view_state = pdk.ViewState(
        latitude=37.5665,
        longitude=126.9780,
        zoom=11,
        pitch=50,
    )

    r = pdk.Deck(
        layers=[layer],
        initial_view_state=view_state,
        tooltip={"text": "{station_name}\n남은 자전거: {bike_count}대"}
    )

    st.pydeck_chart(r)
    
    # 데이터 테이블 표시
    st.subheader("상세 목록")
    st.dataframe(df[['station_name', 'bike_count', 'updated_at']].sort_values('bike_count'))

else:
    st.info("현재 데이터가 없거나 DB 연결을 확인해주세요.")