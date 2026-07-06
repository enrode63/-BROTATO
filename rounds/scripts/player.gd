class_name Player
extends CharacterBody2D
## 플레이어. 두 가지 모드:
##  - is_local=true  : 내가 조종. 입력을 읽어 움직이고 상태를 상대에게 보낸다.
##                     내 체력/죽음도 이 컴퓨터가 판정한다.
##  - is_local=false : 상대(원격) 인형. 네트워크로 받은 위치/조준/체력으로 표시.

signal died

const RADIUS := 16.0
const GRAVITY := 1500.0
const JUMP_VELOCITY := -580.0
const FIRE_COOLDOWN := 0.18
const NET_SEND_HZ := 20.0
const LERP_SPEED := 15.0

@export var color: Color = Color(0.30, 0.65, 1.0)
@export var move_speed: float = 330.0
@export var max_jumps: int = 1
@export var max_health: int = 100

var player_num: int = 1
var is_local: bool = true
var health: int = 100
var alive: bool = true
var active: bool = true            ## false면 입력 정지(라운드 전환 중 등)

var _jumps_left: int = 0
var _fire_cd: float = 0.0
var _aim: Vector2 = Vector2.RIGHT

# 원격 인형용
var _net_pos: Vector2 = Vector2.ZERO
var _has_net: bool = false
var _send_accum: float = 0.0


func _ready() -> void:
	add_to_group("player")
	health = max_health

	collision_layer = 0b0010   # 2번 = 플레이어
	collision_mask = 0b0001    # 1번 = 월드
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	_net_pos = position


func _draw() -> void:
	var body_col := color if alive else Color(color, 0.28)
	draw_circle(Vector2.ZERO, RADIUS, body_col)
	if alive:
		draw_line(Vector2.ZERO, _aim * (RADIUS + 16.0), Color.WHITE, 3.0)
	_draw_health_bar()


func _draw_health_bar() -> void:
	var w := 42.0
	var h := 6.0
	var y := -RADIUS - 14.0
	var frac := clampf(float(health) / float(max_health), 0.0, 1.0)
	draw_rect(Rect2(-w / 2.0, y, w, h), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-w / 2.0, y, w * frac, h), Color(0.35, 0.9, 0.45))


func _physics_process(delta: float) -> void:
	if is_local:
		_local_process(delta)
	else:
		_remote_process(delta)
	queue_redraw()


func _local_process(delta: float) -> void:
	if is_on_floor():
		_jumps_left = max_jumps
	else:
		velocity.y += GRAVITY * delta

	if active and alive:
		velocity.x = Input.get_axis("p1_left", "p1_right") * move_speed
		if Input.is_action_just_pressed("p1_jump") and _jumps_left > 0:
			velocity.y = JUMP_VELOCITY
			_jumps_left -= 1
	else:
		velocity.x = 0.0

	move_and_slide()

	if active and alive:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 1.0:
			_aim = to_mouse.normalized()
		_fire_cd = maxf(_fire_cd - delta, 0.0)
		if Input.is_action_pressed("p1_shoot") and _fire_cd <= 0.0:
			_shoot()
			_fire_cd = FIRE_COOLDOWN

	_send_accum += delta
	if Net.active and _send_accum >= 1.0 / NET_SEND_HZ:
		_send_accum = 0.0
		Net.send_state({
			"x": position.x, "y": position.y,
			"ax": _aim.x, "ay": _aim.y,
			"hp": health, "alive": alive,
		})


func _remote_process(delta: float) -> void:
	if _has_net:
		position = position.lerp(_net_pos, clampf(delta * LERP_SPEED, 0.0, 1.0))


func apply_net_state(data: Dictionary) -> void:
	_net_pos = Vector2(float(data.get("x", position.x)), float(data.get("y", position.y)))
	var a := Vector2(float(data.get("ax", _aim.x)), float(data.get("ay", _aim.y)))
	if a.length() > 0.01:
		_aim = a.normalized()
	health = int(data.get("hp", health))
	alive = bool(data.get("alive", alive))
	_has_net = true


func _shoot() -> void:
	var muzzle := global_position + _aim * (RADIUS + 8.0)
	_spawn_bullet(muzzle, _aim)
	if Net.active:
		Net.send_event({
			"event": "shoot",
			"x": muzzle.x, "y": muzzle.y,
			"dx": _aim.x, "dy": _aim.y,
		})


func spawn_remote_bullet(pos: Vector2, d: Vector2) -> void:
	_spawn_bullet(pos, d)


func _spawn_bullet(pos: Vector2, d: Vector2) -> void:
	var b := Bullet.new()
	b.direction = d
	b.shooter = self
	b.global_position = pos
	get_parent().add_child(b)


func take_damage(amount: int) -> void:
	# 내 플레이어이고 살아있고 활성 상태일 때만 피해를 받는다.
	if not is_local or not alive or not active:
		return
	health = maxi(health - amount, 0)
	if health == 0:
		alive = false
		died.emit()


func reset_for_round(pos: Vector2) -> void:
	position = pos
	_net_pos = pos
	velocity = Vector2.ZERO
	health = max_health
	alive = true
	_jumps_left = max_jumps
	_fire_cd = 0.0
