class_name CutterWeapon
extends Weapon
## "시운이의 커터칼" — melee. Damages every enemy inside a short radius when
## it swings. Fast cooldown, high per-hit damage, tiny range.

const SWING_DUR := 0.22
var _swing_left: float = 0.0


func _init() -> void:
	weapon_id = "cutter"
	cooldown = 0.5
	attack_range = 72.0
	damage = 16
	icon_path = "res://assets/weapon_cutter.png"


func _process(delta: float) -> void:
	super._process(delta)
	if _swing_left > 0.0:
		_swing_left -= delta
		# sweep the blade through an arc while swinging
		if _icon != null:
			var t := clampf(1.0 - _swing_left / SWING_DUR, 0.0, 1.0)
			_icon.rotation += deg_to_rad(lerpf(-75.0, 75.0, t))
		if _swing_left <= 0.0:
			queue_redraw()


func _fire(_target: Node2D) -> void:
	var dmg := effective_damage(damage)
	var reach := effective_range()
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= reach and e.has_method("take_damage"):
			e.take_damage(dmg)
	_swing_left = SWING_DUR
	queue_redraw()


func _draw() -> void:
	if _swing_left > 0.0:
		draw_arc(Vector2.ZERO, effective_range(), 0.0, TAU, 28, Color(0.95, 0.95, 0.95, 0.55), 3.0)
