extends Node2D
## 대결 무대 + 라운드 진행 관리자.
## 벽/발판을 만들고 두 플레이어를 배치하며, 죽음·승패·3판 2선승을 처리한다.

const ARENA_SIZE := Vector2(1152, 648)
const WALL := 40.0
const BG_COLOR := Color(0.11, 0.11, 0.16)
const SOLID_COLOR := Color(0.24, 0.26, 0.34)

const P1_SPAWN := Vector2(280, 420)
const P2_SPAWN := Vector2(872, 420)
const P1_COLOR := Color(0.30, 0.65, 1.0)   # 파랑
const P2_COLOR := Color(1.0, 0.45, 0.40)   # 빨강

const WIN_SCORE := 2      ## 3판 2선승
const MAX_ROUNDS := 5

var _local_player: Player
var _remote_player: Player

var my_score: int = 0
var opp_score: int = 0
var round_num: int = 1
var _round_active: bool = true
var _game_over: bool = false

var _score_label: Label
var _banner: Label


func _ready() -> void:
	_build_walls()
	_build_platforms()
	_spawn_players()
	_build_ui()

	Net.peer_state.connect(_on_peer_state)
	Net.peer_event.connect(_on_peer_event)
	Net.peer_left.connect(_on_peer_left)

	if _local_player:
		_local_player.died.connect(_on_local_died)

	_update_score_label()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), BG_COLOR)


# --- 플레이어 배치 ---
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
		_local_player = _make_player(1, P1_SPAWN, P1_COLOR)


func _make_player(num: int, pos: Vector2, color: Color) -> Player:
	var p := Player.new()
	p.player_num = num
	p.is_local = (not Net.active) or (num == Net.my_player)
	p.color = color
	p.position = pos
	add_child(p)
	return p


# --- 네트워크 수신 ---
func _on_peer_state(data: Dictionary) -> void:
	if _remote_player:
		_remote_player.apply_net_state(data)


func _on_peer_event(data: Dictionary) -> void:
	match str(data.get("event", "")):
		"shoot":
			if _remote_player:
				var pos := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
				var d := Vector2(float(data.get("dx", 1.0)), float(data.get("dy", 0.0)))
				_remote_player.spawn_remote_bullet(pos, d)
		"dead":
			# 상대가 죽었다고 알려옴 → 이번 라운드는 내가 승리
			_end_round(true)


func _on_peer_left() -> void:
	_show_banner("상대가 나갔어요")
	_round_active = false


# --- 라운드 진행 ---
func _on_local_died() -> void:
	if not _round_active:
		return
	Net.send_event({"event": "dead"})   # 상대에게 내 죽음 알림
	_end_round(false)                    # 나는 졌다


func _end_round(i_won: bool) -> void:
	if not _round_active:
		return
	_round_active = false

	if i_won:
		my_score += 1
	else:
		opp_score += 1
	_update_score_label()
	_freeze_players()

	if my_score >= WIN_SCORE or opp_score >= WIN_SCORE or round_num >= MAX_ROUNDS:
		_game_over = true
		var msg := "최종 승리!" if my_score > opp_score else "패배..."
		if my_score == opp_score:
			msg = "무승부"
		_show_banner(msg + "\n(" + str(my_score) + " : " + str(opp_score) + ")")
		return

	_show_banner(("이겼다!" if i_won else "졌다...") + "  라운드 " + str(round_num) + " 종료")
	await get_tree().create_timer(2.0).timeout
	_next_round()


func _next_round() -> void:
	round_num += 1
	_hide_banner()
	_clear_bullets()
	if _local_player:
		_local_player.reset_for_round(P1_SPAWN if _local_player.player_num == 1 else P2_SPAWN)
		_local_player.active = true
	if _remote_player:
		_remote_player.reset_for_round(P1_SPAWN if _remote_player.player_num == 1 else P2_SPAWN)
	_round_active = true


func _freeze_players() -> void:
	if _local_player:
		_local_player.active = false


func _clear_bullets() -> void:
	for child in get_children():
		if child is Bullet:
			child.queue_free()


# --- UI ---
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 28)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_score_label.offset_top = 12.0
	layer.add_child(_score_label)

	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 48)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.visible = false
	layer.add_child(_banner)


func _update_score_label() -> void:
	if _score_label:
		_score_label.text = "나 %d : %d 상대   (라운드 %d)" % [my_score, opp_score, round_num]


func _show_banner(text: String) -> void:
	if _banner:
		_banner.text = text
		_banner.visible = true


func _hide_banner() -> void:
	if _banner:
		_banner.visible = false


# --- 무대 만들기 ---
func _build_walls() -> void:
	var w := ARENA_SIZE.x
	var h := ARENA_SIZE.y
	_make_solid(Vector2(w / 2, h - WALL / 2), Vector2(w, WALL))
	_make_solid(Vector2(w / 2, WALL / 2), Vector2(w, WALL))
	_make_solid(Vector2(WALL / 2, h / 2), Vector2(WALL, h))
	_make_solid(Vector2(w - WALL / 2, h / 2), Vector2(WALL, h))


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
