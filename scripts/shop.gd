class_name Shop
extends CanvasLayer
## Between-wave shop: buy stat upgrades / health / weapons, reroll the offers,
## merge duplicate weapons in the inventory, then press 이동 for the next wave.

signal continue_pressed

const REROLL_PRICES := [10, 30, 50, 100, 200, 300]
const STAT_ITEMS := [
	{"id": "hand", "name": "손", "desc": "데미지 +3%"},
	{"id": "lung", "name": "폐", "desc": "최대 체력 +2"},
	{"id": "leg", "name": "다리", "desc": "이동속도 +3%"},
	{"id": "back", "name": "등", "desc": "방어력 +1"},
	{"id": "eye", "name": "눈", "desc": "사거리 +1"},
]
const WEAPON_ITEMS := [
	{"id": "cucumber", "name": "우람한 오이", "desc": "관통 원거리 창", "icon": "res://assets/weapon_cucumber.png"},
	{"id": "cards", "name": "트페의 카드", "desc": "랜덤 카드 효과", "icon": "res://assets/weapon_cards.png"},
	{"id": "cutter", "name": "시운이의 커터칼", "desc": "근접 광역", "icon": "res://assets/weapon_cutter.png"},
	{"id": "camera", "name": "카메라", "desc": "샷건 광역", "icon": "res://assets/weapon_camera.png"},
]

var _player: Player
var _wave: int = 1
var _offers: Array = []
var _font_display: Font

var _gold_label: Label
var _reroll_btn: Button
var _cards_row: HBoxContainer
var _inv_row: HBoxContainer
var _stats_label: Label


func setup(player: Player, wave: int) -> void:
	_player = player
	_wave = wave


func _ready() -> void:
	layer = 10
	_font_display = load("res://fonts/BlackHanSans-Regular.ttf")
	GameState.reroll_count = 0  # reroll price resets every shop visit
	_generate_offers()
	_build_ui()
	_rebuild_cards()
	_rebuild_inventory()
	_refresh()


# --- offers ------------------------------------------------------------------

func _generate_offers() -> void:
	_offers.clear()
	for i in 4:
		_offers.append(_random_offer())


func _random_offer() -> Dictionary:
	var r := randf()
	if r < 0.18 and _player.weapons.size() < Player.MAX_WEAPONS:
		var w: Dictionary = WEAPON_ITEMS.pick_random()
		return {"kind": "weapon", "id": w["id"], "name": w["name"], "desc": w["desc"],
			"icon": w["icon"], "price": _halve(42 + _wave * 4 + randi() % 16), "sold": false}
	elif r < 0.32:
		return {"kind": "heal", "id": "heal", "name": "체력 회복", "desc": "HP 25% 회복",
			"icon": "res://assets/stat_heal.png", "price": _halve(22 + _wave * 2), "sold": false}
	var s: Dictionary = STAT_ITEMS.pick_random()
	return {"kind": "stat", "id": s["id"], "name": s["name"], "desc": s["desc"],
		"icon": "res://assets/stat_%s.png" % s["id"], "price": _halve(14 + _wave * 3 + randi() % 10), "sold": false}


func _halve(v: int) -> int:
	return max(1, int(round(float(v) * 0.5)))


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11, 0.99)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var title := Label.new()
	title.text = "상점 (웨이브 %d)" % _wave
	title.add_theme_font_override("font", _font_display)
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(40, 22)
	root.add_child(title)

	var coin := TextureRect.new()
	coin.texture = load("res://assets/coin.png")
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.position = Vector2(360, 24)
	coin.size = Vector2(32, 32)
	root.add_child(coin)

	_gold_label = Label.new()
	_gold_label.add_theme_font_override("font", _font_display)
	_gold_label.add_theme_font_size_override("font_size", 27)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_gold_label.position = Vector2(398, 24)
	root.add_child(_gold_label)

	_reroll_btn = Button.new()
	_reroll_btn.add_theme_font_override("font", _font_display)
	_reroll_btn.add_theme_font_size_override("font_size", 20)
	_reroll_btn.position = Vector2(636, 20)
	_reroll_btn.size = Vector2(220, 42)
	_reroll_btn.pressed.connect(_on_reroll)
	root.add_child(_reroll_btn)

	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 16)
	_cards_row.position = Vector2(40, 84)
	root.add_child(_cards_row)

	# inventory (bottom-left)
	var inv_title := Label.new()
	inv_title.text = "인벤토리 (보유 무기 · 같은 무기 2개 드래그하면 합성)"
	inv_title.add_theme_font_size_override("font_size", 17)
	inv_title.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	inv_title.position = Vector2(40, 470)
	root.add_child(inv_title)

	_inv_row = HBoxContainer.new()
	_inv_row.add_theme_constant_override("separation", 10)
	_inv_row.position = Vector2(40, 500)
	root.add_child(_inv_row)

	# stats panel (right)
	var panel := Panel.new()
	panel.position = Vector2(884, 84)
	panel.size = Vector2(228, 476)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.12, 0.14, 0.19, 1.0)
	psb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", psb)
	root.add_child(panel)

	var stitle := Label.new()
	stitle.text = "능력치"
	stitle.add_theme_font_override("font", _font_display)
	stitle.add_theme_font_size_override("font_size", 22)
	stitle.position = Vector2(16, 12)
	panel.add_child(stitle)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 17)
	_stats_label.position = Vector2(16, 52)
	_stats_label.size = Vector2(200, 400)
	panel.add_child(_stats_label)

	var cont := Button.new()
	cont.text = "이동 ▶"
	cont.add_theme_font_override("font", _font_display)
	cont.add_theme_font_size_override("font_size", 26)
	cont.position = Vector2(884, 574)
	cont.size = Vector2(228, 54)
	cont.pressed.connect(_on_continue)
	root.add_child(cont)


func _rebuild_cards() -> void:
	for c in _cards_row.get_children():
		c.queue_free()
	for i in _offers.size():
		_cards_row.add_child(_make_card(i))


func _make_card(index: int) -> Panel:
	var o: Dictionary = _offers[index]
	var accent := _kind_color(o["kind"])

	var card := Panel.new()
	card.custom_minimum_size = Vector2(196, 366)
	card.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.16, 0.22, 1.0)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = accent
	card.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_top = 12
	box.offset_right = -12
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var name_lbl := Label.new()
	name_lbl.text = o["name"]
	name_lbl.add_theme_font_override("font", _font_display)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", accent)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_lbl)

	var art := TextureRect.new()
	art.texture = load(o["icon"]) if o["icon"] != "" else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(0, 150)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(art)

	var desc := Label.new()
	desc.text = o["desc"]
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.82, 0.85, 0.92))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)

	var buy := Button.new()
	buy.add_theme_font_override("font", _font_display)
	buy.add_theme_font_size_override("font_size", 18)
	buy.custom_minimum_size = Vector2(0, 40)
	buy.pressed.connect(_on_buy.bind(index))
	box.add_child(buy)
	o["_btn"] = buy

	return card


func _rebuild_inventory() -> void:
	for c in _inv_row.get_children():
		c.queue_free()
	for i in _player.weapons.size():
		var w: Weapon = _player.weapons[i]
		var slot := WeaponSlot.new()
		_inv_row.add_child(slot)
		slot.setup(self, i, w.icon_path, w.level)


func _kind_color(kind: String) -> Color:
	match kind:
		"weapon": return Color(0.95, 0.55, 0.30)
		"heal": return Color(0.35, 0.85, 0.45)
		_: return Color(0.55, 0.65, 1.0)


# --- actions -----------------------------------------------------------------

func _on_buy(index: int) -> void:
	var o: Dictionary = _offers[index]
	if o.get("sold", false):
		return
	if o["kind"] == "weapon" and _player.weapons.size() >= Player.MAX_WEAPONS:
		return
	if not GameState.spend(int(o["price"])):
		return
	if o["kind"] == "weapon":
		_player.add_weapon(_player.make_weapon(o["id"]))
		_rebuild_inventory()
	else:
		_player.apply_upgrade(o["id"])
	o["sold"] = true
	_refresh()


func _on_reroll() -> void:
	if not GameState.spend(_reroll_price()):
		return
	GameState.reroll_count += 1
	_generate_offers()
	_rebuild_cards()
	_refresh()


func try_merge(from_idx: int, to_idx: int) -> void:
	if _player.merge_weapons(from_idx, to_idx):
		_rebuild_inventory()
		_refresh()


func _on_continue() -> void:
	continue_pressed.emit()
	queue_free()


func _reroll_price() -> int:
	return REROLL_PRICES[min(GameState.reroll_count, REROLL_PRICES.size() - 1)]


func _refresh() -> void:
	_gold_label.text = str(GameState.gold)
	_reroll_btn.text = "초기화 - %d" % _reroll_price()
	_reroll_btn.disabled = GameState.gold < _reroll_price()
	for o in _offers:
		var btn: Button = o.get("_btn")
		if btn == null:
			continue
		if o.get("sold", false):
			btn.text = "완료"
			btn.disabled = true
		else:
			btn.text = "구매 %d" % int(o["price"])
			btn.disabled = GameState.gold < int(o["price"])
	_update_stats()


func _update_stats() -> void:
	_stats_label.text = "\n".join([
		"최대 HP      %d" % _player.max_health,
		"데미지       +%d%%" % int(_player.stat_damage_pct),
		"이동속도     +%d%%" % int(_player.stat_speed_pct),
		"방어력       %d" % _player.stat_armor,
		"사거리       +%d" % int(_player.stat_range / 12.0),
		"",
		"무기         %d / %d" % [_player.weapons.size(), Player.MAX_WEAPONS],
		"경험치       %d" % GameState.xp,
	])
