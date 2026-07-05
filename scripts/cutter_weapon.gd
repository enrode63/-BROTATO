class_name CutterWeapon
extends Weapon
## "시운이의 커터칼" — melee. Damages every enemy inside a short radius when
## it swings. Fast cooldown, high per-hit damage, tiny range.

const SWING_DUR := 0.26
var _swing_left: float = 0.0
var _swing_dir: float = 1.0  ## alternate slash direction each swing


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
		# a big, snappy arc + a forward lunge + a size pop
		if _icon != null and _icon.texture != null:
			var t := clampf(1.0 - _swing_left / SWING_DUR, 0.0, 1.0)
			var eased := t * t * (3.0 - 2.0 * t)  # smoothstep for a snappy feel
			_icon.rotation += deg_to_rad(lerpf(-135.0, 135.0, eased) * _swing_dir)
			var lunge := sin(t * PI) * 16.0
			_icon.position = Vector2.RIGHT.rotated(_icon.rotation) * lunge
			var pop := 1.0 + sin(t * PI) * 0.35
			var tex := _icon.texture
			var base_scale := icon_size / float(maxi(tex.get_width(), tex.get_height()))
			_icon.scale = Vector2.ONE * base_scale * pop
		if _swing_left <= 0.0:
			if _icon != null:
				_icon.position = Vector2.ZERO
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
	_swing_dir *= -1.0
	queue_redraw()


func _draw() -> void:
	if _swing_left > 0.0:
		draw_arc(Vector2.ZERO, effective_range(), 0.0, TAU, 28, Color(0.95, 0.95, 0.95, 0.55), 3.0)
