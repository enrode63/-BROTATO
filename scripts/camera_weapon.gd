class_name CameraWeapon
extends Weapon
## "카메라" — shotgun. Fires a spread of pellets toward the nearest enemy.

@export var pellet_count: int = 5
@export var spread_degrees: float = 32.0


func _init() -> void:
	cooldown = 0.8
	attack_range = 360.0
	damage = 7


func _fire(target: Node2D) -> void:
	var base_angle := (target.global_position - global_position).angle()
	for i in range(pellet_count):
		var t := 0.0
		if pellet_count > 1:
			t = float(i) / float(pellet_count - 1) - 0.5
		var angle := base_angle + deg_to_rad(spread_degrees) * t
		_spawn_pellet(Vector2.RIGHT.rotated(angle))


func _spawn_pellet(dir: Vector2) -> void:
	var b := Bullet.new()
	b.setup(dir, damage)
	b.global_position = global_position
	get_tree().current_scene.add_child(b)
