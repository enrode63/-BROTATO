class_name Bullet
extends Area2D
## 직선으로 날아가는 탄환. 벽/발판에 닿으면 사라지거나(또는 튕기고), 폭발하기도 한다.
## 값(피해/크기/속도/폭발/튕김/기절/슬로우)은 쏜 사람의 카드 상태에서 계산되어 넘어온다.
## 데미지는 "맞은 플레이어를 소유한 컴퓨터"에서만 판정한다(is_local).

const BASE_RADIUS := 5.0
const LIFETIME := 3.0
const BLAST_RADIUS := 90.0
const BLAST_DAMAGE := 15

var speed: float = 950.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 25
var shooter: Player = null       ## 쏜 사람(자기 탄에 안 맞도록 무시)

var radius_mult: float = 1.0     ## BIG BULLET
var boom: bool = false           ## BOOM
var ricochet_left: int = 0       ## RICOCHET
var stun_proc: bool = false      ## STUN GUN (3발마다 이번 발이 맞으면 기절)
var slow_proc: bool = false      ## COLD BULLETS (3발마다 이번 발이 맞으면 슬로우)

var _life: float = 0.0
var _radius: float = BASE_RADIUS


func _ready() -> void:
	_radius = BASE_RADIUS * radius_mult
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	collision_mask = 0b0011      # 월드(1) + 플레이어(2) 감지
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	# 팀(쏜 사람) 색으로 그려서 서로 헷갈리지 않게 한다.
	var col: Color = shooter.color if shooter else Color(1.0, 0.9, 0.35)
	draw_circle(Vector2.ZERO, _radius, col)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 12, Color(1, 1, 1, 0.55), 1.2)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_life += delta
	if _life >= LIFETIME:
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
			direction.x = -direction.x   # 좌우 벽 → 좌우로 튕김
		else:
			direction.y = -direction.y   # 바닥/천장/발판 → 위아래로 튕김
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
