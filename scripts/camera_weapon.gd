class_name CameraWeapon
extends Weapon
## "카메라" — shotgun. Fires a spread of pellets and flashes a translucent white
## cone (부채꼴) in the firing direction.

@export var pellet_count: int = 5
@export var spread_degrees: float = 32.0

var _flash: float = 0.0
var _flash_angle: float = 0.0


func _init() -> void:
	weapon_id = "camera"
	cooldown = 0.8
	attack_range = 360.0
	damage = 7
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
	for i in range(pellet_count):
		var t := 0.0
		if pellet_count > 1:
			t = float(i) / float(pellet_count - 1) - 0.5
		var angle := base_angle + deg_to_rad(spread_degrees) * t
		_spawn_pellet(Vector2.RIGHT.rotated(angle), dmg)
	_flash = 0.12
	_flash_angle = base_angle
	queue_redraw()


func _spawn_pellet(dir: Vector2, dmg: int) -> void:
	var b := Bullet.new()
	b.setup(dir, dmg)
	b.global_position = global_position
	get_tree().current_scene.add_child(b)


func _draw() -> void:
	if _flash <= 0.0:
		return
	var a := clampf(_flash / 0.12, 0.0, 1.0)
	var half := deg_to_rad(26.0)
	var radius := 210.0
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var steps := 16
	for i in steps + 1:
		var ang := _flash_angle - half + (2.0 * half) * float(i) / float(steps)
		pts.append(Vector2.RIGHT.rotated(ang) * radius)
	draw_colored_polygon(pts, Color(1.0, 1.0, 1.0, 0.30 * a))
