# ROUNDS 중계 서버

두 플레이어를 이어주는 작은 WebSocket 서버입니다.

## 내 PC에서 먼저 테스트하기 (권장)

1. [Node.js](https://nodejs.org) 를 설치합니다 (LTS 버전).
2. 이 `server` 폴더에서 터미널을 열고:
   ```
   npm install
   npm start
   ```
3. `ROUNDS 중계 서버 실행 중 → 포트 9000` 이 보이면 성공.
4. 게임의 접속 화면에서 서버 주소를 `ws://localhost:9000` 로 두고 접속하면 됩니다.

> 같은 PC에서 확인할 땐 Godot 에디터 창을 두 개 띄워서(또는 두 번 실행) 같은 방 코드로 접속해 보세요.

## 나중에: Render.com 에 무료 배포 (친구와 다른 PC에서 플레이)

1. 이 `server` 폴더를 GitHub 저장소로 올립니다.
2. Render.com → New → **Web Service** → 해당 저장소 선택.
3. 설정: **Build Command** `npm install`, **Start Command** `npm start`.
4. 배포되면 주소가 나옵니다: `https://your-app.onrender.com`
5. 게임에서는 `wss://your-app.onrender.com` 로 접속합니다 (https → **wss**, 포트 없음).

> 무료 티어는 한동안 접속이 없으면 잠들어서, 첫 접속이 20~30초 느릴 수 있어요.
