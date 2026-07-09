class_name OrbitCucumber
extends Node2D
## Spawned by a max-level 우람한 오이. Circles the player and damages any enemy
## it sweeps over.

const HIT_RADIUS := 36.0
const TICK := 0.3

var angle_offset: float = 0.0
var orbit_radius: float = 120.0
var orbit_speed: float = 2.6
var damage: int = 12

var _player: Node2D
var _t: float = 0.0
var _dmg_cd: float = 0.0


func _ready() -> void:
	add_to_group("orbit_cucumber")
	_player = get_tree().get_first_node_in_group("player")
	var tex := load("res://assets/weapon_cucumber.png") as Texture2D
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2.ONE * (30.0 / float(max(tex.get_width(), tex.get_height())))
		s.z_index = 1
		add_child(s)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	_t += delta
	var ang := angle_offset + _t * orbit_speed
	global_position = _player.global_position + Vector2.RIGHT.rotated(ang) * orbit_radius
	rotation = ang + PI / 2.0

	_dmg_cd -= delta
	if _dmg_cd <= 0.0:
		_dmg_cd = TICK
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and global_position.distance_to(e.global_position) <= HIT_RADIUS + e.body_radius and e.has_method("take_damage"):
				e.take_damage(damage)
