class_name Meteor
extends Node2D
## 차현승의 여드름 메테오. Telegraphs a red circle, then explodes, damaging the
## player if they are still inside.

var radius: float = 95.0
var damage: int = 22
var _t: float = 0.85
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
	b.setup(radius, Color(0.95, 0.35, 0.25))
	b.global_position = global_position
	get_tree().current_scene.add_child(b)
	queue_free()


func _draw() -> void:
	var k := clampf(_t / 0.85, 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 44, Color(1.0, 0.3, 0.2, 0.85), 3.0)
	draw_circle(Vector2.ZERO, radius * (1.0 - k), Color(1.0, 0.35, 0.2, 0.28))
