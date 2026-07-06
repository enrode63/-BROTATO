class_name FireZone
extends Node2D
## Burning area left by a molotov. Damages enemies inside it over time.

const TICK_INTERVAL := 0.4
const TICK_DAMAGE := 7

var radius: float = 100.0
var color: Color = Color(1.0, 0.5, 0.12)  ## molotov = orange
var hits_player: bool = false             ## true for boss acne zones
var _life: float = 4.0
var _tick: float = 0.0


func setup(r: float, c: Color = Color(1.0, 0.5, 0.12), target_player: bool = false) -> void:
	radius = r
	color = c
	hits_player = target_player


func _process(delta: float) -> void:
	_life -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK_INTERVAL
		_damage_targets()
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _damage_targets() -> void:
	if hits_player:
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and global_position.distance_to(pl.global_position) <= radius and pl.has_method("take_damage"):
			pl.take_damage(TICK_DAMAGE)
	else:
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
				e.take_damage(TICK_DAMAGE)


func _draw() -> void:
	var a := clampf(_life / 4.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.20))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.55 * a), 3.0)
