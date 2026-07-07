class_name Shop
extends CanvasLayer
## Between-wave shop: buy stat upgrades / health / weapons, reroll the offers,
## merge duplicate weapons in the inventory, then press 이동 for the next wave.

signal continue_pressed

const REROLL_PRICES := [10, 30, 50, 100, 200, 300]
const STAT_ITEMS := [
	{"id": "tricep", "name": "삼두근", "desc": "데미지 +5%", "icon": "res://assets/stat_tricep.png"},
	{"id": "leg", "name": "다리", "desc": "이동속도 +3%", "icon": "res://assets/stat_leg2.png"},
	{"id": "heart", "name": "심장", "desc": "최대 체력 +5%", "icon": "res://assets/stat_heart.png"},
	{"id": "spine", "name": "척추", "desc": "방어력 +1", "icon": "res://assets/stat_spine.png"},
	{"id": "tooth", "name": "이빨", "desc": "흡혈 +1%", "icon": "res://assets/stat_tooth.png"},
	{"id": "monkey", "name": "쌀숭이", "desc": "추가 골드 +1", "icon": "res://assets/stat_monkey.png"},
]
const WEAPON_ITEMS := [
	{"id": "cucumber", "name": "우람한 오이", "desc": "관통 원거리 창", "icon": "res://assets/weapon_cucumber.png"},
	{"id": "cards", "name": "트페의 카드", "desc": "랜덤 카드 효과", "icon": "res://assets/weapon_cards.png"},
	{"id": "cutter", "name": "시운이의 커터칼", "desc": "근접 광역", "icon": "res://assets/weapon_cutter.png"},
	{"id": "camera", "name": "캡챠해둘게요~", "desc": "부채꼴 스턴", "icon": "res://assets/weapon_camera.png"},
]
const THROWABLE_ITEMS := [
	{"id": "grenade", "name": "수류탄", "desc": "광역 폭발 (1키)", "icon": "res://assets/throw_grenade.png"},
	{"id": "flashbang", "name": "섬광탄", "desc": "전체 3초 속박 (2키)", "icon": "res://assets/throw_flash.png"},
	{"id": "molotov", "name": "화'염병'", "desc": "범위 지속 화염 (3키)", "icon": "res://assets/throw_molotov.png"},
]
const PET_ITEMS := [
	{"id": "yunho",   "name": "윤호 펫",  "desc": "주기적 광역 폭발 딜",   "icon": "res://assets/pet_yunho.png"},
	{"id": "jaehi",   "name": "재희 펫",  "desc": "근접 창 공격",           "icon": "res://assets/pet_jaehi.png"},
	{"id": "hyunjun", "name": "현준 펫",  "desc": "주변 적 최대 3마리 매혹", "icon": "res://assets/pet_hyunjun.png"},
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
	# Fixed slot layout: [무기, 무기, 투척물, 나머지, 나머지].
	_offers = [_weapon_offer(), _weapon_offer(), _throwable_offer(), _stat_offer(), _stat_offer()]


func _weapon_offer() -> Dictionary:
	var w: Dictionary = WEAPON_ITEMS.pick_random()
	return {"kind": "weapon", "id": w["id"], "name": w["name"], "desc": w["desc"],
		"icon": w["icon"], "price": _price(42, 4, 16), "sold": false}


func _throwable_offer() -> Dictionary:
	var t: Dictionary = THROWABLE_ITEMS.pick_random()
	return {"kind": "throwable", "id": t["id"], "name": t["name"], "desc": t["desc"],
		"icon": t["icon"], "amount": 2, "price": _price(28, 3, 10), "sold": false}


func _pet_offer() -> Dictionary:
	var p: Dictionary = PET_ITEMS.pick_random()
	var price: int = mini(2000, 500 * (_player.pets.size() + 1))
	return {"kind": "pet", "id": p["id"], "name": p["name"], "desc": p["desc"],
		"icon": p["icon"], "price": price, "sold": false}


func _stat_offer() -> Dictionary:
	# 3% 확률로 펫 등장 (최대 4마리까지)
	if _player.pets.size() < 4 and randf() < 0.03:
		return _pet_offer()
	if randf() < 0.16:
		return {"kind": "heal", "id": "heal", "name": "체력 회복", "desc": "HP 25% 회복",
			"icon": "res://assets/stat_heal.png", "price": _price(22, 2, 1), "sold": false}
	var pool: Array = []
	for item in STAT_ITEMS:
		if _stat_allowed(item):
			pool.append(item)
	if pool.is_empty():
		pool = STAT_ITEMS
	var s: Dictionary = pool.pick_random()
	return {"kind": "stat", "id": s["id"], "name": s["name"], "desc": s["desc"],
		"icon": s["icon"], "price": _price(14, 3, 10), "sold": false}


## 최대치에 도달한 능력치는 상점에서 제외 (쌀숭이/척추/이빨 = 5 max).
func _stat_allowed(item: Dictionary) -> bool:
	match item["id"]:
		"monkey": return _player.stat_bonus_gold < 5
		"spine": return _player.stat_armor < 5
		"tooth": return _player.stat_lifesteal < 5.0
	return true


## Base price, per-wave growth, and a small random spread — then halved (50% off).
## Prices climb as waves go on.
func _price(base: int, per_wave: int, spread: int) -> int:
	var raw: int = base + _wave * per_wave + (randi() % maxi(spread, 1))
	raw = int(round(float(raw) * (1.0 + 0.04 * float(_wave))))  # extra late-game growth
	return maxi(1, int(round(float(raw) * 0.5)))


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
	_cards_row.add_theme_constant_override("separation", 12)
	_cards_row.position = Vector2(36, 84)
	root.add_child(_cards_row)

	# inventory (bottom-left)
	var inv_title := Label.new()
	inv_title.text = "인벤토리 (같은 무기 2개 드래그 = 합성 · 무기 우클릭 = 50% 판매)"
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
	card.custom_minimum_size = Vector2(158, 366)
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
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", accent)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
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
	# throwables (non-draggable, show remaining count)
	for t in THROWABLE_ITEMS:
		var n := int(_player.throwable_counts.get(t["id"], 0))
		if n <= 0:
			continue
		_inv_row.add_child(_throwable_slot(t["icon"], n))
	# pets (non-draggable)
	for pet in _player.pets:
		if is_instance_valid(pet):
			_inv_row.add_child(_pet_inv_slot(pet))


func _throwable_slot(icon: String, count: int) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(66, 66)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.24, 0.15, 0.15, 1.0)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.95, 0.4, 0.35, 0.6)
	p.add_theme_stylebox_override("panel", sb)
	var art := TextureRect.new()
	art.texture = load(icon)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 6
	art.offset_top = 6
	art.offset_right = -6
	art.offset_bottom = -6
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(art)
	var cnt := Label.new()
	cnt.text = "x%d" % count
	cnt.add_theme_font_size_override("font_size", 14)
	cnt.add_theme_color_override("font_color", Color.WHITE)
	cnt.add_theme_constant_override("outline_size", 4)
	cnt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	cnt.position = Vector2(40, 44)
	cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(cnt)
	return p


func _pet_inv_slot(pet: Node2D) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(66, 66)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.10, 0.20, 1.0)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.98, 0.52, 0.98, 0.7)
	p.add_theme_stylebox_override("panel", sb)
	var tex_path: String = pet.get("texture_path") if "texture_path" in pet else ""
	if tex_path != "":
		var art := TextureRect.new()
		art.texture = load(tex_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.offset_left = 6; art.offset_top = 6
		art.offset_right = -6; art.offset_bottom = -6
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(art)
	return p


func _kind_color(kind: String) -> Color:
	match kind:
		"weapon": return Color(0.95, 0.55, 0.30)
		"throwable": return Color(0.95, 0.40, 0.35)
		"heal": return Color(0.35, 0.85, 0.45)
		"pet": return Color(0.98, 0.52, 0.98)
		_: return Color(0.55, 0.65, 1.0)


# --- actions -----------------------------------------------------------------

func _on_buy(index: int) -> void:
	var o: Dictionary = _offers[index]
	if o.get("sold", false):
		return
	if o["kind"] == "weapon" and not _player.can_acquire_weapon(o["id"]):
		return
	if not GameState.spend(int(o["price"])):
		return
	match o["kind"]:
		"weapon":
			_player.acquire_weapon(o["id"])
			_rebuild_inventory()
		"throwable":
			_player.add_throwable(o["id"], int(o.get("amount", 2)))
			_rebuild_inventory()
		"pet":
			_player.acquire_pet(o["id"])
		_:
			_player.apply_upgrade(o["id"])
	o["sold"] = true
	_refresh()


func sell_weapon(index: int) -> void:
	var value := _player.sell_weapon(index, _wave)
	if value > 0:
		GameState.add_gold(value)
		_rebuild_inventory()
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
		elif o["kind"] == "weapon" and not _player.can_acquire_weapon(o["id"]):
			btn.text = "슬롯 가득"
			btn.disabled = true
		elif o["kind"] == "pet" and _player.pets.size() >= 4:
			btn.text = "펫 가득"
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
		"흡혈         +%d%%" % int(_player.stat_lifesteal),
		"추가 골드    +%d" % _player.stat_bonus_gold,
		"",
		"무기         %d / %d" % [_player.weapons.size(), Player.MAX_WEAPONS],
		"펫           %d / 4" % _player.pets.size(),
		"경험치       %d" % GameState.xp,
	])
