class_name VirtualJoystick
extends Control
## 모바일용 가상 조이스틱. 화면 왼쪽 절반 하단을 터치하면 활성화된다.
## 방향벡터를 GameState.joystick_dir 에 매 프레임 반영한다.

const OUTER_RADIUS := 68.0
const KNOB_RADIUS  := 24.0

var _touch_idx: int = -1
var _center: Vector2
var _knob: Vector2


func _ready() -> void:
	var vp := get_viewport_rect().size
	size = Vector2(vp.x, vp.y)
	position = Vector2.ZERO
	_center = Vector2(130, vp.y - 130)
	_knob = _center
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_idx == -1 and _in_zone(event.position):
			_touch_idx = event.index
			_move(event.position)
		elif not event.pressed and event.index == _touch_idx:
			_touch_idx = -1
			GameState.joystick_dir = Vector2.ZERO
			_knob = _center
			queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _touch_idx:
			_move(event.position)


func _in_zone(pos: Vector2) -> bool:
	var vp := get_viewport_rect().size
	return pos.x < vp.x * 0.45 and pos.y > vp.y * 0.40


func _move(screen_pos: Vector2) -> void:
	var offset := screen_pos - _center
	if offset.length() > OUTER_RADIUS:
		offset = offset.normalized() * OUTER_RADIUS
	_knob = _center + offset
	GameState.joystick_dir = offset / OUTER_RADIUS
	queue_redraw()


func _draw() -> void:
	# 외부 링
	draw_circle(_center, OUTER_RADIUS, Color(0.0, 0.0, 0.0, 0.22))
	draw_arc(_center, OUTER_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.32), 3.5)
	# 노브
	draw_circle(_knob, KNOB_RADIUS, Color(1.0, 1.0, 1.0, 0.52))
	draw_arc(_knob, KNOB_RADIUS, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.85), 2.0)
