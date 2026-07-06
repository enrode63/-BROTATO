class_name CardIcon
extends Control
## 카드 선택 화면에 쓰는 능력별 아이콘. 실제 이미지 대신 능력을 상징하는
## 모양을 코드로 그린다(이 환경에 이미지 편집 도구가 없어 벡터로 대체).

var card_id: String = ""


func setup(id: String) -> void:
	card_id = id
	custom_minimum_size = Vector2(70, 70)
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	match card_id:
		"boom":
			_boom(c)
		"fast_ball":
			_fast_ball(c)
		"cold_bullets":
			_cold_bullets(c)
		"big_bullet":
			_big_bullet(c)
		"ricochet":
			_ricochet(c)
		"stun_gun":
			_stun_gun(c)
		"buck_shot":
			_buck_shot(c)
		"sniper":
			_sniper(c)
		"glass_cannon":
			_glass_cannon(c)
		"tank":
			_tank(c)
		"berserker":
			_berserker(c)
		"speeeeed":
			_speeeeed(c)
		"extra_jump":
			_extra_jump(c)
		_:
			draw_circle(c, 20.0, Color.WHITE)


func _boom(c: Vector2) -> void:
	draw_circle(c, 22.0, Color(1.0, 0.55, 0.15))
	draw_circle(c, 13.0, Color(1.0, 0.85, 0.3))
	for i in 8:
		var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
		draw_line(c + dir * 18.0, c + dir * 30.0, Color(1.0, 0.55, 0.15), 4.0)


func _fast_ball(c: Vector2) -> void:
	var col := Color(1.0, 0.9, 0.4)
	draw_circle(c + Vector2(8, 0), 9.0, col)
	for i in 3:
		var x := -8.0 - i * 9.0
		draw_line(c + Vector2(x, 0), c + Vector2(x + 7.0, 0), Color(col, 1.0 - i * 0.28), 3.0)


func _cold_bullets(c: Vector2) -> void:
	var col := Color(0.55, 0.85, 1.0)
	for i in 3:
		var dir := Vector2.RIGHT.rotated(PI / 3.0 * i)
		draw_line(c - dir * 20.0, c + dir * 20.0, col, 3.0)


func _big_bullet(c: Vector2) -> void:
	draw_circle(c, 24.0, Color(1.0, 0.9, 0.4))
	draw_arc(c, 24.0, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 2.0)


func _ricochet(c: Vector2) -> void:
	var col := Color(0.6, 1.0, 0.6)
	draw_line(c + Vector2(-22, -14), c + Vector2(0, 10), col, 4.0)
	draw_line(c + Vector2(0, 10), c + Vector2(22, -14), col, 4.0)
	draw_line(c + Vector2(22, -14), c + Vector2(11, -14), col, 4.0)
	draw_line(c + Vector2(22, -14), c + Vector2(19, -3), col, 4.0)


func _stun_gun(c: Vector2) -> void:
	var col := Color(1.0, 0.9, 0.2)
	var pts := PackedVector2Array([
		c + Vector2(2, -24), c + Vector2(-10, 2), c + Vector2(2, 2),
		c + Vector2(-4, 24), c + Vector2(14, -4), c + Vector2(2, -4),
	])
	draw_polygon(pts, PackedColorArray([col]))


func _buck_shot(c: Vector2) -> void:
	var col := Color(0.9, 0.75, 0.35)
	for i in 5:
		var t := (float(i) / 4.0) - 0.5
		var dir := Vector2.RIGHT.rotated(deg_to_rad(30.0) * t)
		draw_line(c, c + dir * 22.0, Color(col, 0.55), 2.0)
		draw_circle(c + dir * 22.0, 4.0, col)


func _sniper(c: Vector2) -> void:
	var col := Color(0.85, 0.3, 0.3)
	draw_arc(c, 22.0, 0.0, TAU, 32, col, 2.5)
	draw_line(c + Vector2(-26, 0), c + Vector2(26, 0), col, 2.0)
	draw_line(c + Vector2(0, -26), c + Vector2(0, 26), col, 2.0)
	draw_circle(c, 3.0, col)


func _glass_cannon(c: Vector2) -> void:
	var col := Color(0.75, 0.85, 1.0, 0.9)
	var pts := PackedVector2Array([
		c + Vector2(0, -24), c + Vector2(16, 6), c + Vector2(0, 24), c + Vector2(-16, 6),
	])
	draw_polygon(pts, PackedColorArray([col]))
	draw_line(c + Vector2(0, -24), c + Vector2(-3, 4), Color(0.25, 0.25, 0.35), 2.0)
	draw_line(c + Vector2(-3, 4), c + Vector2(6, 0), Color(0.25, 0.25, 0.35), 2.0)


func _tank(c: Vector2) -> void:
	var col := Color(0.4, 0.75, 0.45)
	var pts := PackedVector2Array([
		c + Vector2(0, -24), c + Vector2(20, -14), c + Vector2(20, 8),
		c + Vector2(0, 24), c + Vector2(-20, 8), c + Vector2(-20, -14),
	])
	draw_polygon(pts, PackedColorArray([col]))


func _berserker(c: Vector2) -> void:
	var col := Color(0.85, 0.15, 0.15)
	draw_circle(c, 20.0, Color(0.2, 0.2, 0.2))
	draw_line(c + Vector2(-11, -7), c + Vector2(-3, -2), col, 3.0)
	draw_line(c + Vector2(11, -7), c + Vector2(3, -2), col, 3.0)
	draw_line(c + Vector2(-8, 10), c + Vector2(8, 10), col, 3.0)


func _speeeeed(c: Vector2) -> void:
	var col := Color(0.95, 0.85, 0.3)
	for i in 3:
		var y := -12.0 + i * 12.0
		draw_line(c + Vector2(-22, y), c + Vector2(6, y), col, 3.0)
	var pts := PackedVector2Array([c + Vector2(6, -16), c + Vector2(22, 0), c + Vector2(6, 16)])
	draw_polygon(pts, PackedColorArray([col]))


func _extra_jump(c: Vector2) -> void:
	var col := Color(0.6, 0.85, 1.0)
	var pts := PackedVector2Array([c + Vector2(-12, 4), c + Vector2(0, -16), c + Vector2(12, 4)])
	draw_polygon(pts, PackedColorArray([col]))
	draw_line(c + Vector2(-8, 10), c + Vector2(8, 10), col, 3.0)
	draw_line(c + Vector2(-8, 20), c + Vector2(8, 20), Color(col, 0.5), 3.0)
