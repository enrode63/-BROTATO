class_name Weapon
extends Node2D
## Base class for auto-firing weapons. Subclasses override [method _fire].
## The weapon ticks its own cooldown and picks the nearest enemy in range.

@export var cooldown: float = 1.0
@export var attack_range: float = 400.0
@export var damage: int = 10

var _cooldown_left: float = 0.0


func _process(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	var target := _find_nearest_enemy()
	if target != null:
		_fire(target)
		_cooldown_left = cooldown


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := attack_range
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_to(e.global_position)
		if d <= nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest


## Override in subclasses. [param target] is the acquired enemy.
func _fire(_target: Node2D) -> void:
	pass
