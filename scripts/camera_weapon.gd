class_name CameraWeapon
extends Weapon
## "캡챠해둘게요~" (camera). Flashes a translucent white cone (부채꼴); every enemy
## inside the cone takes damage and is stunned 0.3s. No projectiles.

const HALF_ANGLE_DEG := 26.0

@export var pellet_count: int = 5      ## 만렙에서 함께 발사되는 탄환 수
@export var spread_degrees: float = 32.0

var _half_angle: float = deg_to_rad(HALF_ANGLE_DEG)
var _flash: float = 0.0
var _flash_angle: float = 0.0


func _init() -> void:
	weapon_id = "camera"
	cooldown = 0.8
	attack_range = 250.0
	damage = 9
	icon_path = "res://assets/weapon_camera.png"
	icon_size = 34.0


func _process(delta: float) -> void:
	super._process(delta)
	if _flash > 0.0:
		_flash -= delta
		queue_redraw()


func _fire(target: Node2D) -> void:
	var base_angle := (target.global_position - global_position).angle()
	var dmg := effective_damage(damage)
	var reach := effective_range()
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var to: Vector2 = e.global_position - global_position
		if to.length() > reach:
			continue
		if absf(wrapf(to.angle() - base_angle, -PI, PI)) <= _half_angle:
			if e.has_method("take_damage"):
				e.take_damage(dmg)
			if e.has_method("apply_stun"):
				e.apply_stun(0.3)
	# 만렙: 처음처럼 탄환도 함께 발사.
	if level >= Weapon.MAX_LEVEL:
		for i in range(pellet_count):
			var t := 0.0
			if pellet_count > 1:
				t = float(i) / float(pellet_count - 1) - 0.5
			var ang := base_angle + deg_to_rad(spread_degrees) * t
			var b := Bullet.new()
			b.setup(Vector2.RIGHT.rotated(ang), dmg)
			b.global_position = global_position
			get_tree().current_scene.add_child(b)
	_flash = 0.14
	_flash_angle = base_angle
	queue_redraw()


func _draw() -> void:
	if _flash <= 0.0:
		return
	var a := clampf(_flash / 0.14, 0.0, 1.0)
	var radius := effective_range()
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var steps := 16
	for i in steps + 1:
		var ang := _flash_angle - _half_angle + (2.0 * _half_angle) * float(i) / float(steps)
		pts.append(Vector2.RIGHT.rotated(ang) * radius)
	draw_colored_polygon(pts, Color(1.0, 1.0, 1.0, 0.32 * a))
