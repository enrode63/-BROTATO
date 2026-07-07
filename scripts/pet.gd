class_name Pet
extends Node2D
## Base class for all pets. Added as a child of the Player so they follow
## automatically. Each subclass overrides _use_skill().

var pet_id: String = ""
var texture_path: String = ""
var sprite_height: float = 54.0
var skill_cd_max: float = 3.0

var _skill_cd: float = 0.0
var _orbit_angle: float = 0.0
var _rng := RandomNumberGenerator.new()

const ORBIT_RADIUS := 90.0
const ORBIT_SPEED  := 0.9   ## rad/s — distinct from weapon orbit


func _ready() -> void:
	_rng.randomize()
	_orbit_angle = _rng.randf_range(0.0, TAU)
	_skill_cd = _rng.randf_range(1.0, skill_cd_max)
	if texture_path != "":
		var tex := load(texture_path) as Texture2D
		if tex != null:
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.scale = Vector2.ONE * (sprite_height / float(tex.get_height()))
			spr.z_index = 2
			add_child(spr)


func _process(delta: float) -> void:
	_orbit_angle += ORBIT_SPEED * delta
	position = Vector2.RIGHT.rotated(_orbit_angle) * ORBIT_RADIUS
	_skill_cd -= delta
	if _skill_cd <= 0.0:
		_use_skill()
		_skill_cd = skill_cd_max


func _use_skill() -> void:
	pass
