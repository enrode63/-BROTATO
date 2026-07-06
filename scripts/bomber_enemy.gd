class_name BomberEnemy
extends Enemy
## 자폭몹: 플레이어를 발견하면 1초간 빨갛게 달아오른 뒤 고속 돌진, 근접 시 자폭한다.
## Wave 5 이후 등장, 스폰률 10%. 폭발 색: 청록 (수류탄·화염과 구별).

const DETECT_RANGE   := 620.0
const CHARGE_TIME    := 1.0
const DASH_SPEED     := 420.0
const EXPLODE_RADIUS := 120.0
const EXPLODE_COLOR  := Color(0.1, 0.92, 0.88)   ## 청록 (수류탄=주황, 여드름=자주와 구별)
const BASE_DAMAGE    := 100

enum Phase { IDLE, ARMING, DASHING }

var _phase: int = Phase.IDLE
var _arm_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _wave_number: int = 1


func _process(_delta: float) -> void:
	if _phase == Phase.ARMING:
		queue_redraw()


func _physics_process(delta: float) -> void:
	_age += delta

	# 출혈
	if _bleed_time > 0.0:
		_bleed_time -= delta
		_bleed_tick -= delta
		if _bleed_tick <= 0.0:
			_bleed_tick = 0.4
			take_damage(int(ceil(_bleed_dps * 0.4)))
			if health <= 0:
				return

	# 스턴
	if _stun > 0.0:
		_stun -= delta
		modulate = Color(1.0, 1.0, 0.5)
		velocity = _knockback
		move_and_slide()
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		if _stun <= 0.0:
			modulate = base_modulate
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return

	var to_player := _player.global_position - global_position
	var dist: float = to_player.length()

	match _phase:
		Phase.IDLE:
			if dist <= DETECT_RANGE:
				_phase = Phase.ARMING
				_arm_timer = CHARGE_TIME
			else:
				velocity = to_player.normalized() * (move_speed * 0.5) + _knockback
				move_and_slide()
				_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)

		Phase.ARMING:
			# 제자리에서 1초간 달아오름
			velocity = _knockback
			move_and_slide()
			_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
			_arm_timer -= delta
			if _arm_timer <= 0.0:
				_phase = Phase.DASHING
				_dash_dir = (_player.global_position - global_position).normalized()

		Phase.DASHING:
			velocity = _dash_dir * DASH_SPEED + _knockback
			move_and_slide()
			_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
			if dist <= body_radius + 24.0:
				_explode()


func _explode() -> void:
	var boom_dmg: int = int(BASE_DAMAGE * (1.0 + 0.05 * float(_wave_number - 1)))
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and global_position.distance_to(pl.global_position) <= EXPLODE_RADIUS and pl.has_method("take_damage"):
		pl.take_damage(boom_dmg)
	var b := BlastEffect.new()
	b.setup(EXPLODE_RADIUS, EXPLODE_COLOR)
	b.global_position = global_position
	get_tree().current_scene.add_child(b)
	var bonus: int = 0
	if _player is Player:
		bonus = (_player as Player).stat_bonus_gold
	GameState.register_kill(false)
	var gp := GoldPickup.new()
	gp.setup(gold_reward + bonus)
	gp.global_position = global_position
	get_tree().current_scene.add_child(gp)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2(0, body_radius * 0.6), body_radius, Color(0, 0, 0, 0.22))
	if _phase == Phase.ARMING:
		var t: float = 1.0 - (_arm_timer / CHARGE_TIME)
		var pulse: float = absf(sin(t * PI * 8.0))
		draw_circle(Vector2.ZERO, body_radius * (1.3 + pulse * 0.3), Color(1.0, 0.08, 0.04, 0.30 + pulse * 0.45))
		draw_arc(Vector2.ZERO, body_radius * 1.65, 0.0, TAU, 28, Color(1.0, 0.2, 0.0, 0.75 + pulse * 0.25), 5.0)
	if not _has_sprite:
		draw_circle(Vector2.ZERO, body_radius, color)
		draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 20, color.darkened(0.4), 2.0)
