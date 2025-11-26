import streamlit as st
import pandas as pd
import pydeck as pdk

st.set_page_config(layout="wide")
st.title("🚴 Seoul Bike Real-time Dashboard")

st.markdown("현재 OCI Cloud 위에서 돌아가는 따릉이 관제 시스템입니다.")

# 나중에 여기에 DB 연결 코드를 넣어서 실제 데이터를 불러옵니다.
# 지금은 가짜 데이터로 지도가 잘 뜨는지 확인합니다.
data = pd.DataFrame({
    'lat': [37.5665, 37.5500, 37.5400],
    'lon': [126.9780, 126.9900, 127.0000],
    'bikes': [0, 5, 10]
})

# 지도 시각화 (자전거 0대인 곳은 빨간색, 아니면 초록색)
layer = pdk.Layer(
    "ScatterplotLayer",
    data,
    get_position='[lon, lat]',
    get_color='[200, 30, 0, 160] if bikes == 0 else [0, 200, 30, 160]',
    get_radius=200,
)

view_state = pdk.ViewState(latitude=37.5665, longitude=126.9780, zoom=12)
st.pydeck_chart(pdk.Deck(layers=[layer], initial_view_state=view_state))