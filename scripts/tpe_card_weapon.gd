class_name TpeCardWeapon
extends Weapon
## "트페의 카드" — throws a random tarot card each shot.
##   GOLD = stun, BLUE = highest single-target damage, RED = area explosion.
## 만렙: 매 발사마다 세 장(GOLD+BLUE+RED)을 동시에 부채꼴로 던진다.

const MAX_LEVEL_SPREAD_DEG := 22.0

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	weapon_id = "cards"
	cooldown = 1.3
	attack_range = 380.0
	damage = 11
	icon_path = "res://assets/weapon_cards.png"
	icon_size = 36.0


func _ready() -> void:
	super._ready()
	_rng.randomize()


func _fire(target: Node2D) -> void:
	var base_angle := (target.global_position - global_position).angle()
	var dmg := effective_damage(damage)
	if level >= Weapon.MAX_LEVEL:
		for kind in 3:  # GOLD / BLUE / RED
			var t := float(kind) / 2.0 - 0.5
			var ang := base_angle + deg_to_rad(MAX_LEVEL_SPREAD_DEG) * t
			_throw_card(kind, Vector2.RIGHT.rotated(ang), dmg)
	else:
		var kind := _rng.randi_range(0, 2)
		_throw_card(kind, Vector2.RIGHT.rotated(base_angle), dmg)


func _throw_card(kind: int, dir: Vector2, dmg: int) -> void:
	var c := CardProjectile.new()
	c.setup(kind, dir, dmg)
	c.global_position = global_position
	get_tree().current_scene.add_child(c)
