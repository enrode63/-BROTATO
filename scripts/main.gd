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
	_update_hud()


# --- Wave loop ---------------------------------------------------------------

func _start_wave() -> void:
	wave += 1
	GameState.set_wave(wave)
	state = State.WAVE
	timer = WAVE_DURATION
	spawn_timer = 0.0
	_center_label.text = ""


func _process_wave(delta: float) -> void:
	timer -= delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		# 웨이브가 거듭될수록 더 많이/빠르게 스폰.
		spawn_timer = maxf(0.22, 1.3 - float(wave) * 0.09)
	if timer <= 0.0:
		_end_wave()


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
	var e := Enemy.new()
	e.arena_size = ARENA

	# 3% chance: 황금 고블린 (빠르고, 안 아프고, 골드 잭팟, 7초 뒤 도망).
	if _rng.randf() < 0.03:
		e.max_health = 24 + wave * 2
		e.move_speed = 440.0
		e.contact_damage = 0
		e.gold_reward = 25
		e.body_radius = 18.0
		e.color = Color(1.0, 0.85, 0.20)
		e.texture_path = "res://assets/goblin.png"
		e.sprite_height = 88.0
		e.wander = true
		e.flee_after = 7.0
		e.position = _random_edge_position()
		add_child(e)
		return

	# Spawn mix: basic 50% / tanker 25% / ranged 25%.
	var roll := _rng.randf()
	if roll < 0.50:
		e.max_health = 16 + wave * 4
		e.move_speed = 88.0 + float(wave) * 2.0
		e.contact_damage = 8
		e.gold_reward = 1
		e.body_radius = 14.0
		e.color = Color(0.90, 0.30, 0.30)
		e.texture_path = "res://assets/mob_basic.png"
		e.sprite_height = 54.0
	elif roll < 0.75:
		e.max_health = 55 + wave * 9
		e.move_speed = 62.0
		e.contact_damage = 14
		e.gold_reward = 3
		e.body_radius = 20.0
		e.color = Color(0.62, 0.24, 0.55)
		e.texture_path = "res://assets/mob_tanker.png"
		e.sprite_height = 72.0
	else:
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
	# 웨이브마다 몹 데미지 +5%.
	var dmg_scale := 1.0 + 0.05 * float(wave - 1)
	e.contact_damage = int(round(float(e.contact_damage) * dmg_scale))
	e.projectile_damage = int(round(float(e.projectile_damage) * dmg_scale))
	e.position = _random_edge_position()
	add_child(e)


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
		box.position = Vector2(tx, 82)
		box.custom_minimum_size = Vector2(62, 40)
		layer.add_child(box)
		var ic := TextureRect.new()
		ic.texture = load(def[1])
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size = Vector2(34, 34)
		box.add_child(ic)
		var key := Label.new()
		key.text = def[2]
		key.add_theme_font_size_override("font_size", 12)
		key.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		key.add_theme_constant_override("outline_size", 3)
		key.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		key.position = Vector2(0, 22)
		box.add_child(key)
		var cnt := Label.new()
		cnt.add_theme_font_override("font", _font_display)
		cnt.add_theme_font_size_override("font_size", 18)
		cnt.add_theme_constant_override("outline_size", 4)
		cnt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		cnt.position = Vector2(32, 8)
		box.add_child(cnt)
		_throw_boxes[def[0]] = box
		_throw_labels[def[0]] = cnt
		tx += 66.0

	# --- Wave + timer (top-center) ---
	_wave_label = _centered_label(layer, 22, 10)
	_wave_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	_timer_label = _centered_label(layer, 40, 34)

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
