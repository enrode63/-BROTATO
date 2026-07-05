class_name SpearProjectile
extends Area2D
## Piercing projectile for the 우람한 오이 (cucumber spear). Passes through
## enemies, damaging each one once.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 540.0
var damage: int = 12
var _life: float = 1.1
var _hit: Dictionary = {}


func setup(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage = dmg


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)

	var tex := load("res://assets/weapon_cucumber.png") as Texture2D
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2.ONE * (34.0 / float(tex.get_height()))
		s.rotation = direction.angle() + PI / 2.0
		s.z_index = 2
		add_child(s)


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage") and not _hit.has(body):
		_hit[body] = true
		body.take_damage(damage)
