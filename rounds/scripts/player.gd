class_name Player
extends CharacterBody2D
## 플레이어. 두 가지 모드:
##  - is_local=true  : 내가 조종. 입력을 읽어 움직이고 상태를 상대에게 보낸다.
##                     내 체력/카드 효과/죽음도 이 컴퓨터가 판정한다.
##  - is_local=false : 상대(원격) 인형. 네트워크로 받은 위치/조준/체력으로 표시.

signal died

const RADIUS := 16.0
const GRAVITY := 1500.0
const JUMP_VELOCITY := -580.0
const FIRE_COOLDOWN := 0.18
const NET_SEND_HZ := 20.0
const LERP_SPEED := 15.0
const SPRITE_H := 56.0
const SLOW_MULT := 0.7          ## COLD BULLETS 슬로우 배율 (30% 감속)

const BASE_MAX_HEALTH := 100
const BASE_MOVE_SPEED := 330.0
const BASE_DAMAGE := 25
const BASE_BULLET_SPEED := 950.0
const BASE_JUMPS := 1

@export var color: Color = Color(0.30, 0.65, 1.0)

var player_num: int = 1
var character_id: String = "ssumawang"
var is_local: bool = true
var health: int = 100
var max_health: int = BASE_MAX_HEALTH
var move_speed: float = BASE_MOVE_SPEED
var max_jumps: int = BASE_JUMPS
var alive: bool = true
var active: bool = true          ## false면 입력 정지(라운드 전환 중 등)

# --- 카드 효과 (owned_cards 로부터 _recompute_stats() 가 매번 다시 계산) ---
var owned_cards: Array = []
var dmg_mult: float = 1.0
var bullet_speed_mult: float = 1.0
var bullet_radius_mult: float = 1.0
var has_boom: bool = false
var has_ricochet: bool = false
var has_cold_bullets: bool = false
var has_stun_gun: bool = false
var has_berserker: bool = false
var weapon_mode: String = "normal"      ## normal / buckshot / sniper

var _tex: Texture2D = null
var _tex_size: Vector2 = Vector2.ZERO
var _jumps_left: int = 0
var _fire_cd: float = 0.0
var _aim: Vector2 = Vector2.RIGHT
var _stun_timer: float = 0.0
var _slow_timer: float = 0.0
var _stun_shot_ct: int = 0
var _cold_shot_ct: int = 0

# 원격 인형용
var _net_pos: Vector2 = Vector2.ZERO
var _has_net: bool = false
var _send_accum: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_recompute_stats()
	health = max_health

	collision_layer = 0b0010   # 2번 = 플레이어
	collision_mask = 0b0001    # 1번 = 월드
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	_net_pos = position
	set_character(character_id)


## 캐릭터(스킨) 지정. 접속 후 상대 캐릭터를 받으면 다시 호출된다.
func set_character(id: String) -> void:
	character_id = id
	var c := Characters.get_by_id(id)
	_tex = load(c["texture"])
	if _tex:
		var scale := SPRITE_H / float(_tex.get_height())
		_tex_size = Vector2(_tex.get_width() * scale, _tex.get_height() * scale)
	queue_redraw()


func _draw() -> void:
	var dim := 1.0 if alive else 0.3
	# 팀(1P 파랑 / 2P 빨강) 구분용 발밑 링
	draw_arc(Vector2.ZERO, RADIUS + 3.0, 0.0, TAU, 28, Color(color, dim), 3.0)
	if _tex:
		draw_texture_rect(_tex, Rect2(-_tex_size / 2.0, _tex_size), false, Color(1, 1, 1, dim))
	else:
		draw_circle(Vector2.ZERO, RADIUS, Color(color, dim))
	if alive:
		draw_line(Vector2.ZERO, _aim * (RADIUS + 18.0), Color.WHITE, 3.0)
	_draw_health_bar()


const HP_SEGMENTS := 10
const HP_SEG_W := 5.0
const HP_SEG_H := 9.0
const HP_SEG_GAP := 1.5
const HP_HEART_R := 6.0
const HP_RED := Color(0.82, 0.14, 0.16)
const HP_EMPTY := Color(0.16, 0.16, 0.19, 0.95)


## 하트 아이콘 + 칸으로 나뉜 픽셀풍 체력바(원작 대신 코드로 그린 형태).
func _draw_health_bar() -> void:
	var total_w := HP_SEGMENTS * (HP_SEG_W + HP_SEG_GAP) - HP_SEG_GAP
	var y := -RADIUS - 22.0
	var start_x := -total_w / 2.0

	_draw_heart(Vector2(start_x - HP_HEART_R * 1.6, y + HP_SEG_H * 0.5), HP_HEART_R)

	var filled := int(ceil(clampf(float(health) / float(max_health), 0.0, 1.0) * HP_SEGMENTS))
	for i in HP_SEGMENTS:
		var seg_x := start_x + i * (HP_SEG_W + HP_SEG_GAP)
		var col := HP_RED if i < filled else HP_EMPTY
		draw_rect(Rect2(seg_x, y, HP_SEG_W, HP_SEG_H), col)
		draw_rect(Rect2(seg_x, y, HP_SEG_W, HP_SEG_H), Color(0, 0, 0, 0.9), false, 1.0)


func _draw_heart(center: Vector2, r: float) -> void:
	draw_circle(center + Vector2(-r * 0.5, -r * 0.3), r * 0.62, HP_RED)
	draw_circle(center + Vector2(r * 0.5, -r * 0.3), r * 0.62, HP_RED)
	var pts := PackedVector2Array([
		center + Vector2(-r * 1.05, -r * 0.1),
		center + Vector2(r * 1.05, -r * 0.1),
		center + Vector2(0, r * 1.1),
	])
	draw_polygon(pts, PackedColorArray([HP_RED]))


func _physics_process(delta: float) -> void:
	if is_local:
		_local_process(delta)
	else:
		_remote_process(delta)
	queue_redraw()


func _local_process(delta: float) -> void:
	_stun_timer = maxf(_stun_timer - delta, 0.0)
	_slow_timer = maxf(_slow_timer - delta, 0.0)
	var stunned := _stun_timer > 0.0
	var speed_now := move_speed * (SLOW_MULT if _slow_timer > 0.0 else 1.0)

	if is_on_floor():
		_jumps_left = max_jumps
	else:
		velocity.y += GRAVITY * delta

	if active and alive and not stunned:
		velocity.x = Input.get_axis("p1_left", "p1_right") * speed_now
		if Input.is_action_just_pressed("p1_jump") and _jumps_left > 0:
			velocity.y = JUMP_VELOCITY
			_jumps_left -= 1
	else:
		velocity.x = 0.0

	move_and_slide()

	if active and alive and not stunned:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 1.0:
			_aim = to_mouse.normalized()
		_fire_cd = maxf(_fire_cd - delta, 0.0)
		if Input.is_action_pressed("p1_shoot") and _fire_cd <= 0.0:
			_shoot()
			_fire_cd = _effective_cooldown()

	_send_accum += delta
	if Net.active and _send_accum >= 1.0 / NET_SEND_HZ:
		_send_accum = 0.0
		Net.send_state({
			"x": position.x, "y": position.y,
			"ax": _aim.x, "ay": _aim.y,
			"hp": health, "alive": alive,
			"maxhp": max_health,
		})


func _remote_process(delta: float) -> void:
	if _has_net:
		position = position.lerp(_net_pos, clampf(delta * LERP_SPEED, 0.0, 1.0))


func apply_net_state(data: Dictionary) -> void:
	_net_pos = Vector2(float(data.get("x", position.x)), float(data.get("y", position.y)))
	var a := Vector2(float(data.get("ax", _aim.x)), float(data.get("ay", _aim.y)))
	if a.length() > 0.01:
		_aim = a.normalized()
	max_health = int(data.get("maxhp", max_health))
	health = int(data.get("hp", health))
	alive = bool(data.get("alive", alive))
	_has_net = true


# --- 사격 ---
func _shoot() -> void:
	var muzzle := global_position + _aim * (RADIUS + 8.0)
	var dirs := _fire_directions()
	var stats := _current_bullet_stats()
	for d in dirs:
		_spawn_bullet(muzzle, d, stats)
	_spawn_muzzle_flash(muzzle, _aim)

	if Net.active:
		var dirs_packed := []
		for d in dirs:
			dirs_packed.append([d.x, d.y])
		var payload := stats.duplicate()
		payload["event"] = "shoot"
		payload["x"] = muzzle.x
		payload["y"] = muzzle.y
		payload["dirs"] = dirs_packed
		payload["aim"] = [_aim.x, _aim.y]
		Net.send_event(payload)


func _spawn_muzzle_flash(pos: Vector2, dir: Vector2) -> void:
	var fx := MuzzleFlash.new()
	fx.global_position = pos
	fx.rotation = dir.angle()
	get_parent().add_child(fx)


func _fire_directions() -> Array:
	if weapon_mode == "buckshot":
		var dirs: Array = []
		var pellets := 5
		var spread_deg := 28.0
		for i in pellets:
			var t := (float(i) / float(pellets - 1)) - 0.5
			dirs.append(_aim.rotated(deg_to_rad(spread_deg) * t))
		return dirs
	return [_aim]


func _current_bullet_stats() -> Dictionary:
	var dmg := float(BASE_DAMAGE) * dmg_mult
	if weapon_mode == "buckshot":
		dmg *= 0.4
	elif weapon_mode == "sniper":
		dmg *= 2.2
	if has_berserker and health > 0 and health <= max_health / 2:
		dmg *= 2.0

	var spd := BASE_BULLET_SPEED * bullet_speed_mult
	if weapon_mode == "sniper":
		spd *= 1.6

	return {
		"dmg": int(round(dmg)),
		"spd": spd,
		"rad": bullet_radius_mult,
		"boom": has_boom,
		"ric": (2 if has_ricochet else 0),
		"stun": _stun_proc(),
		"slow": _slow_proc(),
	}


func _effective_cooldown() -> float:
	match weapon_mode:
		"sniper":
			return 0.85
		"buckshot":
			return 0.5
		_:
			return FIRE_COOLDOWN


func _stun_proc() -> bool:
	if not has_stun_gun:
		return false
	_stun_shot_ct += 1
	return _stun_shot_ct % 3 == 0


func _slow_proc() -> bool:
	if not has_cold_bullets:
		return false
	_cold_shot_ct += 1
	return _cold_shot_ct % 3 == 0


func spawn_remote_bullet(pos: Vector2, d: Vector2, stats: Dictionary) -> void:
	_spawn_bullet(pos, d, stats)


func _spawn_bullet(pos: Vector2, d: Vector2, stats: Dictionary) -> void:
	var b := Bullet.new()
	b.direction = d
	b.shooter = self
	b.damage = int(stats.get("dmg", BASE_DAMAGE))
	b.speed = float(stats.get("spd", BASE_BULLET_SPEED))
	b.radius_mult = float(stats.get("rad", 1.0))
	b.boom = bool(stats.get("boom", false))
	b.ricochet_left = int(stats.get("ric", 0))
	b.stun_proc = bool(stats.get("stun", false))
	b.slow_proc = bool(stats.get("slow", false))
	b.global_position = pos
	get_parent().add_child(b)


# --- 피해 / 카드 효과 ---
func take_damage(amount: int) -> void:
	if not is_local or not alive or not active:
		return
	health = maxi(health - amount, 0)
	if health == 0:
		alive = false
		died.emit()


## 내 탄이 상대에게 명중하는 걸 확인했을 때 호출 (BERSERKER 흡혈용).
func on_bullet_hit_enemy(dmg: int) -> void:
	if not is_local or not has_berserker or not alive:
		return
	health = mini(health + int(round(dmg * 0.5)), max_health)


func apply_stun(duration: float) -> void:
	if is_local:
		_stun_timer = maxf(_stun_timer, duration)


func apply_slow(duration: float) -> void:
	if is_local:
		_slow_timer = maxf(_slow_timer, duration)


func apply_card(id: String) -> void:
	if owned_cards.has(id):
		return
	owned_cards.append(id)
	_recompute_stats()


## owned_cards 전체를 기준으로 스탯을 처음부터 다시 계산한다.
## (카드는 중복 선택이 불가능하므로 누적 곱셈 버그 걱정 없이 매번 새로 계산하면 된다.)
func _recompute_stats() -> void:
	var hp_mult := 1.0
	dmg_mult = 1.0
	bullet_speed_mult = 1.0
	bullet_radius_mult = 1.0
	move_speed = BASE_MOVE_SPEED
	max_jumps = BASE_JUMPS
	has_boom = false
	has_ricochet = false
	has_cold_bullets = false
	has_stun_gun = false
	has_berserker = false
	weapon_mode = "normal"

	for id in owned_cards:
		match id:
			"boom":
				has_boom = true
			"fast_ball":
				bullet_speed_mult *= 1.5
			"cold_bullets":
				has_cold_bullets = true
			"big_bullet":
				bullet_radius_mult *= 2.0
				dmg_mult *= 1.5
				bullet_speed_mult *= 0.5
			"ricochet":
				has_ricochet = true
			"stun_gun":
				has_stun_gun = true
			"buck_shot":
				weapon_mode = "buckshot"
			"sniper":
				weapon_mode = "sniper"
			"glass_cannon":
				dmg_mult *= 2.0
				hp_mult -= 0.5
			"tank":
				hp_mult += 1.0
			"berserker":
				has_berserker = true
			"speeeeed":
				move_speed *= 2.0
			"extra_jump":
				max_jumps += 1

	max_health = maxi(int(round(BASE_MAX_HEALTH * maxf(hp_mult, 0.1))), 10)


func reset_for_round(pos: Vector2) -> void:
	position = pos
	_net_pos = pos
	velocity = Vector2.ZERO
	health = max_health
	alive = true
	_jumps_left = max_jumps
	_fire_cd = 0.0
	_stun_timer = 0.0
	_slow_timer = 0.0
