import React, { useEffect, useRef, useState } from "react";

function App() {
  const mapRef = useRef(null);
  const [marker, setMarker] = useState(null);
  const [weather, setWeather] = useState(null);
  const [backendUrl, setBackendUrl] = useState("");

  // ✅ alb-config.json에서 ALB 주소 동적 로딩
  useEffect(() => {
    fetch("/alb-config.json")
      .then((res) => res.json())
      .then((config) => {
        if (config.albUrl) {
          setBackendUrl(config.albUrl);
        } else {
          throw new Error("alb-config.json에 'albUrl' 키가 존재하지 않습니다.");
        }
      })
      .catch((err) => {
        console.error("❌ alb-config.json 로딩 실패:", err);
      });
  }, []);

  // ✅ backendUrl 로드된 후: /map HTML 렌더링 요청
  useEffect(() => {
    if (!backendUrl) return;

    fetch(`${backendUrl}/map`)
      .then((res) => res.text())
      .then((html) => {
        if (mapRef.current) {
          mapRef.current.innerHTML = html;

          const tryInitMap = () => {
            if (typeof window.initKakaoMap === "function") {
              window.initKakaoMap(onMapClick);
            } else {
              console.warn("⚠️ window.initKakaoMap이 아직 로드되지 않음. 재시도합니다.");
              setTimeout(tryInitMap, 100);
            }
          };
          tryInitMap();
        }
      })
      .catch((err) => {
        console.error("❌ map-api에서 지도 HTML 가져오기 실패:", err);
      });
  }, [backendUrl]);

  // ✅ 지도 클릭 시 → backendUrl/map/weather로 좌표 전송
  const onMapClick = (lat, lon) => {
    setMarker({ lat, lon });

    fetch(`${backendUrl}/map/weather?lat=${lat}&lon=${lon}`)
      .then((res) => res.json())
      .then((data) => setWeather(data))
      .catch(() => {
        setWeather({ error: "날씨 정보를 불러올 수 없습니다." });
      });
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
                <div><b>날씨:</b> {weather.weather?.[0]?.description ?? "N/A"}</div>
                <div><b>온도:</b> {weather.main?.temp ?? "N/A"} ℃</div>
                <div><b>습도:</b> {weather.main?.humidity ?? "N/A"} %</div>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
