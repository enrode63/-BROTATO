extends Node2D
## 대결 무대 + 3단 진행 관리자.
##  - 라운드: 죽으면 끝나는 낱개 대결.
##  - 매치: 라운드 3판 2선승. 매치를 진 사람만 카드 1장을 고른다.
##  - 게임: 매치 7전 4선승(4매치 먼저 이기면 게임 종료).

const ARENA_SIZE := Vector2(1152, 648)
const WALL := 40.0
const BG_COLOR := Color(0.11, 0.11, 0.16)
const SOLID_COLOR := Color(0.24, 0.26, 0.34)

const P1_SPAWN := Vector2(280, 420)
const P2_SPAWN := Vector2(872, 420)
const P1_COLOR := Color(0.30, 0.65, 1.0)   # 파랑
const P2_COLOR := Color(1.0, 0.45, 0.40)   # 빨강

const ROUND_WIN_SCORE := 2   ## 매치 안에서: 라운드 2승 = 매치 승리(3판 2선승)
const MATCH_WIN_SCORE := 4   ## 게임 전체: 매치 4승 = 게임 승리(7전 4선승)
const MAX_MATCHES := 7

var _local_player: Player
var _remote_player: Player

var my_round_wins: int = 0    ## 이번 매치 안에서의 라운드 승수 (0~2)
var opp_round_wins: int = 0
var my_match_score: int = 0   ## 게임 전체에서 이긴 매치 수 (0~4)
var opp_match_score: int = 0
var match_num: int = 1
var _round_active: bool = true
var _game_over: bool = false

var _ui_layer: CanvasLayer
var _score_label: Label
var _banner: Label
var _card_screen: CardSelect = null


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

	# 내 캐릭터를 상대에게 알리고, 상대 캐릭터를 받는다.
	if Net.active:
		Net.send_character()
		Net.peer_character_changed.connect(_on_peer_character)
		if Net.peer_character != "":
			_on_peer_character(Net.peer_character)

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
	if p.is_local:
		p.character_id = Net.my_character
	elif Net.peer_character != "":
		p.character_id = Net.peer_character
	add_child(p)
	return p


func _on_peer_character(id: String) -> void:
	if _remote_player:
		_remote_player.set_character(id)


# --- 네트워크 수신 ---
func _on_peer_state(data: Dictionary) -> void:
	if _remote_player:
		_remote_player.apply_net_state(data)


func _on_peer_event(data: Dictionary) -> void:
	match str(data.get("event", "")):
		"shoot":
			if _remote_player:
				var pos := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
				var stats := {
					"dmg": int(data.get("dmg", 25)),
					"spd": float(data.get("spd", 950.0)),
					"rad": float(data.get("rad", 1.0)),
					"boom": bool(data.get("boom", false)),
					"ric": int(data.get("ric", 0)),
					"stun": bool(data.get("stun", false)),
					"slow": bool(data.get("slow", false)),
				}
				for pair in data.get("dirs", []):
					var d := Vector2(float(pair[0]), float(pair[1]))
					_remote_player.spawn_remote_bullet(pos, d, stats)

				var aim_arr: Array = data.get("aim", [])
				var aim_dir := Vector2.RIGHT
				if aim_arr.size() >= 2:
					aim_dir = Vector2(float(aim_arr[0]), float(aim_arr[1]))
				var fx := MuzzleFlash.new()
				fx.global_position = pos
				fx.rotation = aim_dir.angle()
				add_child(fx)
		"dead":
			_end_round(true)
		"ready":
			_on_peer_ready()


func _on_peer_left() -> void:
	_show_banner("상대가 나갔어요")
	_round_active = false


# --- 라운드 진행 ---
func _on_local_died() -> void:
	if not _round_active:
		return
	Net.send_event({"event": "dead"})   # 상대에게 내 죽음 알림
	_end_round(false)                    # 나는 졌다


## 라운드(낱개 대결) 하나가 끝났을 때. 매치 승부가 안 났으면 카드 없이 바로 다음
## 라운드로, 매치 승부가 났으면 _end_match() 로 넘어간다.
func _end_round(i_won: bool) -> void:
	if not _round_active:
		return
	_round_active = false

	if i_won:
		my_round_wins += 1
	else:
		opp_round_wins += 1
	_freeze_players()

	if my_round_wins >= ROUND_WIN_SCORE or opp_round_wins >= ROUND_WIN_SCORE:
		_end_match(my_round_wins > opp_round_wins)
		return

	_update_score_label()
	_show_banner(("이겼다!" if i_won else "졌다...") + "\n이번 매치 " + str(my_round_wins) + " : " + str(opp_round_wins))
	await get_tree().create_timer(1.2).timeout
	_next_round_in_match()


## 매치(3판 2선승) 하나가 끝났을 때. 진 사람만 카드를 고른다.
func _end_match(did_i_win_match: bool) -> void:
	if did_i_win_match:
		my_match_score += 1
	else:
		opp_match_score += 1
	_update_score_label()

	if my_match_score >= MATCH_WIN_SCORE or opp_match_score >= MATCH_WIN_SCORE or match_num >= MAX_MATCHES:
		_game_over = true
		var msg := "무승부"
		if my_match_score > opp_match_score:
			msg = "최종 승리!"
		elif opp_match_score > my_match_score:
			msg = "패배..."
		_show_banner(msg + "\n(매치 스코어 " + str(my_match_score) + " : " + str(opp_match_score) + ")")
		return

	if did_i_win_match and Net.active:
		_show_banner("매치 승리!\n상대가 카드를 고르는 중...")
	else:
		_show_card_select()


func _on_peer_ready() -> void:
	if _round_active or _game_over:
		return
	_hide_banner()
	_next_match()


## 매치 안에서 라운드만 새로 시작(카드 없음, 점수 유지).
func _next_round_in_match() -> void:
	_start_new_round()


## 매치가 끝나 다음 매치로 넘어감(라운드 승수 초기화, 매치 번호 +1).
func _next_match() -> void:
	match_num += 1
	my_round_wins = 0
	opp_round_wins = 0
	_update_score_label()
	_start_new_round()


func _start_new_round() -> void:
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


# --- 카드 선택 (라운드 진 사람만) ---
func _show_card_select() -> void:
	if not _local_player:
		return
	var pool: Array = Cards.all().filter(func(c): return not _local_player.owned_cards.has(c["id"]))
	pool.shuffle()
	var offer: Array = pool.slice(0, mini(3, pool.size()))

	if offer.is_empty():
		# 이미 카드를 전부 가지고 있으면 그냥 다음 매치로
		if Net.active:
			Net.send_event({"event": "ready"})
		_next_match()
		return

	var portrait: Texture2D = load(Characters.get_by_id(Net.my_character)["texture"])
	var screen := CardSelect.new()
	screen.setup(offer, portrait)
	screen.card_chosen.connect(_on_card_chosen)
	_ui_layer.add_child(screen)
	_card_screen = screen


func _on_card_chosen(id: String) -> void:
	_local_player.apply_card(id)
	if _card_screen:
		_card_screen.queue_free()
		_card_screen = null
	if Net.active:
		Net.send_event({"event": "ready"})
	await get_tree().create_timer(0.4).timeout
	_next_match()


# --- UI ---
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui_layer = layer

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 28)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_score_label.offset_top = 12.0
	layer.add_child(_score_label)

	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 42)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.visible = false
	layer.add_child(_banner)


func _update_score_label() -> void:
	if _score_label:
		_score_label.text = (
			"매치 %d/%d   이번 매치 나 %d : %d 상대\n게임 스코어  나 %d : %d 상대"
			% [match_num, MAX_MATCHES, my_round_wins, opp_round_wins, my_match_score, opp_match_score]
		)


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
	_make_solid(Vector2(w / 2, h - WALL / 2), Vector2(w, WALL), "y")   # 바닥
	_make_solid(Vector2(w / 2, WALL / 2), Vector2(w, WALL), "y")       # 천장
	_make_solid(Vector2(WALL / 2, h / 2), Vector2(WALL, h), "x")       # 왼쪽
	_make_solid(Vector2(w - WALL / 2, h / 2), Vector2(WALL, h), "x")   # 오른쪽


func _build_platforms() -> void:
	_make_solid(Vector2(576, 470), Vector2(320, 28), "y")
	_make_solid(Vector2(300, 320), Vector2(230, 28), "y")
	_make_solid(Vector2(852, 320), Vector2(230, 28), "y")


## axis="x": 좌우로 튕겨야 하는 세로 벽 / axis="y": 위아래로 튕겨야 하는 가로면(바닥/발판).
## RICOCHET 카드가 벽에 부딫힌 탄환을 어느 방향으로 반사할지 판단하는 데 쓰인다.
func _make_solid(center: Vector2, size: Vector2, axis: String = "y") -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 0b0001
	body.collision_mask = 0
	body.set_meta("axis", axis)

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
