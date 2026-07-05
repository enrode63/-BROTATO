class_name Player
extends CharacterBody2D
## The player character. Movement is manual (WASD / arrows); combat is fully
## automatic — attached weapons acquire targets and fire on their own.

signal died
signal health_changed(current: int, maximum: int)

const BASE_MAX_HEALTH := 100

@export var move_speed: float = 220.0
@export var max_health: int = 100
@export var body_radius: float = 14.0
## Face/body image drawn for the player. Height on screen is [member sprite_height].
@export var texture_path: String = "res://assets/player_ssumawang.png"
@export var sprite_height: float = 56.0
## Which character to become. Empty -> read GameState.selected_character_id.
@export var character_id: String = ""

## Rectangle the player is confined to. Set by Main after instancing.
var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1152, 648))
var health: int = 100
var _alive: bool = true

# --- Character ability state (filled by _apply_character) ---
var boss_damage_mult: float = 1.0
var _damage_taken_mult: float = 1.0
var _bodyslam: bool = false
var _bodyslam_damage: int = 0
var _bodyslam_knockback: float = 0.0
var _bodyslam_cd: float = 0.0
var _spear_counter: bool = false
var _spear_damage: int = 0
var _spear_range: float = 0.0
var _spear_cooldown: float = 0.5
var _spear_cd_left: float = 0.0
var _spear_flash: float = 0.0
var _spear_angle: float = 0.0


func _ready() -> void:
	_apply_character()
	health = max_health
	add_to_group("player")
	_build_collision()
	_build_sprite()
	_attach_weapons()
	health_changed.emit(health, max_health)


func _apply_character() -> void:
	var id := character_id if character_id != "" else GameState.selected_character_id
	var c := Characters.get_by_id(id)
	texture_path = c["texture"]
	max_health = int(round(BASE_MAX_HEALTH * float(c["health_mult"])))
	_damage_taken_mult = float(c["damage_taken_mult"])
	boss_damage_mult = float(c["boss_damage_mult"])
	_bodyslam = c.get("bodyslam", false)
	_bodyslam_damage = int(c.get("bodyslam_damage", 0))
	_bodyslam_knockback = float(c.get("bodyslam_knockback", 0.0))
	_spear_counter = c.get("spear_counter", false)
	_spear_damage = int(c.get("spear_damage", 0))
	_spear_range = float(c.get("spear_range", 0.0))
	_spear_cooldown = float(c.get("spear_cooldown", 0.5))


func _build_sprite() -> void:
	if texture_path == "":
		return
	var tex := load(texture_path) as Texture2D
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2.ONE * (sprite_height / float(tex.get_height()))
	spr.z_index = 1
	add_child(spr)


func _build_collision() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius
	shape.shape = circle
	add_child(shape)


func _attach_weapons() -> void:
	# MVP loadout: the Camera (shotgun) and the Cutter knife (melee).
	add_child(CameraWeapon.new())
	add_child(CutterWeapon.new())


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	velocity = _input_direction() * move_speed
	move_and_slide()
	# Keep the player inside the arena.
	global_position.x = clampf(global_position.x, bounds.position.x + body_radius, bounds.end.x - body_radius)
	global_position.y = clampf(global_position.y, bounds.position.y + body_radius, bounds.end.y - body_radius)

	if _bodyslam:
		_update_bodyslam(delta)
	if _spear_counter:
		_update_spear_counter(delta)


## 다니엘: 몹과 부딪치면 넉백 + 데미지.
func _update_bodyslam(delta: float) -> void:
	_bodyslam_cd -= delta
	if _bodyslam_cd > 0.0:
		return
	var hit := false
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var off: Vector2 = e.global_position - global_position
		var reach: float = body_radius + float(e.body_radius) + 8.0
		if off.length() <= reach:
			if e.has_method("apply_knockback"):
				e.apply_knockback(off.normalized() * _bodyslam_knockback)
			if e.has_method("take_damage"):
				e.take_damage(_bodyslam_damage)
			hit = true
	if hit:
		_bodyslam_cd = 0.3


## 솔추: 적이 근접하면 자동으로 창 반격.
func _update_spear_counter(delta: float) -> void:
	_spear_cd_left -= delta
	if _spear_cd_left > 0.0:
		return
	var target := _nearest_enemy_within(_spear_range)
	if target == null:
		return
	var dir: Vector2 = target.global_position - global_position
	target.take_damage(_spear_damage)
	if target.has_method("apply_knockback"):
		target.apply_knockback(dir.normalized() * 150.0)
	_spear_cd_left = _spear_cooldown
	_spear_flash = 0.12
	_spear_angle = dir.angle()
	queue_redraw()


func _nearest_enemy_within(radius: float) -> Node2D:
	var nearest: Node2D = null
	var best := radius
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= best:
			best = d
			nearest = e
	return nearest


func _process(delta: float) -> void:
	if _spear_flash > 0.0:
		_spear_flash -= delta
		if _spear_flash <= 0.0:
			queue_redraw()


func _input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	return dir.normalized()


func take_damage(amount: int) -> void:
	if not _alive:
		return
	var dmg := max(0, int(round(amount * _damage_taken_mult)))
	health = max(0, health - dmg)
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0:
		_alive = false
		died.emit()


func _draw() -> void:
	# Soft shadow under the sprite for a bit of depth.
	draw_circle(Vector2(0, body_radius * 0.6), body_radius, Color(0, 0, 0, 0.25))
	# 솔추 창 반격 이펙트.
	if _spear_flash > 0.0:
		var tip := Vector2.RIGHT.rotated(_spear_angle) * _spear_range
		draw_line(Vector2.ZERO, tip, Color(0.95, 0.95, 0.98, 0.8), 4.0)
