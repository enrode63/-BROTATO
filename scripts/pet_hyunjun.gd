class_name PetHyunjun
extends Pet
## 현준 펫 — 주변 적 최대 3마리를 매혹해 펫 쪽으로 끌어당긴다.

const CHARM_RANGE    := 320.0
const CHARM_COUNT    := 3
const CHARM_DURATION := 2.5

var _charmed: Array = []
var _ring_t: float = 0.0


func _init() -> void:
	pet_id = "hyunjun"
	texture_path = "res://assets/pet_hyunjun.png"
	skill_cd_max = 6.0


func _process(delta: float) -> void:
	super._process(delta)
	# 매혹된 적의 목표를 매 프레임 이 펫 위치로 갱신
	var still_alive: Array = []
	for e in _charmed:
		if is_instance_valid(e):
			if e.has_method("set_charm_target"):
				e.set_charm_target(global_position)
			still_alive.append(e)
	_charmed = still_alive
	if _ring_t > 0.0:
		_ring_t -= delta
		queue_redraw()


func _use_skill() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	var my_pos := global_position
	enemies.sort_custom(func(a, b): return my_pos.distance_to(a.global_position) < my_pos.distance_to(b.global_position))
	var count := 0
	for e in enemies:
		if count >= CHARM_COUNT:
			break
		if not is_instance_valid(e):
			continue
		if my_pos.distance_to(e.global_position) > CHARM_RANGE:
			break
		if e.has_method("apply_charm"):
			e.apply_charm(global_position, CHARM_DURATION)
			_charmed.append(e)
		count += 1
	_ring_t = 0.5
	queue_redraw()


func _draw() -> void:
	if _ring_t <= 0.0:
		return
	var a := clampf(_ring_t / 0.5, 0.0, 1.0)
	draw_circle(Vector2.ZERO, CHARM_RANGE, Color(1.0, 0.45, 0.9, 0.05 * a))
	draw_arc(Vector2.ZERO, CHARM_RANGE, 0.0, TAU, 40, Color(1.0, 0.5, 0.92, 0.45 * a), 2.5)
