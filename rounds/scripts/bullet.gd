class_name Bullet
extends Area2D
## 완전한 직선이 아니라 살짝 아래로 휘는 포물선 궤도로 날아가는 탄환.
## 사거리를 넘거나 벽/발판/플레이어에 닿으면 사라지거나(또는 튕기고), 폭발하기도 한다.
## 값(피해/크기/속도/사거리/폭발/튕김/기절/슬로우)은 쏜 사람의 카드 상태에서 계산되어 넘어온다.
## 데미지는 "맞은 플레이어를 소유한 컴퓨터"에서만 판정한다(is_local).

const BASE_RADIUS := 5.0
const LIFETIME := 3.0
const BULLET_GRAVITY := 250.0    ## 탄환을 살짝 아래로 휘게 하는 중력(포물선 궤도)
const BLAST_RADIUS := 90.0
const BLAST_DAMAGE := 15

var speed: float = 950.0
var direction: Vector2 = Vector2.RIGHT   ## 발사 순간의 조준 방향(초기값, 시각 계산용)
var velocity: Vector2 = Vector2.ZERO     ## 실제 이동 벡터. 중력으로 매 프레임 휘어진다.
var damage: int = 25
var shooter: Player = null       ## 쏜 사람(자기 탄에 안 맞도록 무시)
var max_range: float = 650.0     ## 사거리 제한(이 거리를 날면 사라짐)

var radius_mult: float = 1.0     ## BIG BULLET
var boom: bool = false           ## BOOM
var ricochet_left: int = 0       ## RICOCHET
var stun_proc: bool = false      ## STUN GUN (3발마다 이번 발이 맞으면 기절)
var slow_proc: bool = false      ## COLD BULLETS (3발마다 이번 발이 맞으면 슬로우)

var _life: float = 0.0
var _distance: float = 0.0
var _radius: float = BASE_RADIUS


func _ready() -> void:
	_radius = BASE_RADIUS * radius_mult
	velocity = direction * speed
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	collision_mask = 0b0011      # 월드(1) + 플레이어(2) 감지
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var col: Color = shooter.color if shooter else Color(1.0, 0.9, 0.35)
	_draw_trail()
	draw_circle(Vector2.ZERO, _radius, col)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 12, Color(1, 1, 1, 0.55), 1.2)


## 소총/저격(주황 화염) 기본 트레일. 슬로우/스턴이 실제로 발동하는 탄환은
## 얼음(파랑)/스턴(초록) 지그재그 이펙트로 눈에 띄게 표시한다.
func _draw_trail() -> void:
	var trail_col := _effect_color()
	var back := -velocity.normalized() if velocity.length() > 0.01 else -direction

	for i in 4:
		var len := _radius * (2.2 + i * 1.6)
		var w := maxf(_radius * (1.3 - i * 0.22), 1.0)
		var a := maxf(0.55 - i * 0.12, 0.0)
		draw_line(Vector2.ZERO, back * len, Color(trail_col, a), w)

	if stun_proc or slow_proc:
		_draw_zigzag(trail_col, back)


func _effect_color() -> Color:
	if slow_proc:
		return Color(0.35, 0.55, 1.0)     # 얼음(COLD BULLETS)
	if stun_proc:
		return Color(0.45, 1.0, 0.35)     # 스턴(STUN GUN)
	return Color(1.0, 0.55, 0.15)          # 기본 소총/저격 화염


func _draw_zigzag(col: Color, back: Vector2) -> void:
	var perp := back.orthogonal()
	var pts := PackedVector2Array()
	var segs := 5
	for i in segs + 1:
		var t := float(i) / float(segs)
		var base := back * (_radius * 5.0 * t)
		var jitter := perp * (sin(t * 14.0 + _life * 40.0) * _radius * 0.5 * (1.0 - t))
		pts.append(base + jitter)
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], Color(col, 0.8 * (1.0 - float(i) / float(pts.size()))), 2.0)


func _physics_process(delta: float) -> void:
	velocity.y += BULLET_GRAVITY * delta
	var step := velocity * delta
	position += step
	_distance += step.length()
	_life += delta
	if _life >= LIFETIME or _distance >= max_range:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return

	if body is Player:
		_hit_player(body)
		_explode(body)
		queue_free()
		return

	# 벽/발판에 맞음
	_explode(null)
	if ricochet_left > 0:
		var axis: String = body.get_meta("axis") if body.has_meta("axis") else "y"
		if axis == "x":
			velocity.x = -velocity.x   # 좌우 벽 → 좌우로 튕김
		else:
			velocity.y = -velocity.y   # 바닥/천장/발판 → 위아래로 튕김
		ricochet_left -= 1
		return
	queue_free()


func _hit_player(body: Player) -> void:
	if body.is_local and body.alive:
		body.take_damage(damage)
		if stun_proc:
			body.apply_stun(1.0)
		if slow_proc:
			body.apply_slow(2.0)
	elif shooter and shooter.is_local:
		# 내가 쏜 탄이 상대(원격 인형)에 맞는 걸 내 화면에서 확인한 순간
		# (흡혈 같은 "명중 시 나에게 생기는 효과"는 여기서 처리한다)
		shooter.on_bullet_hit_enemy(damage)


func _explode(hit_body: Player) -> void:
	if not boom:
		return
	var fx := BlastEffect.new()
	fx.global_position = global_position
	get_parent().add_child(fx)

	for node in get_tree().get_nodes_in_group("player"):
		if node == shooter or node == hit_body:
			continue
		if node is Player and node.is_local and node.alive:
			if node.global_position.distance_to(global_position) <= BLAST_RADIUS:
				node.take_damage(BLAST_DAMAGE)
