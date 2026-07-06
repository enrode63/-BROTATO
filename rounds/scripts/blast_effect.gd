class_name BlastEffect
extends Node2D
## BOOM 카드로 탄환이 터질 때 잠깐 나타나는 원형 폭발 이펙트.

const DURATION := 0.25
const MAX_RADIUS := 46.0

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= DURATION:
		queue_free()


func _draw() -> void:
	var f := clampf(_t / DURATION, 0.0, 1.0)
	draw_circle(Vector2.ZERO, MAX_RADIUS * f, Color(1.0, 0.55, 0.15, 1.0 - f))
