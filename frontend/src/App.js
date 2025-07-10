import React, { useEffect, useRef, useState } from "react";

function App() {
  const mapRef = useRef(null);
  const [weather, setWeather] = useState(null);
  const [backendUrl, setBackendUrl] = useState("");
  const [clickedLocation, setClickedLocation] = useState(null);

  // ✅ 1. alb-config.json 로딩 (초기 1회)
  useEffect(() => {
    fetch("/alb-config.json")
      .then((res) => res.json())
      .then((config) => {
        if (config.albUrl) {
          setBackendUrl(config.albUrl);
        } else {
          throw new Error("alb-config.json에 'albUrl' 키가 없습니다.");
        }
      })
      .catch((err) => {
        console.error("❌ alb-config.json 로딩 실패:", err);
      });
  }, []);

// ✅ 2. backendUrl이 로딩된 후 /map 요청 → Kakao Map HTML + script 추출 실행
useEffect(() => {
  if (!backendUrl) return;

  fetch(`${backendUrl}/map`)
    .then((res) => res.text())
    .then((html) => {
      if (mapRef.current) {
        // 🧩 HTML 파싱
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");

        // ✅ #map 요소만 추출해서 삽입
        const mapDiv = doc.querySelector("#map");
        if (mapDiv) {
          mapRef.current.innerHTML = mapDiv.outerHTML;
        }

        // ✅ <script> 태그들 실행 (SDK + 지도 초기화 코드)
        const scripts = doc.querySelectorAll("script");
        scripts.forEach((scriptTag) => {
          const newScript = document.createElement("script");

          if (scriptTag.src) {
            // 외부 스크립트 (예: Kakao SDK)
            newScript.src = scriptTag.src;
          } else {
            // 인라인 스크립트 (지도 생성 등)
            newScript.textContent = scriptTag.textContent;
          }

          // ⚠️ script 삽입은 반드시 DOM에 추가해야 실행됨
          document.body.appendChild(newScript);
        });
      }
    })
    .catch((err) => {
      console.error("❌ Kakao Map HTML 로딩 실패:", err);
    });
}, [backendUrl]);


  // ✅ 3. 메시지 수신 → 좌표 받아서 날씨 요청
  useEffect(() => {
    const listener = (event) => {
      if (!event.data || typeof event.data !== "object") return;
      const { lat, lon } = event.data;
      if (lat && lon) {
        setClickedLocation({ lat, lon });
        fetchWeather(lat, lon);
      }
    };
    window.addEventListener("message", listener);
    return () => window.removeEventListener("message", listener);
  }, [backendUrl]);

  // ✅ 4. 날씨 요청 함수
  const fetchWeather = async (lat, lon) => {
    try {
      const res = await fetch(`${backendUrl}/map/weather?lat=${lat}&lon=${lon}`);
      const data = await res.json();
      setWeather(data);
    } catch (err) {
      console.error("❌ 날씨 정보 요청 실패:", err);
      setWeather({ error: "날씨 정보를 불러올 수 없습니다." });
    }
  };

  // ✅ 5. 렌더링
  return (
    <div style={{ padding: 24, maxWidth: 600, margin: "auto" }}>
      <h2>
        지도에서 위치를 선택하면 <br /> 해당 지역의 날씨 정보를 확인할 수 있습니다.
      </h2>

      {/* 지도 렌더링 영역 */}
      <div ref={mapRef} style={{ width: "100%", height: "400px", border: "1px solid #ccc" }} />

      {/* 선택된 위치 + 날씨 정보 출력 */}
      <div style={{ marginTop: 20 }}>
        {clickedLocation && (
          <div>
            선택된 위치: <b>{clickedLocation.lat.toFixed(4)}, {clickedLocation.lon.toFixed(4)}</b>
          </div>
        )}
        {weather && (
          <div style={{ marginTop: 10, background: "#e6f7ff", padding: 16, borderRadius: 8 }}>
            {weather.error ? (
              <div style={{ color: "red" }}>{weather.error}</div>
            ) : (
              <>
                <div><b>날씨:</b> {weather.weather.description}</div>
                <div><b>온도:</b> {weather.weather.temperature} ℃</div>
                <img
                  src={`http://openweathermap.org/img/wn/${weather.weather.icon}@2x.png`}
                  alt="weather icon"
                />
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
