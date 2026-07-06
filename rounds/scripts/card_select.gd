class_name CardSelect
extends Control
## 라운드 패배 시 뜨는 카드 선택 화면.
## 화면 아래쪽에 내가 고른 캐릭터 초상화, 위쪽에 카드 3장(버튼)을 보여준다.
## 카드를 클릭하면 card_chosen 시그널을 보낸다.

signal card_chosen(id: String)


func setup(cards: Array, portrait_tex: Texture2D) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 내가 고른 캐릭터 초상화 (화면 아래쪽 중앙)
	var portrait := TextureRect.new()
	portrait.texture = portrait_tex
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(170, 170)
	portrait.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	portrait.position -= Vector2(85, 210)
	add_child(portrait)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 24)
	add_child(vb)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 70)
	vb.add_child(top_spacer)

	var title := Label.new()
	title.text = "매치 패배 — 능력치 카드 선택"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	vb.add_child(row)

	for c in cards:
		row.add_child(_make_card_button(c))


func _make_card_button(c: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 260)
	btn.pressed.connect(func(): card_chosen.emit(c["id"]))

	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 12)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)

	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 20)
	top_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(top_pad)

	var name_l := Label.new()
	name_l.text = c["name"]
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(name_l)

	var desc_l := Label.new()
	desc_l.text = c["desc"]
	desc_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_l.custom_minimum_size = Vector2(180, 0)
	desc_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(desc_l)

	return btn
