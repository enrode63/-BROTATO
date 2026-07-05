class_name Player
extends CharacterBody2D
## The player character. Movement is manual (WASD / arrows); combat is fully
## automatic — attached weapons acquire targets and fire on their own.

signal died
signal health_changed(current: int, maximum: int)

@export var move_speed: float = 220.0
@export var max_health: int = 100
@export var body_radius: float = 14.0

## Rectangle the player is confined to. Set by Main after instancing.
var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1152, 648))
var health: int = 100
var _alive: bool = true


func _ready() -> void:
	health = max_health
	add_to_group("player")
	_build_collision()
	_attach_weapons()
	health_changed.emit(health, max_health)


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


func _physics_process(_delta: float) -> void:
	if not _alive:
		return
	velocity = _input_direction() * move_speed
	move_and_slide()
	# Keep the player inside the arena.
	global_position.x = clampf(global_position.x, bounds.position.x + body_radius, bounds.end.x - body_radius)
	global_position.y = clampf(global_position.y, bounds.position.y + body_radius, bounds.end.y - body_radius)


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
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0:
		_alive = false
		died.emit()


func _draw() -> void:
	draw_circle(Vector2.ZERO, body_radius, Color(0.30, 0.70, 1.0))
	# little facing dot / eye so orientation reads
	draw_circle(Vector2(0, -body_radius * 0.4), body_radius * 0.28, Color(0.05, 0.1, 0.2))
