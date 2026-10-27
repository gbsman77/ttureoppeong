extends Node2D
## 하수구 배경: 벽돌 벽, 파이프, 보스가 나오는 큰 하수구 굴, 원근감 있는 바닥.

const DU = preload("res://scripts/draw_util.gd")

var main


func _draw():
	var t = main.t
	var ft = main.FLOOR_TOP
	var bgt = DU.tex("bg/bg_sewer")
	if bgt != null:
		draw_texture_rect(bgt, Rect2(0, 0, 960, 540), false)
		if main.state == "boss_warn" and int(main.t * 6.0) % 2 == 0:
			for sx in [-1.0, 1.0]:
				DU.ellipse(self, Vector2(515 + sx * 34, 235), 13, 8, Color("ff3b2f"))
				DU.ellipse(self, Vector2(515 + sx * 34, 235), 6, 4, Color("ffd0c0"))
		return
	# 벽
	draw_rect(Rect2(0, 0, 960, ft), Color("35514d"))
	var brick = Color("2a403d")
	var row = 0
	for y in range(0, int(ft), 22):
		draw_line(Vector2(0, y), Vector2(960, y), brick, 2.0)
		var off = 0 if row % 2 == 0 else 24
		for x in range(off, 960, 48):
			draw_line(Vector2(x, y), Vector2(x, min(y + 22, ft)), brick, 2.0)
		row += 1
	# 큰 하수구 굴
	var tc = Vector2(480, ft)
	draw_colored_polygon(DU.ell_pts(tc, 168, 124, 32, PI, TAU), Color("6d7c78"))
	draw_colored_polygon(DU.ell_pts(tc, 150, 110, 32, PI, TAU), Color("141c1b"))
	for i in 9:
		var a = PI + i * PI / 8.0
		draw_line(tc + Vector2(cos(a) * 150, sin(a) * 110), tc + Vector2(cos(a) * 168, sin(a) * 124), Color("4b5855"), 3.0)
	if main.state == "boss_warn":
		# 굴 속에서 번쩍이는 눈
		if int(main.t * 6.0) % 2 == 0:
			DU.ellipse(self, tc + Vector2(-34, -50), 12, 8, Color("ff3b2f"))
			DU.ellipse(self, tc + Vector2(34, -50), 12, 8, Color("ff3b2f"))
	# 굴에서 흘러나오는 오물
	var sludge = Color(0.45, 0.35, 0.12, 0.9)
	draw_colored_polygon(PackedVector2Array([tc + Vector2(-120, 0), tc + Vector2(120, 0), tc + Vector2(150, 28), tc + Vector2(-150, 28)]), sludge)
	# 파이프
	var pipe = Color("5f8f5a")
	var pipe_d = Color("3f6a3b")
	draw_rect(Rect2(0, 30, 960, 20), pipe_d)
	draw_rect(Rect2(0, 32, 960, 14), pipe)
	for x in [120.0, 840.0]:
		draw_rect(Rect2(x - 12, 30, 24, ft - 30), pipe_d)
		draw_rect(Rect2(x - 9, 30, 18, ft - 30), pipe)
		draw_rect(Rect2(x - 16, 60, 32, 10), pipe_d)
		draw_rect(Rect2(x - 16, ft - 22, 32, 10), pipe_d)
		var dy = fmod(t * 120.0 + x, 160.0)
		DU.ellipse(self, Vector2(x + 18, 50 + dy), 3, 5, Color(0.6, 0.8, 0.5, 1.0 - dy / 160.0))
	for x in [300.0, 660.0]:
		draw_rect(Rect2(x - 22, 26, 10, 28), pipe_d)
	# 바닥
	var fb = 540.0
	var bands = 10
	for i in bands:
		var y0 = ft + (fb - ft) * pow(float(i) / bands, 1.5)
		var y1 = ft + (fb - ft) * pow(float(i + 1) / bands, 1.5)
		var c = Color("56634f").lerp(Color("7d8b70"), float(i) / bands)
		draw_rect(Rect2(0, y0, 960, y1 - y0 + 1), c)
		draw_line(Vector2(0, y0), Vector2(960, y0), Color(0, 0, 0, 0.18), 1.5)
	for i in range(-8, 17):
		var xb = 480.0 + i * 120.0 - 480.0
		var xt = 480.0 + (xb - 480.0) * 0.32
		draw_line(Vector2(xt, ft), Vector2(xb, fb), Color(0, 0, 0, 0.15), 1.5)
	# 웅덩이
	var puddles = [[Vector2(250, 250), 60.0], [Vector2(720, 320), 80.0], [Vector2(420, 380), 50.0]]
	for pd in puddles:
		var s = main.depth_scale(pd[0].y)
		DU.ellipse(self, pd[0], pd[1] * s, 12.0 * s, Color(0.35, 0.5, 0.42, 0.6))
		var hx = sin(t * 2.0 + pd[0].x) * pd[1] * 0.3 * s
		DU.ellipse(self, pd[0] + Vector2(hx, -2), 12.0 * s, 2.5 * s, Color(1, 1, 1, 0.35))
	# 천장 쪽 어둡게
	draw_rect(Rect2(0, 0, 960, 14), Color(0, 0, 0, 0.35))
