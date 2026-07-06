extends Node2D
## 대결 무대. 벽/발판/배경을 코드로 만들고, 네트워크 역할에 따라
## 내 플레이어(조종)와 상대 플레이어(인형)를 배치한다.

const ARENA_SIZE := Vector2(1152, 648)
const WALL := 40.0
const BG_COLOR := Color(0.11, 0.11, 0.16)
const SOLID_COLOR := Color(0.24, 0.26, 0.34)

const P1_SPAWN := Vector2(280, 420)
const P2_SPAWN := Vector2(872, 420)
const P1_COLOR := Color(0.30, 0.65, 1.0)   # 파랑
const P2_COLOR := Color(1.0, 0.45, 0.40)   # 빨강

var _local_player: Player
var _remote_player: Player


func _ready() -> void:
	_build_walls()
	_build_platforms()
	_spawn_players()

	Net.peer_state.connect(_on_peer_state)
	Net.peer_event.connect(_on_peer_event)
	Net.peer_left.connect(_on_peer_left)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), BG_COLOR)


func _spawn_players() -> void:
	if Net.active and Net.my_player != 0:
		var p1 := _make_player(1, P1_SPAWN, P1_COLOR)
		var p2 := _make_player(2, P2_SPAWN, P2_COLOR)
		if Net.my_player == 1:
			_local_player = p1
			_remote_player = p2
		else:
			_local_player = p2
			_remote_player = p1
	else:
		# 오프라인 단독 테스트(접속 화면 없이 arena 를 바로 실행했을 때)
		_local_player = _make_player(1, P1_SPAWN, P1_COLOR)


func _make_player(num: int, pos: Vector2, color: Color) -> Player:
	var p := Player.new()
	p.player_num = num
	p.is_local = (not Net.active) or (num == Net.my_player)
	p.color = color
	p.position = pos
	add_child(p)
	return p


func _on_peer_state(data: Dictionary) -> void:
	if _remote_player:
		_remote_player.apply_net_state(data)


func _on_peer_event(data: Dictionary) -> void:
	if _remote_player and str(data.get("event", "")) == "shoot":
		var pos := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
		var d := Vector2(float(data.get("dx", 1.0)), float(data.get("dy", 0.0)))
		_remote_player.spawn_remote_bullet(pos, d)


func _on_peer_left() -> void:
	print("상대가 나갔습니다")   # 다음 단계에서 UI 로 처리


# --- 무대 만들기 (이전과 동일) ---
func _build_walls() -> void:
	var w := ARENA_SIZE.x
	var h := ARENA_SIZE.y
	_make_solid(Vector2(w / 2, h - WALL / 2), Vector2(w, WALL))   # 바닥
	_make_solid(Vector2(w / 2, WALL / 2), Vector2(w, WALL))       # 천장
	_make_solid(Vector2(WALL / 2, h / 2), Vector2(WALL, h))       # 왼쪽
	_make_solid(Vector2(w - WALL / 2, h / 2), Vector2(WALL, h))   # 오른쪽


func _build_platforms() -> void:
	_make_solid(Vector2(576, 470), Vector2(320, 28))
	_make_solid(Vector2(300, 320), Vector2(230, 28))
	_make_solid(Vector2(852, 320), Vector2(230, 28))


func _make_solid(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 0b0001
	body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var half := size / 2.0
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	poly.color = SOLID_COLOR
	body.add_child(poly)

	add_child(body)
