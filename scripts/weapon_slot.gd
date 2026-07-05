class_name WeaponSlot
extends Panel
## One weapon in the shop's bottom inventory. Draggable onto another slot to
## merge two identical weapons into a higher level.

var shop: Shop
var index: int = -1
var _tex_path: String = ""


func setup(shop_ref: Shop, idx: int, icon_path: String, level: int) -> void:
	shop = shop_ref
	index = idx
	_tex_path = icon_path
	custom_minimum_size = Vector2(66, 66)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.20, 0.27, 1.0)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.12)
	add_theme_stylebox_override("panel", sb)

	if icon_path != "":
		var art := TextureRect.new()
		art.texture = load(icon_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.offset_left = 6
		art.offset_top = 6
		art.offset_right = -6
		art.offset_bottom = -6
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)

	if level > 1:
		var lvl := Label.new()
		lvl.text = Weapon.roman(level)
		lvl.add_theme_font_size_override("font_size", 15)
		lvl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		lvl.add_theme_constant_override("outline_size", 4)
		lvl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lvl.position = Vector2(5, 2)
		lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lvl)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if index < 0:
		return null
	var preview := TextureRect.new()
	if _tex_path != "":
		preview.texture = load(_tex_path)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(56, 56)
	preview.size = Vector2(56, 56)
	set_drag_preview(preview)
	return {"from": index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("from")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if shop != null:
		shop.try_merge(int(data["from"]), index)
