class_name Minimap
extends Control
## 우측 상단 미니맵. 플레이어=초록 네모, 일반몹=빨간 네모, 보스=보라 네모(2배 크기).

const MAP_SIZE := Vector2(180, 101)
const DOT_SIZE := 5.0
const BOSS_DOT_SIZE := 10.0

var arena_size: Vector2 = Vector2(1152, 648)
var player: Node2D


func _ready() -> void:
	custom_minimum_size = MAP_SIZE
	size = MAP_SIZE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.0, 0.0, 0.0, 0.45))
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(1.0, 1.0, 1.0, 0.6), false, 2.0)

	var to_map: Vector2 = MAP_SIZE / arena_size
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var p: Vector2 = (e.global_position * to_map).clamp(Vector2.ZERO, MAP_SIZE)
		if e.is_in_group("boss"):
			_draw_square(p, BOSS_DOT_SIZE, Color(0.65, 0.25, 0.9))
		else:
			_draw_square(p, DOT_SIZE, Color(0.9, 0.2, 0.2))

	if player != null and is_instance_valid(player):
		var pp: Vector2 = (player.global_position * to_map).clamp(Vector2.ZERO, MAP_SIZE)
		_draw_square(pp, DOT_SIZE, Color(0.25, 0.9, 0.35))


func _draw_square(center: Vector2, s: float, col: Color) -> void:
	draw_rect(Rect2(center - Vector2.ONE * s * 0.5, Vector2.ONE * s), col)
