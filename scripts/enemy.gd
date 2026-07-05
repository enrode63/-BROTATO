class_name Enemy
extends CharacterBody2D
## Generic melee enemy. Walks toward the player and deals contact damage on a
## short cooldown. Stats are configured by the spawner (basic vs. tanker etc.).

@export var move_speed: float = 90.0
@export var max_health: int = 20
@export var contact_damage: int = 8
@export var gold_reward: int = 1
@export var body_radius: float = 12.0
@export var color: Color = Color(0.90, 0.30, 0.30)
## Optional image for this enemy. Height on screen is [member sprite_height].
@export var texture_path: String = ""
@export var sprite_height: float = 48.0

# --- Ranged behavior (원거리 몹) ---
@export var ranged: bool = false
@export var prefer_range: float = 300.0     ## holds position once this close
@export var fire_interval: float = 2.0
@export var projectile_damage: int = 8
@export var projectile_speed: float = 260.0
@export var max_fire_range: float = 620.0

const KNOCKBACK_DECAY := 900.0
var _fire_cd: float = 2.0

var health: int = 20
var _player: Node2D = null
var _attack_cooldown: float = 0.0
var _has_sprite: bool = false
var _knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius
	shape.shape = circle
	add_child(shape)
	_build_sprite()
	_fire_cd = fire_interval
	_player = get_tree().get_first_node_in_group("player")


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
	_has_sprite = true


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	# Ranged enemies stop approaching once they are close enough to shoot.
	var move_dir := to_player.normalized()
	if ranged and dist <= prefer_range:
		move_dir = Vector2.ZERO
	velocity = move_dir * move_speed + _knockback
	move_and_slide()
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)

	if ranged:
		_fire_cd -= delta
		if _fire_cd <= 0.0 and dist <= max_fire_range:
			_fire_projectile(to_player.normalized())
			_fire_cd = fire_interval

	_attack_cooldown -= delta
	if dist <= body_radius + 18.0 and _attack_cooldown <= 0.0:
		if _player.has_method("take_damage"):
			_player.take_damage(contact_damage)
		_attack_cooldown = 0.6


func _fire_projectile(dir: Vector2) -> void:
	var b := EnemyBullet.new()
	b.setup(dir, projectile_damage, projectile_speed)
	b.global_position = global_position
	get_tree().current_scene.add_child(b)


func apply_knockback(impulse: Vector2) -> void:
	_knockback = impulse


func take_damage(amount: int) -> void:
	health -= amount
	queue_redraw()
	if health <= 0:
		_die()


func _die() -> void:
	GameState.add_gold(gold_reward)
	queue_free()


func _draw() -> void:
	# Soft shadow so figures read against the floor.
	draw_circle(Vector2(0, body_radius * 0.6), body_radius, Color(0, 0, 0, 0.22))
	if not _has_sprite:
		# Fallback look when no image is set.
		draw_circle(Vector2.ZERO, body_radius, color)
		draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 20, color.darkened(0.4), 2.0)
