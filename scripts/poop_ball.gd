extends Node2D
## 똥괴물이 던지는 똥 덩어리. 화면 앞쪽으로 커지며 날아와 주인공 줄에 떨어진다.
## 뚜러뻥으로 맞혀서 공중에서 터뜨릴 수 있다.

const DU = preload("res://scripts/draw_util.gd")

var main
var from = Vector2.ZERO
var target = Vector2.ZERO
var pos = Vector2.ZERO
var s0 = 0.5
var sc = 0.5
var t = 0.0
var dur = 1.1
var spin = 0.0
var kind = ""  # "" 보통 똥 / "green" 녹색똥 / "rainbow" 무지개똥
var tex_name = "props/poop_ball"


func setup(m, f: Vector2, to: Vector2, start_scale: float, flight: float, k: String = ""):
	main = m
	kind = k
	if kind != "":
		tex_name = "props/poop_ball_" + kind
		if DU.tex(tex_name) == null:
			# 전용 그림이 없으면 보통 똥 그림의 색을 바꾼다
			tex_name = "props/poop_ball"
			material = DU.recolor(kind)
	from = f
	target = to
	s0 = start_scale
	dur = flight
	pos = from
	sc = s0


func hit_test(p: Vector2) -> bool:
	return p.distance_to(pos) < 16.0 * sc + 14.0


func tick(delta: float):
	t += delta
	var k = min(t / dur, 1.0)
	pos = from.lerp(target, k) + Vector2(0, -sin(k * PI) * 110.0 * (1.0 - k * 0.4))
	sc = lerp(s0, 1.35, k * k)
	spin += delta * 7.0
	queue_redraw()
	if k >= 1.0:
		queue_free()
		main.ball_land(self)


func pop(award: bool):
	if is_queued_for_deletion():
		return
	main.fx.burst(pos, _color(), 8, 160.0)
	if award:
		main.score += 10
		main.fx.text(pos, "팡!", Color("ffe08a"), 22, 0.5)
		Sfx.play("splat", 1.6, -3.0)
	queue_free()


func _color() -> Color:
	match kind:
		"green":
			return Color("6bbf3a")
		"rainbow":
			return Color.from_hsv(randf(), 0.7, 1.0)
		"gold":
			return Color("ffc83d")
		"ketchup":
			return Color("e2231a")
	return Color("7a4a1e")


func _draw():
	var k = min(t / dur, 1.0)
	# 떨어질 자리에 그림자 (피할 수 있게)
	DU.ellipse(self, target + Vector2(0, 50), 26.0 * k + 4.0, 7.0 * k + 1.0, Color(0, 0, 0, 0.18 + 0.25 * k))
	var r = 16.0 * sc
	var t = DU.tex(tex_name)
	if t != null:
		DU.quad(self, t, Transform2D(spin, pos), Rect2(-r - 2, -r - 2, 2 * r + 4, 2 * r + 4))
		return
	draw_circle(pos, r + 2.5, Color("3d230c"))
	draw_circle(pos, r, Color("7a4a1e"))
	draw_arc(pos, r * 0.55, spin, spin + 4.0, 12, Color("5a3414"), 3.0 * sc + 1.0)
	draw_circle(pos + Vector2(-r * 0.35, -r * 0.4), r * 0.22, Color("a87443"))
