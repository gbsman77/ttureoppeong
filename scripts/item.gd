extends Node2D
## 똥괴물이 떨어뜨리는 아이템. 뚜러뻥으로 맞히면 얻는다.
## 톡 튀어나와 반짝이며 둥실 떠 있다가 LIFE 초 뒤에 사라진다.

const DU = preload("res://scripts/draw_util.gd")
const LIFE = 9.0
const SIZE = 78.0

var main
var kind = "life"
var pos = Vector2.ZERO
var base = Vector2.ZERO
var t = 0.0


func setup(m, p: Vector2, k: String):
	main = m
	base = p
	pos = p
	kind = k
	Sfx.play("item", 1.5, -6.0)


func hit_test(p: Vector2) -> bool:
	return p.distance_to(pos) < 48.0


func collect():
	if is_queued_for_deletion():
		return
	if kind == "life":
		main.player.add_life()
		main.fx.text(pos, "휴지 +1!", Color("b9f5ff"), 30, 0.9)
	else:
		main.player.bombs = min(main.player.bombs + 1, 9)
		main.fx.text(pos, "왕뚜러뻥 +1!", Color("ffb3a8"), 30, 0.9)
	main.fx.sparks(pos, Color("ffe14d"), 12)
	Sfx.play("item")
	queue_free()


func tick(delta: float):
	t += delta
	# 처음엔 위로 톡 튀었다가, 그다음엔 좌우로 살랑살랑 둥실둥실
	var pop = -sin(min(t / 0.45, 1.0) * PI) * 50.0
	pos = base + Vector2(sin(t * 2.0) * 12.0, pop - min(t, 6.0) * 4.0 + sin(t * 4.0) * 5.0)
	if t > LIFE:
		queue_free()
	queue_redraw()


func _draw():
	if t > LIFE - 2.0 and int(t * 10.0) % 2 == 0:
		return
	var s = min(t / 0.25, 1.0) * (1.0 + sin(t * 6.0) * 0.06)
	var r = SIZE * 0.5 * s
	# 반짝이는 후광
	var glow = Color("fff2a0") if kind == "life" else Color("ffb3a8")
	glow.a = 0.35 + sin(t * 8.0) * 0.12
	draw_circle(pos, r + 10.0, glow)
	draw_arc(pos, r + 10.0, 0, TAU, 36, Color(1, 1, 1, 0.85), 3.0, true)
	for i in 4:
		var a = t * 2.5 + i * TAU / 4.0
		DU.star(self, pos + Vector2(cos(a), sin(a)) * (r + 18.0), 6.0, Color("ffe14d"))
	var tx = DU.tex("props/item_" + kind)
	if tx != null:
		draw_texture_rect(tx, Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0), false)
		return
	if kind == "life":
		DU.roll(self, pos + Vector2(0, -12), 26, 22)
	else:
		DU.plunger(self, pos + Vector2(0, 16), 0.3, 0.8)
