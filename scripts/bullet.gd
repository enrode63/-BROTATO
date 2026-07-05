class_name Bullet
extends Area2D
## Simple straight-flying projectile. Damages the first enemy it touches.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 620.0
var damage: int = 8
var _life: float = 1.3
var _radius: float = 5.0


func setup(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage = dmg


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, Color(1.0, 0.9, 0.35))
