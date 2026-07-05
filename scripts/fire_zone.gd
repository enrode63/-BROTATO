class_name FireZone
extends Node2D
## Burning area left by a molotov. Damages enemies inside it over time.

const TICK_INTERVAL := 0.4
const TICK_DAMAGE := 7

var radius: float = 100.0
var _life: float = 4.0
var _tick: float = 0.0


func setup(r: float) -> void:
	radius = r


func _process(delta: float) -> void:
	_life -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK_INTERVAL
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
				e.take_damage(TICK_DAMAGE)
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _draw() -> void:
	var a := clampf(_life / 4.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.4, 0.1, 0.20))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(1.0, 0.6, 0.2, 0.5 * a), 3.0)
