class_name CardProjectile
extends Area2D
## Thrown by 트페의 카드. Colour decides the on-hit effect:
##   GOLD = stun, BLUE = highest single-target damage, RED = area explosion.

enum Kind { GOLD, BLUE, RED }

const EXPLOSION_RADIUS := 90.0
const BLUE_DAMAGE_MULT := 2.0  ## BLUE trades utility for the hardest single hit

var kind: int = Kind.RED
var direction: Vector2 = Vector2.RIGHT
var speed: float = 380.0
var damage: int = 10
var _life: float = 1.6


func setup(card_kind: int, dir: Vector2, dmg: int) -> void:
	kind = card_kind
	direction = dir.normalized()
	damage = dmg


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)

	var path := "res://assets/card_red.png"
	if kind == Kind.GOLD:
		path = "res://assets/card_gold.png"
	elif kind == Kind.BLUE:
		path = "res://assets/card_blue.png"
	var tex := load(path) as Texture2D
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2.ONE * (34.0 / float(tex.get_height()))
		s.z_index = 2
		add_child(s)


func _process(delta: float) -> void:
	rotation += 6.0 * delta
	global_position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemy"):
		return
	match kind:
		Kind.GOLD:
			if body.has_method("take_damage"):
				body.take_damage(damage)
			if body.has_method("apply_stun"):
				body.apply_stun(3.0)
		Kind.BLUE:
			if body.has_method("take_damage"):
				body.take_damage(int(round(damage * BLUE_DAMAGE_MULT)))
		Kind.RED:
			_explode()
	queue_free()


func _explode() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= EXPLOSION_RADIUS:
			if e.has_method("take_damage"):
				e.take_damage(damage)
	# brief blast marker
	var blast := _Blast.new()
	blast.global_position = global_position
	get_tree().current_scene.add_child(blast)


class _Blast extends Node2D:
	var _t := 0.18
	var _radius := 90.0
	func _process(delta: float) -> void:
		_t -= delta
		queue_redraw()
		if _t <= 0.0:
			queue_free()
	func _draw() -> void:
		var a := clampf(_t / 0.18, 0.0, 1.0)
		draw_circle(Vector2.ZERO, _radius, Color(1.0, 0.4, 0.2, 0.35 * a))
