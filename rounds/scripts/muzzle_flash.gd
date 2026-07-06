class_name MuzzleFlash
extends Node2D
## 발사 순간 총구에서 아주 잠깐 나타나는 화염 효과.
## 조준 방향(rotation)으로 긴 중심 스파이크 + 위아래 짧은 곁가지를 그린다.

const DURATION := 0.09
const LENGTH := 34.0

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= DURATION:
		queue_free()


func _draw() -> void:
	var f := 1.0 - clampf(_t / DURATION, 0.0, 1.0)
	var core := Color(1.0, 0.95, 0.6, f)
	var hot := Color(1.0, 0.6, 0.15, f * 0.85)

	_spike(LENGTH * f, 7.0, core)
	_spike(LENGTH * 0.55 * f, 11.0, hot)
	_side_spike(0.6, f, hot)
	_side_spike(-0.6, f, hot)


func _spike(len: float, width: float, col: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(0, -width * 0.5),
		Vector2(len, 0),
		Vector2(0, width * 0.5),
	])
	draw_polygon(pts, PackedColorArray([col]))


func _side_spike(angle: float, f: float, col: Color) -> void:
	var len := LENGTH * 0.4 * f
	var dir := Vector2.RIGHT.rotated(angle)
	var perp := dir.orthogonal() * 4.0
	var tip := dir * len
	var pts := PackedVector2Array([-perp, tip, perp])
	draw_polygon(pts, PackedColorArray([col]))
