extends Control
## 게임 시작 전 플레이 방식(컴퓨터 / 모바일)을 선택하는 화면.

func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var font_d := load("res://fonts/BlackHanSans-Regular.ttf") as Font

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "BROTATO"
	title.add_theme_font_override("font", font_d)
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.95, 0.30, 0.20))
	title.add_theme_constant_override("outline_size", 9)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 110
	add_child(title)

	var sub := Label.new()
	sub.text = "플레이 방식을 선택하세요"
	sub.add_theme_font_override("font", font_d)
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.60, 0.66, 0.80))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.position.y = 240
	add_child(sub)

	_make_card(font_d, "컴퓨터 플레이", "키보드 + 마우스", false, Vector2(186, 295))
	_make_card(font_d, "모바일 플레이", "터치 조이스틱", true,  Vector2(626, 295))

	var rank_btn := Button.new()
	rank_btn.text = "🏆 랭킹 보기"
	rank_btn.add_theme_font_override("font", font_d)
	rank_btn.add_theme_font_size_override("font_size", 20)
	rank_btn.size = Vector2(180, 46)
	rank_btn.position = Vector2((1152.0 - 180.0) / 2.0, 560.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.20, 0.10)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.95, 0.75, 0.25)
	rank_btn.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.32, 0.29, 0.14)
	rank_btn.add_theme_stylebox_override("hover", sbh)
	rank_btn.add_theme_stylebox_override("pressed", sbh)
	rank_btn.pressed.connect(func(): add_child(RankingScreen.new()))
	add_child(rank_btn)


func _make_card(font_d: Font, label: String, desc: String, mobile: bool, pos: Vector2) -> void:
	var accent := Color(0.38, 0.58, 1.0) if not mobile else Color(0.32, 0.92, 0.58)

	var card := Panel.new()
	card.position = pos
	card.size = Vector2(340, 230)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.13, 0.20)
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(3)
	sb.border_color = accent
	card.add_theme_stylebox_override("panel", sb)
	add_child(card)

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.add_theme_font_override("font", font_d)
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", accent)
	name_lbl.add_theme_constant_override("outline_size", 5)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	name_lbl.position.y = 40
	card.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 19)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.74))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	desc_lbl.position.y = 98
	card.add_child(desc_lbl)

	var btn := Button.new()
	btn.text = "선택"
	btn.add_theme_font_override("font", font_d)
	btn.add_theme_font_size_override("font_size", 22)
	btn.size = Vector2(260, 52)
	btn.position = Vector2(40, 154)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = accent.darkened(0.45)
	bsb.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", bsb)
	var bsb_h := bsb.duplicate() as StyleBoxFlat
	bsb_h.bg_color = accent.darkened(0.20)
	btn.add_theme_stylebox_override("hover", bsb_h)
	btn.add_theme_stylebox_override("pressed", bsb_h)
	btn.pressed.connect(_on_select.bind(mobile))
	card.add_child(btn)


func _on_select(mobile: bool) -> void:
	GameState.is_mobile = mobile
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
