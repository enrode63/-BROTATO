class_name TpeCardWeapon
extends Weapon
## "트페의 카드" — throws a random tarot card each shot.
##   GOLD = stun, BLUE = bonus XP, RED = area explosion.

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	cooldown = 1.3
	attack_range = 380.0
	damage = 11
	icon_path = "res://assets/weapon_cards.png"
	icon_size = 36.0


func _ready() -> void:
	super._ready()
	_rng.randomize()


func _fire(target: Node2D) -> void:
	var dir := (target.global_position - global_position).normalized()
	var kind := _rng.randi_range(0, 2)  # GOLD / BLUE / RED
	var c := CardProjectile.new()
	c.setup(kind, dir, effective_damage(damage))
	c.global_position = global_position
	get_tree().current_scene.add_child(c)
