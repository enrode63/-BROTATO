class_name Weapon
extends Node2D
## Base class for auto-firing weapons. Subclasses override [method _fire].
## The weapon shows its icon orbiting the player and aims at the nearest enemy.
## Damage and range are boosted by the owning player's stats.

const MAX_LEVEL := 5

@export var cooldown: float = 1.0
@export var attack_range: float = 400.0
@export var damage: int = 10
@export var icon_path: String = ""
@export var icon_size: float = 30.0

var weapon_id: String = ""
var level: int = 1                 ## 1..5, each level = +50% damage
var damage_bonus_mult: float = 1.0 ## e.g. 1.5 for a character's signature weapon
var slot_index: int = 0
var slot_count: int = 1

var _cooldown_left: float = 0.0
var _icon: Sprite2D
var _lvl_label: Label


static func roman(n: int) -> String:
	var table := ["", "I", "II", "III", "IV", "V"]
	return table[clampi(n, 0, 5)]


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
		_lvl_label = Label.new()
		_lvl_label.add_theme_font_size_override("font_size", 12)
		_lvl_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		_lvl_label.add_theme_constant_override("outline_size", 4)
		_lvl_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_lvl_label.position = Vector2(6, -6)
		_lvl_label.z_index = 2
		add_child(_lvl_label)


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
	if _lvl_label != null:
		_lvl_label.text = Weapon.roman(level)
		_lvl_label.visible = level > 1
	if _icon != null:
		var t := _find_nearest_enemy()
		if t != null:
			_icon.rotation = (t.global_position - global_position).angle()
		else:
			_icon.rotation = angle


# --- stat helpers ------------------------------------------------------------

func _player() -> Node:
	return get_parent()


func level_mult() -> float:
	return 1.0 + 0.5 * float(level - 1)


func effective_damage(base: int) -> int:
	var p := _player()
	var mult := damage_bonus_mult * level_mult()
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
