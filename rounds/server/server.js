// ROUNDS 온라인 대전용 중계(relay) 서버.
// 하는 일: 같은 "방 코드"로 접속한 두 플레이어를 짝지어주고,
//          한 명이 보낸 메시지를 다른 한 명에게 그대로 전달한다.
// 게임 판정은 각 클라이언트가 하고, 이 서버는 "우편배달부" 역할만 한다.

const http = require("http");
const { WebSocketServer, WebSocket } = require("ws");

const PORT = process.env.PORT || 9000;

// 헬스체크용 간단한 HTTP 응답(Render 같은 호스팅이 서버 살아있는지 확인함)
const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("ROUNDS relay ok");
});

const wss = new WebSocketServer({ server });

// 방 코드 -> [소켓, 소켓]
const rooms = {};

wss.on("connection", (ws) => {
  ws.room = null;

  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch (_) {
      return; // JSON 아니면 무시
    }

    if (msg.type === "join") {
      const code = String(msg.room || "default");
      if (!rooms[code]) rooms[code] = [];
      const room = rooms[code];

      if (room.length >= 2) {
        ws.send(JSON.stringify({ type: "full" })); // 이미 2명이면 거절
        return;
      }

      room.push(ws);
      ws.room = code;
      const num = room.length; // 1 또는 2
      console.log(`방 ${code}: 플레이어 ${num} 입장 (현재 ${room.length}명)`);

      // 2명이 다 모이면 양쪽에 시작 신호
      if (room.length === 2) {
        room[0].send(JSON.stringify({ type: "start", player: 1 }));
        room[1].send(JSON.stringify({ type: "start", player: 2 }));
        console.log(`방 ${code}: 대전 시작!`);
      }
      return;
    }

    // 그 외 메시지(state/event 등)는 같은 방의 "상대"에게 그대로 전달
    const room = rooms[ws.room];
    if (!room) return;
    for (const peer of room) {
      if (peer !== ws && peer.readyState === WebSocket.OPEN) {
        peer.send(raw.toString());
      }
    }
  });

  ws.on("close", () => {
    const room = rooms[ws.room];
    if (!room) return;
    for (const peer of room) {
      if (peer !== ws && peer.readyState === WebSocket.OPEN) {
        peer.send(JSON.stringify({ type: "peer_left" }));
      }
    }
    rooms[ws.room] = room.filter((p) => p !== ws);
    if (rooms[ws.room].length === 0) delete rooms[ws.room];
    console.log(`방 ${ws.room}: 한 명 퇴장`);
  });
});

server.listen(PORT, () => {
  console.log(`ROUNDS 중계 서버 실행 중 → 포트 ${PORT}`);
});
