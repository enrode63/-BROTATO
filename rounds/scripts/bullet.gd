class_name Bullet
extends Area2D
## 직선으로 날아가는 탄환. 이번 단계에서는 "보이기만" 한다(데미지 없음).
## 벽·발판·플레이어에 닿으면 사라진다.
## 다음 단계에서 _on_body_entered 안에 데미지 처리를 넣는다.

const RADIUS := 5.0
const LIFETIME := 3.0            ## 최대 생존 시간(초)

var speed: float = 950.0
var direction: Vector2 = Vector2.RIGHT
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
	# TODO(다음 단계): body.is_local 이면 body.take_damage(...) 로 피해 주기
	queue_free()
