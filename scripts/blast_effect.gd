class_name BlastEffect
extends Node2D
## Brief expanding ring used for explosions.

var radius: float = 120.0
var color: Color = Color(1.0, 0.5, 0.2)
var _t: float = 0.28


func setup(r: float, c: Color) -> void:
	radius = r
	color = c


func _process(delta: float) -> void:
	_t -= delta
	queue_redraw()
	if _t <= 0.0:
		queue_free()


func _draw() -> void:
	var a := clampf(_t / 0.28, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * (1.25 - 0.25 * a), Color(color.r, color.g, color.b, 0.40 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.7 * a), 3.0)
