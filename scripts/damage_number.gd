class_name DamageNumber
extends Node2D
## Small white number that floats up and fades when an enemy is hit.

const LIFETIME := 0.55

var _life := LIFETIME


func setup(amount: int, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = str(amount)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.position = Vector2(-9, -14)
	l.z_index = 5
	add_child(l)


func _process(delta: float) -> void:
	position.y -= 46.0 * delta
	_life -= delta
	modulate.a = clampf(_life / LIFETIME, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()
