class_name RoundPortrait
extends Control
## 매치 안에서 라운드를 이길 때마다 내 캐릭터(또는 상대 캐릭터) 그림이
## 아래에서부터 절반씩 채워지는 표시. Rounds 원작의 "승수만큼 캐릭터가
## 채워지는" 연출을 텍스처 리빌 방식으로 구현한다.

var _tex: Texture2D = null
var _fill: float = 0.0   ## 0.0~1.0


func setup(tex_path: String) -> void:
	_tex = load(tex_path)
	custom_minimum_size = Vector2(56, 78)
	queue_redraw()


## frac: 0.0(무승) ~ 1.0(매치 승리 확정) 사이 값.
func set_fill(frac: float) -> void:
	_fill = clampf(frac, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if not _tex:
		return
	var box := size
	var tex_size := _tex.get_size()
	var s := minf(box.x / tex_size.x, box.y / tex_size.y)
	var draw_size := tex_size * s
	var offset := (box - draw_size) / 2.0

	# 아직 못 채운 부분 - 어두운 실루엣
	draw_texture_rect(_tex, Rect2(offset, draw_size), false, Color(0.15, 0.15, 0.18, 0.9))

	if _fill <= 0.0:
		return

	# 이긴 만큼 아래쪽부터 원래 색으로 다시 그려서 "차오르는" 느낌을 낸다.
	var fill_h := draw_size.y * _fill
	var dest := Rect2(offset.x, offset.y + draw_size.y - fill_h, draw_size.x, fill_h)
	var src := Rect2(0, tex_size.y * (1.0 - _fill), tex_size.x, tex_size.y * _fill)
	draw_texture_rect_region(_tex, dest, src)
