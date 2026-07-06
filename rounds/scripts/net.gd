extends Node
## 온라인 대전 네트워크 매니저 (autoload = 'Net').
## WebSocket 으로 중계 서버에 접속하고, 상대와 메시지를 주고받는다.
## 씬이 바뀌어도 살아있어야 하므로 autoload 로 등록되어 있다.

signal connected              ## 방에 2명이 다 모여 대전 시작 가능
signal closed                 ## 연결 실패 또는 끊김
signal peer_state(data: Dictionary)   ## 상대 위치/조준 갱신
signal peer_event(data: Dictionary)   ## 상대 이벤트(사격 등)
signal peer_left              ## 상대가 나감
signal peer_character_changed(id: String)   ## 상대가 고른 캐릭터

var active: bool = false      ## 온라인 세션 진행 중인가
var my_player: int = 0        ## 서버가 알려준 내 번호 (1 또는 2)
var my_character: String = "ssumawang"      ## 내가 고른 캐릭터
var peer_character: String = ""             ## 상대가 고른 캐릭터(마지막 수신값)

var _ws := WebSocketPeer.new()
var _room: String = ""
var _joined: bool = false


func start(url: String, room: String) -> void:
	_room = room
	_joined = false
	my_player = 0
	# 접속을 다시 시도할 때마다 새 소켓을 만든다. 이전 소켓을 재사용하면
	# 아직 CLOSED 상태가 아닐 때 connect_to_url이 ERR_ALREADY_IN_USE로
	# 실패해 화면이 그대로 멈추는(회색 화면) 문제가 있었다.
	_ws = WebSocketPeer.new()
	var err := _ws.connect_to_url(url)
	if err != OK:
		active = false
		closed.emit()
		return
	active = true


func _process(_delta: float) -> void:
	if not active:
		return
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _joined:
				_joined = true
				_send({"type": "join", "room": _room})
			while _ws.get_available_packet_count() > 0:
				_handle(_ws.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			active = false
			closed.emit()


func _handle(txt: String) -> void:
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return
	match str(data.get("type", "")):
		"start":
			my_player = int(data.get("player", 1))
			connected.emit()
		"state":
			peer_state.emit(data)
		"event":
			peer_event.emit(data)
		"char":
			peer_character = str(data.get("id", ""))
			peer_character_changed.emit(peer_character)
		"peer_left":
			peer_left.emit()
		"full":
			active = false
			closed.emit()


func send_state(data: Dictionary) -> void:
	data["type"] = "state"
	_send(data)


func send_event(data: Dictionary) -> void:
	data["type"] = "event"
	_send(data)


func send_character() -> void:
	_send({"type": "char", "id": my_character})


func _send(d: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(d))
