import React, { useState, useCallback } from "react";
import { GoogleMap, useJsApiLoader, Marker } from "@react-google-maps/api";

const containerStyle = {
  width: "100%",
  height: "400px",
};

const center = {
  lat: 37.5665, // 서울 중심
  lng: 126.9780,
};

function App() {
  const [marker, setMarker] = useState(null);
  const [weather, setWeather] = useState(null);

  // 환경변수에서 API 키 불러오기
  const apiKey = process.env.REACT_APP_GOOGLE_MAPS_API_KEY;

  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: apiKey,
  });

  // 지도 클릭 → 마커 표시 + 날씨 정보 요청
  const handleMapClick = useCallback((e) => {
    const lat = e.latLng.lat();
    const lng = e.latLng.lng();
    setMarker({ lat, lng });

    // 백엔드 API 호출(SSM에서 받아온 주소 사용)
    fetch(`${process.env.REACT_APP_BACKEND_URL}/api/weather?lat=${lat}&lon=${lng}`)
      .then((res) => res.json())
      .then((data) => setWeather(data))
      .catch(() => setWeather({ error: "날씨 정보를 불러올 수 없습니다." }));
  }, []);

  return (
    <div style={{ padding: 24, maxWidth: 600, margin: "auto" }}>
      <h2>
        지도에서 위치를 선택하면 <br /> 해당 지역의 날씨 정보를 확인할 수 있습니다.
      </h2>
      {isLoaded && (
        <GoogleMap
          mapContainerStyle={containerStyle}
          center={center}
          zoom={12}
          onClick={handleMapClick}
        >
          {marker && <Marker position={marker} />}
        </GoogleMap>
      )}
      <div style={{ marginTop: 20 }}>
        {marker && (
          <div>
            선택된 위치: <b>{marker.lat.toFixed(4)}, {marker.lng.toFixed(4)}</b>
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
