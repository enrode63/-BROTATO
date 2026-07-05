extends Control
## Start screen: pick a character (photo + ability), then press START to play.
## Styled with gradient background, rounded accent cards, and a big START button.

const FONT_DISPLAY := "res://fonts/BlackHanSans-Regular.ttf"
const FONT_BODY := "res://fonts/GothicA1-Regular.ttf"

var _chars: Array = []
var _cards: Array = []
var _selected: int = 0
var _font_display: Font
var _font_body: Font


func _ready() -> void:
	_font_display = load(FONT_DISPLAY)
	_font_body = load(FONT_BODY)
	_chars = Characters.all()
	_selected = Characters.index_of(GameState.selected_character_id)
	_build_ui()
	_refresh_selection()


func _build_ui() -> void:
	_build_background()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	margin.add_child(col)

	col.add_child(_build_title())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(row)
	for i in _chars.size():
		row.add_child(_make_card(_chars[i], i))

	col.add_child(_build_start_button())


func _build_background() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0.16, 0.18, 0.27))
	grad.set_color(1, Color(0.06, 0.07, 0.11))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)


func _build_title() -> Control:
	var wrap := HBoxContainer.new()
	var accent := ColorRect.new()
	accent.color = Color(1.0, 0.42, 0.32)
	accent.custom_minimum_size = Vector2(10, 56)
	wrap.add_child(accent)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(16, 0)
	wrap.add_child(spacer)
	var title := Label.new()
	title.text = "JAE AGAIN"
	title.add_theme_font_override("font", _font_display)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(title)
	return wrap


func _make_card(c: Dictionary, index: int) -> Button:
	var accent: Color = c["accent"]

	var card := Button.new()
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(250, 400)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	card.add_theme_stylebox_override("normal", _card_style(Color(0.16, 0.18, 0.26, 0.95), Color(1, 1, 1, 0.10), 2))
	card.add_theme_stylebox_override("hover", _card_style(Color(0.20, 0.22, 0.31, 0.98), Color(1, 1, 1, 0.28), 2))
	var sel := _card_style(Color(0.20, 0.23, 0.33, 1.0), accent, 4)
	sel.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
	sel.shadow_size = 18
	card.add_theme_stylebox_override("pressed", sel)
	card.pressed.connect(func() -> void: _on_card_pressed(index))
	_cards.append(card)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 14
	box.offset_right = -14
	box.offset_bottom = -14
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	# name banner
	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = accent
	bsb.set_corner_radius_all(9)
	bsb.content_margin_top = 4
	bsb.content_margin_bottom = 4
	banner.add_theme_stylebox_override("panel", bsb)
	var name_lbl := Label.new()
	name_lbl.text = c["name"]
	name_lbl.add_theme_font_override("font", _font_display)
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color(0.08, 0.09, 0.12))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(name_lbl)
	box.add_child(banner)

	# photo
	var pic := TextureRect.new()
	pic.texture = load(c["texture"])
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(0, 210)
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)

	# ability title
	var atitle := Label.new()
	atitle.text = "[ %s ]" % c["ability_title"]
	atitle.add_theme_font_override("font", _font_display)
	atitle.add_theme_font_size_override("font_size", 19)
	atitle.add_theme_color_override("font_color", accent)
	atitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(atitle)

	# ability description
	var desc := Label.new()
	desc.text = c["ability_desc"]
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.82, 0.85, 0.92))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc)

	return card


func _card_style(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(18)
	s.set_border_width_all(border_w)
	s.border_color = border
	return s


func _build_start_button() -> Button:
	var start := Button.new()
	start.text = "START"
	start.focus_mode = Control.FOCUS_NONE
	start.add_theme_font_override("font", _font_display)
	start.add_theme_font_size_override("font_size", 42)
	start.add_theme_color_override("font_color", Color(0.1, 0.06, 0.03))
	start.add_theme_color_override("font_hover_color", Color(0.1, 0.06, 0.03))
	start.add_theme_color_override("font_pressed_color", Color(0.1, 0.06, 0.03))
	start.custom_minimum_size = Vector2(400, 92)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var base := Color(1.0, 0.62, 0.24)
	start.add_theme_stylebox_override("normal", _button_style(base, 0))
	var hov := _button_style(base.lightened(0.12), 22)
	hov.shadow_color = Color(base.r, base.g, base.b, 0.6)
	start.add_theme_stylebox_override("hover", hov)
	start.add_theme_stylebox_override("pressed", _button_style(base.darkened(0.12), 0))
	start.pressed.connect(_on_start_pressed)
	return start


func _button_style(bg: Color, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(16)
	s.shadow_size = shadow
	return s


func _on_card_pressed(index: int) -> void:
	_selected = index
	_refresh_selection()


func _refresh_selection() -> void:
	for i in _cards.size():
		_cards[i].button_pressed = i == _selected


func _on_start_pressed() -> void:
	GameState.selected_character_id = _chars[_selected]["id"]
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				_selected = (_selected - 1 + _cards.size()) % _cards.size()
				_refresh_selection()
			KEY_RIGHT, KEY_D:
				_selected = (_selected + 1) % _cards.size()
				_refresh_selection()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_on_start_pressed()
