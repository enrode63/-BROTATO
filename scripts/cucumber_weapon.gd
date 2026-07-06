class_name CucumberWeapon
extends Weapon
## "우람한 오이" — long-range piercing spear. One shot passes through a whole
## line of enemies.


var _orbits_spawned: bool = false


func _init() -> void:
	weapon_id = "cucumber"
	cooldown = 1.1
	attack_range = 460.0
	damage = 14
	icon_path = "res://assets/weapon_cucumber.png"
	icon_size = 34.0


func _process(delta: float) -> void:
	super._process(delta)
	# 만렙: 플레이어 주변을 맴도는 오이 3개 생성 (1회).
	if level >= Weapon.MAX_LEVEL and not _orbits_spawned:
		_orbits_spawned = true
		var p := _player()
		if p != null:
			for i in 3:
				var o := OrbitCucumber.new()
				o.angle_offset = TAU * float(i) / 3.0
				o.damage = effective_damage(10)
				p.add_child(o)


func _fire(target: Node2D) -> void:
	var dir := (target.global_position - global_position).normalized()
	var s := SpearProjectile.new()
	s.setup(dir, effective_damage(damage))
	s.global_position = global_position
	get_tree().current_scene.add_child(s)
