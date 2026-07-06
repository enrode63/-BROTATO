class_name Characters
extends RefCounted
## rounds용 캐릭터 정의. 기획서 방향대로 **외형(스킨)만** 다르고 능력치는 동일하다.
## (능력 차이는 순전히 카드 조합으로만 생긴다.)
## 접속 화면과 플레이어가 같은 데이터를 읽도록 하나의 출처로 둔다.

static func all() -> Array:
	return [
		{
			"id": "ssumawang",
			"name": "쑤마왕",
			"texture": "res://assets/player_ssumawang.png",
			"accent": Color(1.0, 0.80, 0.25),
		},
		{
			"id": "solchu",
			"name": "솔추",
			"texture": "res://assets/player_solchu.png",
			"accent": Color(0.36, 0.66, 1.0),
		},
		{
			"id": "daniel",
			"name": "다니엘",
			"texture": "res://assets/player_daniel.png",
			"accent": Color(0.32, 0.82, 0.47),
		},
	]


static func get_by_id(id: String) -> Dictionary:
	for c in all():
		if c["id"] == id:
			return c
	return all()[0]   # 기본: 쑤마왕
