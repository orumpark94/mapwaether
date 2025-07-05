import React, { useEffect, useRef, useState } from "react";

function App() {
  const mapRef = useRef(null);
  const [marker, setMarker] = useState(null);
  const [weather, setWeather] = useState(null);

  const defaultLat = 37.5665;
  const defaultLng = 126.9780;

  useEffect(() => {
    // 백엔드에서 Kakao Map HTML을 렌더링한 결과를 받아와서 삽입
    fetch(`${process.env.REACT_APP_BACKEND_URL}/map`)  // ALB → map-api
      .then((res) => res.text())
      .then((html) => {
        if (mapRef.current) {
          mapRef.current.innerHTML = html;

          // Kakao Map 스크립트 로드 후, 클릭 이벤트 바인딩
          if (window.initKakaoMap) {
            window.initKakaoMap(onMapClick);
          }
        }
      });
  }, []);

  // 지도 클릭 시 백엔드에 날씨 요청
  const onMapClick = (lat, lon) => {
    setMarker({ lat, lon });

    fetch(`${process.env.REACT_APP_BACKEND_URL}/weather?lat=${lat}&lon=${lon}`)
      .then((res) => res.json())
      .then((data) => setWeather(data))
      .catch(() =>
        setWeather({ error: "날씨 정보를 불러올 수 없습니다." })
      );
  };

  return (
    <div style={{ padding: 24, maxWidth: 600, margin: "auto" }}>
      <h2>
        지도에서 위치를 선택하면 <br /> 해당 지역의 날씨 정보를 확인할 수 있습니다.
      </h2>
      <div ref={mapRef} style={{ width: "100%", height: "400px" }} />
      <div style={{ marginTop: 20 }}>
        {marker && (
          <div>
            선택된 위치: <b>{marker.lat.toFixed(4)}, {marker.lon.toFixed(4)}</b>
          </div>
        )}
        {weather && (
          <div style={{ marginTop: 10, background: "#e6f7ff", padding: 16, borderRadius: 8 }}>
            {weather.error ? (
              <div style={{ color: "red" }}>{weather.error}</div>
            ) : (
              <>
                <div>
                  <b>날씨:</b> {weather.weather?.[0]?.description ?? "N/A"}
                </div>
                <div>
                  <b>온도:</b> {weather.main?.temp ?? "N/A"} ℃
                </div>
                <div>
                  <b>습도:</b> {weather.main?.humidity ?? "N/A"} %
                </div>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
