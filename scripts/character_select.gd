extends Control
## Start screen: pick a character (photo + ability), then press START to play.

var _chars: Array = []
var _cards: Array = []
var _selected: int = 0


func _ready() -> void:
	_chars = Characters.all()
	_selected = Characters.index_of(GameState.selected_character_id)
	_build_ui()
	_refresh_selection()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.96, 0.96, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	margin.add_child(col)

	var title := Label.new()
	title.text = "JAE AGAIN"
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color.BLACK)
	col.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(row)

	for i in _chars.size():
		row.add_child(_make_card(_chars[i], i))

	var start := Button.new()
	start.text = "START"
	start.add_theme_font_size_override("font_size", 40)
	start.custom_minimum_size = Vector2(380, 88)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_on_start_pressed)
	col.add_child(start)


func _make_card(c: Dictionary, index: int) -> Button:
	var card := Button.new()
	card.toggle_mode = true
	card.custom_minimum_size = Vector2(230, 380)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pressed.connect(func() -> void: _on_card_pressed(index))
	_cards.append(card)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_top = 12
	box.offset_right = -12
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var name_lbl := Label.new()
	name_lbl.text = c["name"]
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_lbl)

	var pic := TextureRect.new()
	pic.texture = load(c["texture"])
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(0, 200)
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)

	var desc := Label.new()
	desc.text = c["ability"]
	desc.add_theme_font_size_override("font_size", 15)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc)

	return card


func _on_card_pressed(index: int) -> void:
	_selected = index
	_refresh_selection()


func _refresh_selection() -> void:
	for i in _cards.size():
		var picked := i == _selected
		_cards[i].button_pressed = picked
		_cards[i].modulate = Color(0.62, 0.82, 1.0) if picked else Color.WHITE


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
