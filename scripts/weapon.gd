class_name Weapon
extends Node2D
## Base class for auto-firing weapons. Subclasses override [method _fire].
## The weapon shows its icon orbiting the player and aims at the nearest enemy.
## Damage and range are boosted by the owning player's stats.

@export var cooldown: float = 1.0
@export var attack_range: float = 400.0
@export var damage: int = 10
@export var icon_path: String = ""
@export var icon_size: float = 30.0

var slot_index: int = 0
var slot_count: int = 1

var _cooldown_left: float = 0.0
var _icon: Sprite2D


func _ready() -> void:
	if icon_path != "":
		var tex := load(icon_path) as Texture2D
		if tex != null:
			_icon = Sprite2D.new()
			_icon.texture = tex
			var longest := float(max(tex.get_width(), tex.get_height()))
			_icon.scale = Vector2.ONE * (icon_size / longest)
			_icon.z_index = 1
			add_child(_icon)


func _process(delta: float) -> void:
	_update_orbit()
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	var target := _find_nearest_enemy()
	if target != null:
		_fire(target)
		_cooldown_left = cooldown


func _update_orbit() -> void:
	var angle := -PI / 2.0 + float(slot_index) * TAU / float(max(slot_count, 1))
	position = Vector2.RIGHT.rotated(angle) * 34.0
	if _icon != null:
		var t := _find_nearest_enemy()
		if t != null:
			_icon.rotation = (t.global_position - global_position).angle()
		else:
			_icon.rotation = angle


# --- stat helpers ------------------------------------------------------------

func _player() -> Node:
	return get_parent()


func effective_damage(base: int) -> int:
	var p := _player()
	var mult := 1.0
	if p is Player:
		mult += (p as Player).stat_damage_pct / 100.0
	return int(round(float(base) * mult))


func effective_range() -> float:
	var p := _player()
	var r := attack_range
	if p is Player:
		r += (p as Player).stat_range
	return r


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := effective_range()
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
