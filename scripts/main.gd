extends Node2D
## Game root: builds the arena, spawns the player, runs the endless wave loop,
## and drives the HUD. Shop / bosses / extra weapons come in later milestones.

enum State { WAVE, SHOP, GAMEOVER }

const ARENA := Vector2(1152, 648)
const WAVE_DURATION := 45.0

var state: int = State.WAVE
var wave: int = 0
var timer: float = 0.0
var spawn_timer: float = 0.0

var player: Player
var _rng := RandomNumberGenerator.new()

var _hp_bar: ProgressBar
var _hp_label: Label
var _wave_label: Label
var _timer_label: Label
var _gold_label: Label
var _center_label: Label
var _font_display: Font
var _throw_boxes: Dictionary = {}
var _throw_labels: Dictionary = {}
var _boss_wave: bool = false
var _boss_pending: bool = false
var _boss_spawn_timer: float = 0.0
var _single_boss_index: int = 0
var _banner_label: Label
var _banner_time: float = 0.0


func _ready() -> void:
	_rng.randomize()
	GameState.reset()
	_build_background()
	_build_player()
	_build_hud()
	GameState.gold_changed.connect(func(_v: int) -> void: _update_hud())
	_start_wave()


func _process(delta: float) -> void:
	match state:
		State.WAVE:
			_process_wave(delta)
		State.GAMEOVER:
			if Input.is_physical_key_pressed(KEY_R):
				get_tree().change_scene_to_file("res://scenes/character_select.tscn")
	_update_banner(delta)
	_update_hud()


func _update_banner(delta: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner_label.visible = true
		_banner_label.modulate.a = clampf(_banner_time, 0.0, 1.0)
	elif _banner_label != null:
		_banner_label.visible = false


# --- Wave loop ---------------------------------------------------------------

func _start_wave() -> void:
	wave += 1
	GameState.set_wave(wave)
	state = State.WAVE
	timer = WAVE_DURATION
	spawn_timer = 0.0
	_center_label.text = ""
	_boss_wave = wave % 5 == 0
	_boss_pending = _boss_wave
	_boss_spawn_timer = 10.0  # 보스는 웨이브 시작 10초 후 등장


func _process_wave(delta: float) -> void:
	timer -= delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		# 웨이브마다 한 번에 스폰되는 몹 수 증가 (8웨이브마다 +1, 최대 3)
		var spawn_count: int = mini(3, 1 + int(wave / 8))
		for _i in spawn_count:
			_spawn_enemy()
		spawn_timer = 2.5 if _boss_wave else maxf(0.16, 1.3 - float(wave) * 0.09)

	if _boss_pending:
		_boss_spawn_timer -= delta
		if _boss_spawn_timer <= 0.0:
			_spawn_bosses()
			_boss_pending = false

	if _boss_wave:
		# 보스를 모두 처치해야 웨이브 클리어 (보스 등장 전엔 클리어 안 됨).
		if not _boss_pending and get_tree().get_nodes_in_group("boss").is_empty():
			_end_wave()
	elif timer <= 0.0:
		_end_wave()


# --- Bosses ------------------------------------------------------------------

func _spawn_bosses() -> void:
	if wave % 10 == 0:
		_spawn_boss("seoyounggyo")
		_spawn_boss("chahyeonseung")
		show_banner("⚠ WARNING ⚠\n보스 2체 등장!", Color(1.0, 0.25, 0.25))
	else:
		var t := "seoyounggyo" if _single_boss_index % 2 == 0 else "chahyeonseung"
		_single_boss_index += 1
		var nm := "서영교" if t == "seoyounggyo" else "차현승"
		_spawn_boss(t)
		show_banner("⚠ WARNING ⚠\n보스 %s 등장!" % nm, Color(1.0, 0.25, 0.25))


func _spawn_boss(type: String) -> void:
	var b := Boss.new()
	b.arena_size = ARENA
	b.boss_type = type
	b.max_health = 2500 + wave * 225
	b.move_speed = 58.0
	b.contact_damage = 100
	b.gold_reward = 80
	b.body_radius = 42.0
	b.sprite_height = 150.0
	if type == "seoyounggyo":
		b.texture_path = "res://assets/boss_seoyounggyo.png"
		b.skill_cd_max = 20.0
	else:
		b.texture_path = "res://assets/boss_chahyeonseung.png"
		b.skill_cd_max = 7.0
	b.position = _random_edge_position()
	add_child(b)


## 서영교 스킬: 파란 몹(탱커/기본/원거리) 20마리씩 소환. 피격 시 1초 둔화.
func spawn_blue_mobs() -> void:
	for kind in ["basic", "tanker", "ranged"]:
		for i in 20:
			var e := Enemy.new()
			e.arena_size = ARENA
			_config_enemy(e, kind)
			_apply_dmg_scale(e)
			e.slow_on_hit = true
			e.base_modulate = Color(0.55, 0.65, 1.5)
			e.position = _random_edge_position()
			add_child(e)
			e.modulate = e.base_modulate


func show_banner(text: String, color: Color) -> void:
	if _banner_label == null:
		return
	_banner_label.text = text
	_banner_label.add_theme_color_override("font_color", color)
	_banner_time = 2.8


func _end_wave() -> void:
	GameState.add_gold(5 + wave * 2)  # wave-clear bonus
	# auto-collect any coins the player left on the ground
	for p in get_tree().get_nodes_in_group("pickup"):
		if p.has_method("force_collect"):
			p.force_collect()
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	# also clear stray projectiles / coins already collected above
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		b.queue_free()
	_open_shop()


func _open_shop() -> void:
	state = State.SHOP
	_center_label.text = ""
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.input_enabled = false
	var shop := Shop.new()
	shop.setup(player, wave)
	shop.continue_pressed.connect(_on_shop_continue)
	add_child(shop)


func _on_shop_continue() -> void:
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.input_enabled = true
	_start_wave()


func _spawn_enemy() -> void:
	# 3% chance: 황금 고블린 (빠르고, 안 아프고, 골드 잭팟, 7초 뒤 도망).
	if _rng.randf() < 0.03:
		var g := Enemy.new()
		g.arena_size = ARENA
		g.max_health = 24 + wave * 2
		g.move_speed = 440.0
		g.contact_damage = 0
		g.gold_reward = 25
		g.body_radius = 18.0
		g.color = Color(1.0, 0.85, 0.20)
		g.texture_path = "res://assets/goblin.png"
		g.sprite_height = 88.0
		g.wander = true
		g.flee_after = 7.0
		g.position = _random_edge_position()
		add_child(g)
		return

	# Wave 5 이후 10% 확률로 자폭몹 등장
	if wave >= 5 and _rng.randf() < 0.10:
		_spawn_bomber()
		return

	var roll := _rng.randf()
	var kind := "basic" if roll < 0.50 else ("tanker" if roll < 0.75 else "ranged")
	var e := Enemy.new()
	e.arena_size = ARENA
	_config_enemy(e, kind)
	_apply_dmg_scale(e)
	e.position = _random_edge_position()
	add_child(e)


func _spawn_bomber() -> void:
	var b := BomberEnemy.new()
	b.arena_size = ARENA
	b.max_health = 30 + wave * 6
	b.move_speed = 82.0
	b.contact_damage = 0
	b.gold_reward = 3
	b.body_radius = 15.0
	b.color = Color(0.95, 0.55, 0.15)
	b.texture_path = "res://assets/mob_bomber.png"
	b.sprite_height = 60.0
	b._wave_number = wave
	b.position = _random_edge_position()
	add_child(b)


## Configure an enemy's base stats for a given kind (basic / tanker / ranged).
func _config_enemy(e: Enemy, kind: String) -> void:
	match kind:
		"tanker":
			e.max_health = 55 + wave * 9
			e.move_speed = 62.0
			e.contact_damage = 14
			e.gold_reward = 3
			e.body_radius = 20.0
			e.color = Color(0.62, 0.24, 0.55)
			e.texture_path = "res://assets/mob_tanker.png"
			e.sprite_height = 72.0
		"ranged":
			e.max_health = 22 + wave * 4
			e.move_speed = 74.0
			e.contact_damage = 6
			e.gold_reward = 2
			e.body_radius = 15.0
			e.color = Color(0.35, 0.55, 0.95)
			e.texture_path = "res://assets/mob_ranged.png"
			e.sprite_height = 66.0
			e.ranged = true
			e.prefer_range = 300.0
			e.fire_interval = 2.0
			e.projectile_damage = 7 + int(wave / 2)
			e.projectile_speed = 250.0
		_:  # basic
			e.max_health = 16 + wave * 4
			e.move_speed = 88.0 + float(wave) * 2.0
			e.contact_damage = 8
			e.gold_reward = 1
			e.body_radius = 14.0
			e.color = Color(0.90, 0.30, 0.30)
			e.texture_path = "res://assets/mob_basic.png"
			e.sprite_height = 54.0


func _apply_dmg_scale(e: Enemy) -> void:
	# 웨이브마다 몹 데미지 +5%.
	var dmg_scale := 1.0 + 0.05 * float(wave - 1)
	e.contact_damage = int(round(float(e.contact_damage) * dmg_scale))
	e.projectile_damage = int(round(float(e.projectile_damage) * dmg_scale))


func _random_edge_position() -> Vector2:
	var margin := 24.0
	match _rng.randi_range(0, 3):
		0:  # top
			return Vector2(_rng.randf_range(0, ARENA.x), margin)
		1:  # bottom
			return Vector2(_rng.randf_range(0, ARENA.x), ARENA.y - margin)
		2:  # left
			return Vector2(margin, _rng.randf_range(0, ARENA.y))
		_:  # right
			return Vector2(ARENA.x - margin, _rng.randf_range(0, ARENA.y))


# --- Setup helpers -----------------------------------------------------------

func _build_background() -> void:
	var tex := load("res://assets/ground.png") as Texture2D
	if tex != null:
		var ground := Sprite2D.new()
		ground.texture = tex
		ground.centered = false
		ground.z_index = -10
		add_child(ground)
	else:
		var bg := ColorRect.new()
		bg.color = Color(0.10, 0.11, 0.14)
		bg.size = ARENA
		add_child(bg)


func _build_player() -> void:
	player = Player.new()
	player.position = ARENA / 2.0
	player.bounds = Rect2(Vector2.ZERO, ARENA)
	player.died.connect(_on_player_died)
	add_child(player)


func _build_hud() -> void:
	_font_display = load("res://fonts/BlackHanSans-Regular.ttf")
	var layer := CanvasLayer.new()
	add_child(layer)

	# --- Health bar (top-left) ---
	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.position = Vector2(16, 14)
	_hp_bar.custom_minimum_size = Vector2(196, 26)
	_hp_bar.size = Vector2(196, 26)
	_hp_bar.add_theme_stylebox_override("background", _bar_style(Color(0.09, 0.09, 0.12), Color(0, 0, 0, 0.6)))
	_hp_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.85, 0.20, 0.22), Color(0.4, 0.05, 0.05)))
	layer.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.position = Vector2(16, 14)
	_hp_label.size = Vector2(196, 26)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 15)
	_hp_label.add_theme_constant_override("outline_size", 4)
	_hp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	layer.add_child(_hp_label)

	# --- Gold (coin icon + amount, under the bar) ---
	var coin := TextureRect.new()
	coin.texture = load("res://assets/coin.png")
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.position = Vector2(14, 46)
	coin.size = Vector2(30, 30)
	layer.add_child(coin)

	_gold_label = Label.new()
	_gold_label.position = Vector2(50, 44)
	_gold_label.add_theme_font_override("font", _font_display)
	_gold_label.add_theme_font_size_override("font_size", 26)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_gold_label.add_theme_constant_override("outline_size", 5)
	_gold_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	layer.add_child(_gold_label)

	# --- Throwable counters (under gold) ---
	var tdefs := [["grenade", "res://assets/throw_grenade.png", "1"],
		["flashbang", "res://assets/throw_flash.png", "2"],
		["molotov", "res://assets/throw_molotov.png", "3"]]
	var tx := 14.0
	for def in tdefs:
		var box := Control.new()
		box.position = Vector2(tx, 84)
		box.custom_minimum_size = Vector2(48, 30)
		layer.add_child(box)
		var ic := TextureRect.new()
		ic.texture = load(def[1])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(26, 26)
		ic.size = Vector2(26, 26)
		box.add_child(ic)
		var key := Label.new()
		key.text = def[2]
		key.add_theme_font_size_override("font_size", 11)
		key.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		key.add_theme_constant_override("outline_size", 3)
		key.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		key.position = Vector2(0, 14)
		box.add_child(key)
		var cnt := Label.new()
		cnt.add_theme_font_override("font", _font_display)
		cnt.add_theme_font_size_override("font_size", 15)
		cnt.add_theme_constant_override("outline_size", 4)
		cnt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		cnt.position = Vector2(24, 3)
		box.add_child(cnt)
		_throw_boxes[def[0]] = box
		_throw_labels[def[0]] = cnt
		tx += 50.0

	# --- Wave + timer (top-center) ---
	_wave_label = _centered_label(layer, 22, 10)
	_wave_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	_timer_label = _centered_label(layer, 40, 34)

	# --- Boss warning banner ---
	_banner_label = _centered_label(layer, 34, 150)
	_banner_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	_banner_label.visible = false

	# --- Big center message (wave clear / game over) ---
	_center_label = Label.new()
	_center_label.add_theme_font_override("font", _font_display)
	_center_label.add_theme_font_size_override("font_size", 44)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center_label.add_theme_constant_override("outline_size", 6)
	_center_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	layer.add_child(_center_label)


func _bar_style(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(5)
	s.set_border_width_all(2)
	s.border_color = border
	return s


func _centered_label(layer: CanvasLayer, size: int, y: float) -> Label:
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l.position.y = y
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _font_display)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	layer.add_child(l)
	return l


func _update_hud() -> void:
	if player == null or not is_instance_valid(player):
		return
	_hp_bar.max_value = player.max_health
	_hp_bar.value = player.health
	_hp_label.text = "%d / %d" % [player.health, player.max_health]
	_gold_label.text = str(GameState.gold)
	for id in _throw_boxes:
		var n := int(player.throwable_counts.get(id, 0))
		_throw_boxes[id].visible = n > 0
		_throw_labels[id].text = "x%d" % n
	_wave_label.text = "WAVE %d" % wave
	match state:
		State.WAVE:
			if _boss_wave and _boss_pending:
				_timer_label.text = "보스 %d초" % int(ceil(maxf(_boss_spawn_timer, 0.0)))
			elif _boss_wave:
				_timer_label.text = "보스 %d" % get_tree().get_nodes_in_group("boss").size()
			else:
				_timer_label.text = str(int(ceil(maxf(timer, 0.0))))
		_:
			_timer_label.text = ""


func _on_player_died() -> void:
	state = State.GAMEOVER
	if is_instance_valid(player):
		player.input_enabled = false
	_center_label.text = "GAME OVER\n\n도달 웨이브: %d\n처치한 몹: %d\n보스 처치: %d\n\nR 키: 시작 화면으로" % [
		wave, GameState.kills, GameState.boss_kills]
	for e in get_tree().get_nodes_in_group("enemy"):
		e.set_physics_process(false)
