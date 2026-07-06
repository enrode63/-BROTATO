class_name Meteor
extends Node2D
## 차현승의 여드름 메테오. Telegraphs a purple circle, then explodes over a wide
## area, damaging the player and leaving a burning acne zone. Purple to stay
## visually distinct from the orange molotov.

const ACNE_COLOR := Color(0.85, 0.2, 0.55)

var radius: float = 140.0
var damage: int = 22
var _t: float = 0.9
var _done: bool = false


func setup(pos: Vector2, dmg: int) -> void:
	global_position = pos
	damage = dmg


func _process(delta: float) -> void:
	_t -= delta
	queue_redraw()
	if _t <= 0.0 and not _done:
		_done = true
		_explode()


func _explode() -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl.global_position.distance_to(global_position) <= radius and pl.has_method("take_damage"):
		pl.take_damage(damage)
	var b := BlastEffect.new()
	b.setup(radius, ACNE_COLOR)
	b.global_position = global_position
	get_tree().current_scene.add_child(b)
	# leave a burning acne zone that keeps hurting the player standing in it
	var fz := FireZone.new()
	fz.setup(radius * 0.9, ACNE_COLOR, true)
	fz.global_position = global_position
	get_tree().current_scene.add_child(fz)
	queue_free()


func _draw() -> void:
	var k := clampf(_t / 0.9, 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(ACNE_COLOR.r, ACNE_COLOR.g, ACNE_COLOR.b, 0.85), 3.0)
	draw_circle(Vector2.ZERO, radius * (1.0 - k), Color(ACNE_COLOR.r, ACNE_COLOR.g, ACNE_COLOR.b, 0.28))
