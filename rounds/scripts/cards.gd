class_name Cards
extends RefCounted
## 라운드 패배 시 선택 가능한 능력치 카드 목록.
## 카드는 한 플레이어당 한 번만 가질 수 있다(중복 선택 불가 — 이미 가진 카드는
## 다음 선택지에 다시 나오지 않는다).

static func all() -> Array:
	return [
		{"id": "boom", "name": "BOOM", "desc": "탄환이 명중하면\n주변에 폭발 피해"},
		{"id": "fast_ball", "name": "FAST BALL", "desc": "탄속 +50%"},
		{"id": "cold_bullets", "name": "COLD BULLETS", "desc": "3발마다 한 발 적중 시\n2초간 30% 슬로우"},
		{"id": "big_bullet", "name": "BIG BULLET", "desc": "탄환 크기 +100%\n피해 +50%\n탄속 -50%"},
		{"id": "ricochet", "name": "RICOCHET", "desc": "벽에 맞아도 사라지지 않고\n2번 튕겨 나간다"},
		{"id": "stun_gun", "name": "STUN GUN", "desc": "3발마다 한 발 적중 시\n1초간 기절"},
		{"id": "buck_shot", "name": "BUCK SHOT", "desc": "산탄총으로 변경\n(부채꼴 5연발, 저피해)"},
		{"id": "sniper", "name": "SNIPER", "desc": "저격총으로 변경\n(고피해, 고속탄, 저연사)"},
		{"id": "glass_cannon", "name": "GLASS CANNON", "desc": "피해 +100%\n체력 -50%"},
		{"id": "tank", "name": "TANK", "desc": "체력 +100%"},
		{"id": "berserker", "name": "BERSERKER", "desc": "체력 50% 이하일 때\n피해 +100%, 흡혈 50%"},
		{"id": "speeeeed", "name": "SPEEEEED", "desc": "이동속도 +100%"},
		{"id": "extra_jump", "name": "EXTRA JUMP", "desc": "공중에서 점프\n1회 추가 가능"},
	]
