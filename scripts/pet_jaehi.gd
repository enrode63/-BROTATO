class_name PetJaehi
extends Pet
## 재희 펫 — 가장 가까운 적에게 빠른 창 찌르기.

const SPEAR_RANGE  := 200.0
const SPEAR_DAMAGE := 28

var _spear_t: float = 0.0
var _spear_dir: Vector2 = Vector2.RIGHT


func _init() -> void:
	pet_id = "jaehi"
	texture_path = "res://assets/pet_jaehi.png"
	skill_cd_max = 1.8


func _process(delta: float) -> void:
	super._process(delta)
	if _spear_t > 0.0:
		_spear_t -= delta
		queue_redraw()


func _use_skill() -> void:
	var nearest: Node2D = null
	var best_d := SPEAR_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			nearest = e
	if nearest == null:
		return
	_spear_dir = (nearest.global_position - global_position).normalized()
	if nearest.has_method("take_damage"):
		nearest.take_damage(SPEAR_DAMAGE)
	if nearest.has_method("apply_knockback"):
		nearest.apply_knockback(_spear_dir * 280.0)
	_spear_t = 0.20
	queue_redraw()


func _draw() -> void:
	if _spear_t <= 0.0:
		return
	var a := clampf(_spear_t / 0.20, 0.0, 1.0)
	draw_line(Vector2.ZERO, _spear_dir * SPEAR_RANGE * 0.9, Color(0.95, 0.9, 0.25, a), 5.0)
	draw_circle(_spear_dir * SPEAR_RANGE * 0.9, 8.0, Color(1.0, 0.95, 0.4, a))
