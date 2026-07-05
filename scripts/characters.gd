class_name Characters
extends RefCounted
## Playable character definitions. One dictionary per character; the player and
## the select screen both read from here so there is a single source of truth.

const BASE_HEALTH := 100


static func all() -> Array:
	return [
		{
			"id": "daniel",
			"name": "다니엘",
			"texture": "res://assets/player_daniel.png",
			"accent": Color(0.32, 0.82, 0.47),
			"weapon": "cutter",
			"weapon_name": "시운이의 커터칼",
			"ability_title": "몸통 박치기",
			"ability_desc": "체력 +200%\n몹과 부딪치면\n넉백 + 데미지",
			"health_mult": 3.0,
			"damage_taken_mult": 1.0,
			"boss_damage_mult": 1.0,
			"bodyslam": true,
			"bodyslam_damage": 12,
			"bodyslam_knockback": 340.0,
			"spear_counter": false,
		},
		{
			"id": "ssumawang",
			"name": "쑤마왕",
			"texture": "res://assets/player_ssumawang.png",
			"accent": Color(1.0, 0.80, 0.25),
			"weapon": "camera",
			"weapon_name": "캡챠해둘게요~",
			"ability_title": "보스 킬러",
			"ability_desc": "보스몹 데미지 +200%\n받는 데미지 50% 감소",
			"health_mult": 1.0,
			"damage_taken_mult": 0.5,
			"boss_damage_mult": 3.0,
			"bodyslam": false,
			"spear_counter": false,
		},
		{
			"id": "solchu",
			"name": "솔 추",
			"texture": "res://assets/player_solchu.png",
			"accent": Color(0.36, 0.66, 1.0),
			"weapon": "cucumber",
			"weapon_name": "우람한 오이",
			"ability_title": "근접 탱커",
			"ability_desc": "체력 +40%\n적이 근접하면\n창으로 자동 반격",
			"health_mult": 1.4,
			"damage_taken_mult": 1.0,
			"boss_damage_mult": 1.0,
			"bodyslam": false,
			"spear_counter": true,
			"spear_damage": 22,
			"spear_range": 98.0,
			"spear_cooldown": 0.45,
		},
	]


static func get_by_id(id: String) -> Dictionary:
	for c in all():
		if c["id"] == id:
			return c
	return all()[1]  # default: 쑤마왕


static func index_of(id: String) -> int:
	var list := all()
	for i in list.size():
		if list[i]["id"] == id:
			return i
	return 1
