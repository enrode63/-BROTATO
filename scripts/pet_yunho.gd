class_name PetYunho
extends Pet
## 윤호 펫 — 주기적으로 주변 전체에 광역 폭발 데미지.

const SKILL_RADIUS := 160.0
const SKILL_DAMAGE := 18

var _flash_t: float = 0.0


func _init() -> void:
	pet_id = "yunho"
	texture_path = "res://assets/pet_yunho.png"
	skill_cd_max = 3.5


func _process(delta: float) -> void:
	super._process(delta)
	if _flash_t > 0.0:
		_flash_t -= delta
		queue_redraw()


func _use_skill() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= SKILL_RADIUS:
			if e.has_method("take_damage"):
				e.take_damage(SKILL_DAMAGE)
	var b := BlastEffect.new()
	b.setup(SKILL_RADIUS, Color(1.0, 0.55, 0.1))
	b.global_position = global_position
	get_tree().current_scene.add_child(b)
	_flash_t = 0.32
	queue_redraw()


func _draw() -> void:
	if _flash_t <= 0.0:
		return
	var a := clampf(_flash_t / 0.32, 0.0, 1.0)
	draw_circle(Vector2.ZERO, SKILL_RADIUS, Color(1.0, 0.55, 0.1, 0.09 * a))
	draw_arc(Vector2.ZERO, SKILL_RADIUS, 0.0, TAU, 32, Color(1.0, 0.6, 0.15, 0.55 * a), 3.0)
