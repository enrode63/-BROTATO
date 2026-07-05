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

var health: int = 20
var _player: Node2D = null
var _attack_cooldown: float = 0.0
var _has_sprite: bool = false


func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius
	shape.shape = circle
	add_child(shape)
	_build_sprite()
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
	velocity = to_player.normalized() * move_speed
	move_and_slide()

	_attack_cooldown -= delta
	if to_player.length() <= body_radius + 18.0 and _attack_cooldown <= 0.0:
		if _player.has_method("take_damage"):
			_player.take_damage(contact_damage)
		_attack_cooldown = 0.6


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
