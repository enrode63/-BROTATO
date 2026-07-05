class_name Throwable
extends Node2D
## A thrown item (grenade / flashbang / molotov). Arcs from the player to the
## cursor, then triggers its effect on landing.

const GRENADE_RADIUS := 130.0
const GRENADE_DAMAGE := 45
const MOLOTOV_RADIUS := 105.0

var id: String = "grenade"
var _start: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _dur: float = 0.42
var _arrived: bool = false


func setup(throw_id: String, start: Vector2, target: Vector2) -> void:
	id = throw_id
	_start = start
	_target = target


func _ready() -> void:
	global_position = _start
	var tex := load(_asset()) as Texture2D
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2.ONE * (36.0 / float(max(tex.get_width(), tex.get_height())))
		s.z_index = 3
		add_child(s)


func _asset() -> String:
	match id:
		"flashbang": return "res://assets/throw_flash.png"
		"molotov": return "res://assets/throw_molotov.png"
		_: return "res://assets/throw_grenade.png"


func _process(delta: float) -> void:
	if _arrived:
		return
	_t += delta
	var k := clampf(_t / _dur, 0.0, 1.0)
	var hop := sin(k * PI) * 46.0
	global_position = _start.lerp(_target, k) - Vector2(0, hop)
	rotation += 12.0 * delta
	if k >= 1.0:
		_arrived = true
		_trigger()
		queue_free()


func _trigger() -> void:
	match id:
		"flashbang": _flashbang()
		"molotov": _molotov()
		_: _grenade()


func _grenade() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and _target.distance_to(e.global_position) <= GRENADE_RADIUS:
			if e.has_method("take_damage"):
				e.take_damage(GRENADE_DAMAGE)
			if e.has_method("apply_knockback"):
				e.apply_knockback((e.global_position - _target).normalized() * 280.0)
	_spawn_blast(GRENADE_RADIUS, Color(1.0, 0.5, 0.2))


func _flashbang() -> void:
	get_tree().current_scene.add_child(FlashOverlay.new())
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.has_method("apply_stun"):
			e.apply_stun(3.0)


func _molotov() -> void:
	var fz := FireZone.new()
	fz.setup(MOLOTOV_RADIUS)
	fz.global_position = _target
	get_tree().current_scene.add_child(fz)
	_spawn_blast(MOLOTOV_RADIUS, Color(1.0, 0.55, 0.15))


func _spawn_blast(r: float, c: Color) -> void:
	var b := BlastEffect.new()
	b.setup(r, c)
	b.global_position = _target
	get_tree().current_scene.add_child(b)
