class_name FlashOverlay
extends CanvasLayer
## Full-screen white flash for the flashbang: solid white ~0.1s then fades.

var _t: float = 0.5
var _rect: ColorRect


func _ready() -> void:
	layer = 20
	_rect = ColorRect.new()
	_rect.color = Color(1, 1, 1, 1)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.4:
		_rect.color.a = 1.0
	else:
		_rect.color.a = clampf(_t / 0.4, 0.0, 1.0)
	if _t <= 0.0:
		queue_free()
