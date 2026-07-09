class_name RankingScreen
extends CanvasLayer
## 로컬 랭킹 목록을 보여주는 오버레이 창. 닫기 버튼을 누르면 스스로 사라진다.

signal closed

const PANEL_SIZE := Vector2(480, 520)


func _ready() -> void:
	layer = 30
	_build_ui()


func _build_ui() -> void:
	var font_d := load("res://fonts/BlackHanSans-Regular.ttf") as Font

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := Panel.new()
	panel.size = PANEL_SIZE
	panel.position = Vector2((1152.0 - PANEL_SIZE.x) / 2.0, (648.0 - PANEL_SIZE.y) / 2.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.11, 0.16)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.95, 0.75, 0.25)
	panel.add_theme_stylebox_override("panel", sb)
	dim.add_child(panel)

	var title := Label.new()
	title.text = "랭킹 TOP %d" % Ranking.MAX_ENTRIES
	title.add_theme_font_override("font", font_d)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.30))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 18
	panel.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 74)
	scroll.size = Vector2(PANEL_SIZE.x - 40.0, PANEL_SIZE.y - 156.0)
	panel.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.custom_minimum_size = Vector2(scroll.size.x, 0)
	scroll.add_child(list)

	var entries := Ranking.load_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "아직 기록이 없습니다"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.68))
		list.add_child(empty)
	else:
		for i in entries.size():
			list.add_child(_row(font_d, i + 1, entries[i]))

	var close_btn := Button.new()
	close_btn.text = "닫기"
	close_btn.add_theme_font_override("font", font_d)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.size = Vector2(140, 46)
	close_btn.position = Vector2((PANEL_SIZE.x - 140.0) / 2.0, PANEL_SIZE.y - 62.0)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.35, 0.20, 0.20)
	bsb.set_corner_radius_all(10)
	close_btn.add_theme_stylebox_override("normal", bsb)
	var bsb_h := bsb.duplicate() as StyleBoxFlat
	bsb_h.bg_color = Color(0.48, 0.26, 0.26)
	close_btn.add_theme_stylebox_override("hover", bsb_h)
	close_btn.add_theme_stylebox_override("pressed", bsb_h)
	close_btn.pressed.connect(_on_close)
	panel.add_child(close_btn)


func _row(font_d: Font, rank: int, entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var rank_lbl := Label.new()
	rank_lbl.text = "%d위" % rank
	rank_lbl.custom_minimum_size = Vector2(48, 0)
	rank_lbl.add_theme_font_override("font", font_d)
	rank_lbl.add_theme_font_size_override("font_size", 17)
	var rank_color := Color(0.85, 0.85, 0.9)
	if rank == 1:
		rank_color = Color(1.0, 0.84, 0.2)
	elif rank == 2:
		rank_color = Color(0.78, 0.82, 0.88)
	elif rank == 3:
		rank_color = Color(0.85, 0.55, 0.30)
	rank_lbl.add_theme_color_override("font_color", rank_color)
	row.add_child(rank_lbl)

	var msg_lbl := Label.new()
	var msg: String = str(entry.get("message", ""))
	msg_lbl.text = msg if msg != "" else "-"
	msg_lbl.custom_minimum_size = Vector2(230, 0)
	msg_lbl.add_theme_font_size_override("font_size", 16)
	msg_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	row.add_child(msg_lbl)

	var wave_lbl := Label.new()
	wave_lbl.text = "%d웨이브" % int(entry.get("wave", 0))
	wave_lbl.add_theme_font_size_override("font_size", 16)
	wave_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	row.add_child(wave_lbl)

	return row


func _on_close() -> void:
	closed.emit()
	queue_free()
