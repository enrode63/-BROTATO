class_name CucumberWeapon
extends Weapon
## "우람한 오이" — long-range piercing spear. One shot passes through a whole
## line of enemies.


func _init() -> void:
	cooldown = 1.1
	attack_range = 460.0
	damage = 14
	icon_path = "res://assets/weapon_cucumber.png"
	icon_size = 34.0


func _fire(target: Node2D) -> void:
	var dir := (target.global_position - global_position).normalized()
	var s := SpearProjectile.new()
	s.setup(dir, effective_damage(damage))
	s.global_position = global_position
	get_tree().current_scene.add_child(s)
