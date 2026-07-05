class_name EnemyBullet
extends Area2D
## Projectile fired by ranged enemies. Damages the player on contact.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 260.0
var damage: int = 8
var _life: float = 4.0
var _radius: float = 7.0


func setup(dir: Vector2, dmg: int, spd: float) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd


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
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, Color(0.75, 0.25, 0.95))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 16, Color(0.4, 0.1, 0.5), 2.0)
