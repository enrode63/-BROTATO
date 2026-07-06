extends Control
## 접속 화면. 서버 주소와 방 코드를 입력하고 접속한다.
## 화면 요소는 코드로 만든다(.tscn 최소화).

var _url: LineEdit
var _room: LineEdit
var _btn: Button
var _status: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.11, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	var title := Label.new()
	title.text = "ROUNDS 온라인 대전"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	vb.add_child(_make_label("서버 주소"))
	_url = LineEdit.new()
	_url.text = "ws://localhost:9000"
	_url.custom_minimum_size = Vector2(360, 0)
	vb.add_child(_url)

	vb.add_child(_make_label("방 코드 (친구와 똑같이)"))
	_room = LineEdit.new()
	_room.text = "1234"
	_room.custom_minimum_size = Vector2(360, 0)
	vb.add_child(_room)

	_btn = Button.new()
	_btn.text = "접속하기"
	_btn.pressed.connect(_on_connect_pressed)
	vb.add_child(_btn)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_status)

	Net.connected.connect(_on_connected)
	Net.closed.connect(_on_closed)


func _make_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _on_connect_pressed() -> void:
	_status.text = "접속 중... 친구를 기다리는 중"
	_btn.disabled = true
	Net.start(_url.text.strip_edges(), _room.text.strip_edges())


func _on_connected() -> void:
	get_tree().change_scene_to_file("res://scenes/arena.tscn")


func _on_closed() -> void:
	_status.text = "연결 실패/끊김. 서버 주소·방 코드를 확인하세요."
	_btn.disabled = false
