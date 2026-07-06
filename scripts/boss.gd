class_name Boss
extends Enemy
## Boss enemy. Chases the player like a normal enemy but casts a skill on a
## cooldown. Killing all bosses is required to clear a boss wave.
##   서영교 = 민주당의 외침 (파란 몹 대량 소환)   / cd 20s
##   차현승 = 여드름 폭발 (플레이어 위치에 메테오) / cd 7s

var boss_type: String = "seoyounggyo"
var skill_cd_max: float = 20.0
var _skill_cd: float = 6.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	_skill_cd = 6.0


func _physics_process(delta: float) -> void:
	if health > 0 and _stun <= 0.0:
		_skill_cd -= delta
		if _skill_cd <= 0.0:
			_cast_skill()
			_skill_cd = skill_cd_max
	super._physics_process(delta)


func _cast_skill() -> void:
	var g := get_tree().current_scene
	if boss_type == "seoyounggyo":
		if g.has_method("show_banner"):
			g.show_banner("민주당의 외침!", Color(0.4, 0.6, 1.0))
		if g.has_method("spawn_blue_mobs"):
			g.spawn_blue_mobs()
	else:
		if g.has_method("show_banner"):
			g.show_banner("여드름 폭발!", Color(1.0, 0.45, 0.35))
		_cast_meteors()


func _cast_meteors() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	for i in 3:
		var m := Meteor.new()
		var off := Vector2(_rng.randf_range(-130.0, 130.0), _rng.randf_range(-130.0, 130.0))
		m.setup(_player.global_position + off, 22)
		get_tree().current_scene.add_child(m)


func _die() -> void:
	GameState.register_kill(true)
	# drop a jackpot of coins
	for i in 5:
		var p := GoldPickup.new()
		p.setup(int(gold_reward / 5.0) + 1)
		p.global_position = global_position + Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(-40.0, 40.0))
		get_tree().current_scene.add_child(p)
	queue_free()


func _draw() -> void:
	# boss aura ring
	draw_circle(Vector2(0, body_radius * 0.6), body_radius, Color(0, 0, 0, 0.28))
	draw_arc(Vector2.ZERO, body_radius * 1.15, 0.0, TAU, 40, Color(0.9, 0.15, 0.15, 0.7), 3.0)
