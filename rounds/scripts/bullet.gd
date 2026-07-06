class_name Bullet
extends Area2D
## 직선으로 날아가는 탄환. 벽·발판·플레이어에 닿으면 사라진다.
## 데미지는 "맞은 플레이어를 소유한 컴퓨터"에서만 처리한다(is_local).
## → 각 컴퓨터가 자기 플레이어의 체력을 책임지는 방식(동기화 단순화).

const RADIUS := 5.0
const LIFETIME := 3.0            ## 최대 생존 시간(초)

var speed: float = 950.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 25
var shooter: Node = null         ## 쏜 사람(자기 탄에 안 맞도록 무시)

var _life: float = 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	collision_mask = 0b0011      # 월드(1) + 플레이어(2) 감지
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.9, 0.35))


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_life += delta
	if _life >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	# 내가 소유한(is_local) 살아있는 플레이어에게만 피해를 준다.
	if body is Player and body.is_local and body.alive:
		body.take_damage(damage)
	queue_free()
