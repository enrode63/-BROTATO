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
			"ability": "체력 +200%\n\n[몸통 박치기]\n몹과 부딪치면\n넉백시키고 데미지",
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
			"ability": "[보스 킬러]\n보스몹 데미지 +200%\n받는 데미지 50% 감소",
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
			"ability": "[근접 탱커]\n적이 근접하면\n근거리 창으로\n자동 반격",
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
