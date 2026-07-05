class_name GoldPickup
extends Node2D
## A coin dropped by a dead enemy. Sits on the ground until the player gets
## close, then flies into them (magnet) and is collected as gold.

const MAGNET_RANGE := 145.0
const COLLECT_RANGE := 16.0

var value: int = 1
var _player: Node2D = null


func setup(v: int) -> void:
	value = v


func _ready() -> void:
	add_to_group("pickup")
	var tex := load("res://assets/coin.png") as Texture2D
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2.ONE * (18.0 / float(tex.get_height()))
		s.z_index = 2
		add_child(s)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var d := global_position.distance_to(_player.global_position)
	if d <= COLLECT_RANGE:
		_collect()
	elif d <= MAGNET_RANGE:
		var spd := 190.0 + (MAGNET_RANGE - d) * 3.5
		global_position = global_position.move_toward(_player.global_position, spd * delta)


func _collect() -> void:
	GameState.add_gold(value)
	queue_free()


## Grant the gold without needing the player to walk over it (used at wave end).
func force_collect() -> void:
	GameState.add_gold(value)
	queue_free()
