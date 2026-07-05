extends Node2D
## Game root: builds the arena, spawns the player, runs the endless wave loop,
## and drives the HUD. Shop / bosses / extra weapons come in later milestones.

enum State { WAVE, BREAK, GAMEOVER }

const ARENA := Vector2(1152, 648)
const WAVE_DURATION := 20.0
const BREAK_DURATION := 3.0

var state: int = State.WAVE
var wave: int = 0
var timer: float = 0.0
var spawn_timer: float = 0.0

var player: Player
var _rng := RandomNumberGenerator.new()

var _hp_label: Label
var _wave_label: Label
var _timer_label: Label
var _gold_label: Label
var _center_label: Label


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
		State.BREAK:
			_process_break(delta)
		State.GAMEOVER:
			if Input.is_physical_key_pressed(KEY_R):
				get_tree().reload_current_scene()
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
		# Enemies come faster in later waves, floored so it stays survivable.
		spawn_timer = maxf(0.35, 1.4 - float(wave) * 0.08)
	if timer <= 0.0:
		_end_wave()


func _end_wave() -> void:
	GameState.add_gold(5 + wave * 2)  # wave-clear bonus
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	state = State.BREAK
	timer = BREAK_DURATION
	_center_label.text = "WAVE %d CLEAR\n(다음 웨이브 준비중...)" % wave


func _process_break(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
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
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.11, 0.14)
	bg.size = ARENA
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)  # added first -> drawn behind everything


func _build_player() -> void:
	player = Player.new()
	player.position = ARENA / 2.0
	player.bounds = Rect2(Vector2.ZERO, ARENA)
	player.died.connect(_on_player_died)
	add_child(player)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(16, 12)
	layer.add_child(vbox)
	_hp_label = _make_label(vbox, 20)
	_wave_label = _make_label(vbox, 20)
	_timer_label = _make_label(vbox, 20)
	_gold_label = _make_label(vbox, 20)

	_center_label = Label.new()
	_center_label.add_theme_font_size_override("font_size", 40)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_center_label)


func _make_label(parent: Node, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _update_hud() -> void:
	if player == null or not is_instance_valid(player):
		return
	_hp_label.text = "HP: %d / %d" % [player.health, player.max_health]
	_wave_label.text = "Wave: %d" % wave
	_gold_label.text = "Gold: %d" % GameState.gold
	match state:
		State.WAVE:
			_timer_label.text = "Time: %0.1f" % maxf(timer, 0.0)
		State.BREAK:
			_timer_label.text = "Next: %0.1f" % maxf(timer, 0.0)
		_:
			_timer_label.text = ""


func _on_player_died() -> void:
	state = State.GAMEOVER
	_center_label.text = "GAME OVER\nWave %d 도달\nR 키로 재시작" % wave
	for e in get_tree().get_nodes_in_group("enemy"):
		e.set_physics_process(false)
