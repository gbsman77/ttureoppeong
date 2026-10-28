extends Node2D
## 인트로(변기 속으로 다이빙)와 엔딩(쾌변! 변기가 펑 뚫림), 대승리 화면 연출.

const DU = preload("res://scripts/draw_util.gd")
const BOWL = Vector2(480, 348)
const WATER = Color("7ec8ef")
const LEGS_END = 2.7  # 변기 위로 다리가 버둥거리다 쏙 빨려 들어가는 시각
const INTRO_LEN = 4.6

var main
var mode = ""
var t = 0.0
var parts = []
var flyers = []
var flags = {}


func start(m: String):
	mode = m
	t = 0.0
	parts.clear()
	flyers.clear()
	flags.clear()
	visible = mode != ""
	queue_redraw()


func _once(key: String, at: float) -> bool:
	if t >= at and not flags.has(key):
		flags[key] = true
		return true
	return false


func _water(p: Vector2, n: int, spd: float, up: float = 1.0):
	for i in n:
		var a = randf_range(PI * 1.1, PI * 1.9)
		parts.append({"p": p, "v": Vector2(cos(a) * spd * randf_range(0.3, 1.0), sin(a) * spd * up * randf_range(0.5, 1.0)),
			"life": randf_range(0.6, 1.2), "col": Color(0.7, 0.9, 1.0), "r": randf_range(4, 8), "g": 900.0})


func _process(delta):
	if mode == "":
		return
	t += delta
	if mode == "intro":
		if _once("splash", 1.5):
			Sfx.play("splash")
			_water(BOWL, 30, 420)
		if _once("flush", LEGS_END):
			Sfx.play("flush")
			_water(BOWL, 16, 300)
	elif mode == "clear":
		if _once("rumble", 0.05):
			Sfx.play("rumble")
		if _once("pop", 1.1):
			Sfx.play("pop")
			Sfx.play("splash", 0.8)
			_water(BOWL, 50, 700, 1.4)
			for i in 6:
				flyers.append({"p": BOWL, "v": Vector2(randf_range(-420, 420), randf_range(-900, -600)),
					"rot": 0.0, "vr": randf_range(-8, 8), "kind": ["mini", "runner", "tank"][i % 3], "col": [Color("8b5a2b"), Color("bb853f"), Color("5a3818")][i % 3]})
		if _once("fanfare", 1.45):
			Sfx.play("fanfare")
		if t > 1.3 and randf() < 0.5:
			var cols = [Color("ff5a5a"), Color("ffd23f"), Color("5ad1ff"), Color("8cff7a"), Color("ff9be0")]
			parts.append({"p": Vector2(randf_range(0, 960), -10), "v": Vector2(randf_range(-40, 40), randf_range(80, 160)),
				"life": 4.0, "col": cols[randi() % cols.size()], "r": randf_range(3, 6), "g": 0.0})
		if t > 1.1 and t < 3.5:
			_water(BOWL + Vector2(randf_range(-25, 25), -300), 1, 300)
	elif mode == "victory":
		_victory_tick(delta)
	for q in parts:
		q.life -= delta
		q.v.y += q.g * delta
		q.p += q.v * delta
	parts = parts.filter(func(q): return q.life > 0.0)
	for f in flyers:
		f.v.y += 900.0 * delta
		f.p += f.v * delta
		f.rot += f.vr * delta
	queue_redraw()


func _draw():
	if mode == "intro":
		_draw_intro()
	elif mode == "clear":
		_draw_clear()
	elif mode == "victory":
		_draw_victory()


func _room(shake: Vector2, swirl: float, wc: Color):
	var bgt = DU.tex("bg/bg_bathroom")
	if bgt != null:
		draw_texture_rect(bgt, Rect2(0, 0, 960, 540), false)
	else:
		DU.bathroom(self)
	var tt = DU.tex("bg/toilet")
	if tt == null:
		DU.toilet(self, BOWL + shake, swirl, wc)
		return
	# 그림 속 물 웅덩이(가로 52%, 세로 59% 지점)가 BOWL 에 오도록
	var h = 300.0
	var w = h * tt.get_width() / tt.get_height()
	draw_texture_rect(tt, Rect2(BOWL + shake - Vector2(w * 0.52, h * 0.59), Vector2(w, h)), false)
	var wcol = wc
	wcol.a = 0.35 if wc != WATER else 0.0
	DU.ellipse(self, BOWL + shake, 44, 11, wcol)
	if swirl != 0.0:
		for arm in 3:
			var pts = PackedVector2Array()
			for i in 20:
				var a = swirl + i * 0.35 + arm * TAU / 3.0
				var r = 42.0 * (1.0 - i / 20.0)
				pts.append(BOWL + shake + Vector2(cos(a) * r, sin(a) * r * 0.27))
			draw_polyline(pts, Color(1, 1, 1, 0.8), 2.5, true)


func _hero_tex(name: String, pos: Vector2, rot: float, height: float) -> bool:
	var t = DU.tex("hero/hero_" + name)
	if t == null:
		return false
	var w = height * t.get_width() / t.get_height()
	DU.quad(self, t, Transform2D(rot, pos), Rect2(-w * 0.5, -height, w, height))
	return true


func _parts():
	for q in parts:
		draw_circle(q.p, q.r, q.col)


func _draw_intro():
	var swirl = 0.0
	var wc = WATER
	if t > LEGS_END:
		swirl = (t - LEGS_END) * 9.0
		wc = WATER.lerp(Color("4f8fb8"), min((t - LEGS_END) / 1.5, 1.0))
	_room(Vector2.ZERO, swirl, wc)
	if t < 0.9:
		var x = lerp(-60.0, 300.0, t / 0.9)
		if not _hero_tex("run_side", Vector2(x, 470 - abs(sin(t * 20.0)) * 8.0), 0.0, 130.0):
			draw_set_transform(Vector2(x, 470), 0.0, Vector2.ONE)
			DU.hero(self, Vector2(1, -1), t * 22.0, false, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif t < 1.5:
		var k = (t - 0.9) / 0.6
		var p = Vector2(300, 470).lerp(BOWL + Vector2(0, -20), k) + Vector2(0, -sin(k * PI) * 260.0)
		var sc = lerp(1.0, 0.6, k)
		if not _hero_tex("dive", p + Vector2(0, 50) * sc, k * 0.9, 110.0 * sc):
			draw_set_transform(p, k * PI, Vector2(sc, sc))
			DU.hero(self, Vector2(0, -1), 0.0, true, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif t < LEGS_END:
		_draw_legs()
	_parts()
	if t > 0.15 and t < 1.3:
		DU.text_c(self, Vector2(480, 70), "큰일이다! 하수구가 똥괴물 때문에 꽉 막혔다!", 34, Color.WHITE, 8)
	if t > 0.75 and t < 1.5:
		DU.text_c(self, Vector2(330, 290), "으랏차!", 40, Color("ffd23f"), 8)
	if t > 1.5 and t < 2.1:
		DU.text_c(self, Vector2(480, 130), "풍덩!", 64, Color("5ad1ff"), 10)
	if t > 1.8 and t < LEGS_END:
		DU.text_c(self, Vector2(640, 250 + sin(t * 20.0) * 4.0), "버둥버둥!", 34, Color.WHITE, 8)
	if t > LEGS_END + 0.2:
		DU.text_c(self, Vector2(480, 110), "슈와아아~ 하수구로 출동!", 44, Color.WHITE, 9)
	if t > INTRO_LEN - 0.9:
		var k = clamp((t - (INTRO_LEN - 0.9)) / 0.6, 0.0, 1.0)
		var r2 = lerp(1100.0, 0.0, k)
		draw_arc(BOWL, r2 + 700.0, 0, TAU, 72, Color.BLACK, 1400.0)
	DU.text_c(self, Vector2(880, 525), "누르면 건너뛰기", 16, Color(1, 1, 1, 0.7), 4)


## 변기 물 위로 쏙 솟은 주인공 다리. 파닥파닥 버둥거리다 마지막에 쏙 빨려 들어간다.
func _draw_legs():
	var u = t - 1.5
	var sink = clamp((t - (LEGS_END - 0.35)) / 0.35, 0.0, 1.0)
	var base = BOWL + Vector2(0, 4)
	var lt = DU.tex("hero/hero_legs")
	if lt != null:
		var h = 125.0 * (1.0 - sink * 0.9)
		var w = 125.0 * lt.get_width() / lt.get_height()
		var wig = sin(t * 26.0) * 0.08
		# 그림의 아래쪽(허리)부터 잘라서 물속으로 들어가는 것처럼
		var src = Rect2(0, 0, lt.get_width(), lt.get_height() * (1.0 - sink * 0.9))
		draw_set_transform(base, wig, Vector2.ONE)
		draw_texture_rect_region(lt, Rect2(-w * 0.5, -h, w, h), src)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var length = 78.0 * (1.0 - sink)
		for sx in [-1.0, 1.0]:
			var ang = sx * (0.28 + sin(u * 26.0 + sx) * 0.18)
			draw_set_transform(base + Vector2(sx * 8.0, 0), ang, Vector2.ONE)
			if length > 4.0:
				draw_rect(Rect2(-11, -length, 22, length), DU.INK)
				draw_rect(Rect2(-8.5, -length + 2, 17, length - 2), Color("2f6fd6"))
				draw_rect(Rect2(-8.5, -length + 2, 6, length - 2), Color("4f8ff0"))
				# 운동화 (밑창이 하늘을 향함)
				DU.ellipse(self, Vector2(sx * 4.0, -length - 4), 15, 10, DU.INK)
				DU.ellipse(self, Vector2(sx * 4.0, -length - 4), 12.5, 7.5, Color("8a4f22"))
				DU.ellipse(self, Vector2(sx * 4.0, -length - 9), 11, 4, Color("e9d8c0"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 허리가 잠긴 자리의 물보라
	for i in 5:
		var a = t * 9.0 + i * TAU / 5.0
		DU.ellipse(self, base + Vector2(cos(a) * 30.0, sin(a) * 6.0 - 2.0), 7, 4, Color(1, 1, 1, 0.85))
	if randf() < 0.4:
		parts.append({"p": base + Vector2(randf_range(-30, 30), -60.0 * (1.0 - sink)), "v": Vector2(randf_range(-120, 120), randf_range(-260, -120)),
			"life": 0.6, "col": Color(0.7, 0.9, 1.0), "r": randf_range(3, 6), "g": 900.0})


func _draw_clear():
	var sh = Vector2.ZERO
	if t < 1.1:
		sh = Vector2(sin(t * 70.0) * 4.0 * t, cos(t * 53.0) * 2.0 * t)
	_room(sh, t * 6.0 if t > 1.1 else 0.0, WATER)
	if t > 1.1:
		# 물기둥
		var k = min((t - 1.1) / 0.2, 1.0)
		var top = lerp(BOWL.y, -20.0, k)
		var w = lerp(80.0, 34.0, clamp((t - 1.3) / 2.0, 0.0, 1.0))
		var gt = DU.tex("bg/geyser")
		if gt != null:
			var gw = w * 2.6 + sin(t * 25.0) * 6.0
			draw_texture_rect(gt, Rect2(BOWL.x - gw * 0.5, top, gw, BOWL.y + 10 - top), false)
	if t > 1.1 and DU.tex("bg/geyser") == null:
		var k = min((t - 1.1) / 0.2, 1.0)
		var top = lerp(BOWL.y, -20.0, k)
		var w = lerp(80.0, 34.0, clamp((t - 1.3) / 2.0, 0.0, 1.0))
		var pts = PackedVector2Array()
		var n = 16
		for i in n + 1:
			var y = lerp(BOWL.y, top, float(i) / n)
			pts.append(Vector2(BOWL.x - w * 0.5 - sin(t * 20.0 + i) * 5.0, y))
		for i in range(n, -1, -1):
			var y = lerp(BOWL.y, top, float(i) / n)
			pts.append(Vector2(BOWL.x + w * 0.5 + sin(t * 17.0 + i * 1.3) * 5.0, y))
		draw_colored_polygon(pts, Color(0.55, 0.85, 1.0, 0.9))
		draw_line(Vector2(BOWL.x - w * 0.2, BOWL.y), Vector2(BOWL.x - w * 0.2, top), Color(1, 1, 1, 0.7), 5.0)
	for f in flyers:
		var ft = DU.tex("enemies/%s_crit" % f.kind)
		if ft != null:
			var fw = 56.0 * ft.get_width() / ft.get_height()
			DU.quad(self, ft, Transform2D(f.rot, f.p), Rect2(-fw * 0.5, -28, fw, 56))
			continue
		draw_set_transform(f.p, f.rot, Vector2(0.45, 0.45))
		DU.poop(self, f.col, "crit", Vector2.ZERO, t, 0.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 주인공: 변기에서 튀어나와 옆에 착지하고 만세
	if t > 1.1:
		var hp: Vector2
		var rot = 0.0
		var u = t - 1.1
		if u < 1.2:
			var k = u / 1.2
			hp = BOWL.lerp(Vector2(740, 480), k) + Vector2(0, -sin(k * PI) * 420.0)
			rot = k * TAU
		else:
			hp = Vector2(740, 480 - abs(sin((u - 1.2) * 6.0)) * 22.0)
		var drawn = false
		if u < 1.2:
			drawn = _hero_tex("roll", hp + Vector2(0, -40), rot, 80.0)
		else:
			drawn = _hero_tex("win", hp, 0.0, 140.0)
		if not drawn:
			draw_set_transform(hp, rot, Vector2.ONE)
			DU.hero(self, Vector2(0.2, -1), 0.0, true, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_parts()
	if t < 1.1:
		DU.text_c(self, Vector2(480 + sh.x * 3.0, 110), "꾸르륵... 꾸르르륵...", 44, Color("c9a27a"), 9)
	elif t < 2.0:
		var s = 1.0 + max(0.0, 1.0 - (t - 1.1) * 6.0)
		DU.star(self, Vector2(280, 250), 90.0 * s, Color("ffd23f"))
		draw_set_transform(Vector2(280, 250), -0.2, Vector2(s, s))
		DU.text_c(self, Vector2.ZERO, "펑!", 72, Color("ff5a3a"), 10, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t > 1.45:
		var u = t - 1.45
		# 탄성 있게 튀어나오는 '쾌변!'
		var s = 1.0 + exp(-u * 5.0) * sin(u * 18.0) * 0.6
		if u < 0.12:
			s = u / 0.12 * 1.5
		var c = Color.from_hsv(fmod(t * 0.3, 1.0), 0.25, 1.0).lerp(Color("ffd23f"), 0.6)
		var lt = DU.tex("ui/logo_kwaebyeon")
		if lt != null:
			var lw = 330.0
			var lh = lw * lt.get_height() / lt.get_width()
			DU.quad(self, lt, Transform2D(sin(t * 4.0) * 0.05, Vector2(s, s), 0.0, Vector2(480, 108)), Rect2(-lw * 0.5, -lh * 0.5, lw, lh))
		else:
			draw_set_transform(Vector2(480, 95), sin(t * 4.0) * 0.06, Vector2(s, s))
			DU.text_c(self, Vector2.ZERO, "쾌변!", 120, c, 18, Color("6b3410"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t > 2.4:
		DU.text_c(self, Vector2(480, 232 if DU.tex("ui/logo_kwaebyeon") != null else 185), "모든 하수구가 뻥! 뚫렸다!  ALL CLEAR", 34, Color.WHITE, 8)
	if t > 3.0:
		DU.text_c(self, Vector2(180, 500), "최종 점수 %d" % main.score, 32, Color("fff2b0"), 8)
	if t > 3.5 and int(t * 2.0) % 2 == 0:
		DU.text_c(self, Vector2(480, 520), "누르면 계속", 24, Color("b9f5ff"), 6)


# ---------------------------------------------------------------- 대승리 화면

func _victory_tick(_delta):
	var cols = [Color("ff5a5a"), Color("ffd23f"), Color("5ad1ff"), Color("8cff7a"), Color("ff9be0")]
	if randf() < 0.6:
		parts.append({"p": Vector2(randf_range(0, 960), -10), "v": Vector2(randf_range(-40, 40), randf_range(80, 170)),
			"life": 4.5, "col": cols[randi() % cols.size()], "r": randf_range(3, 6), "g": 0.0})
	# 펑펑 터지는 불꽃놀이
	if _once("fw%d" % int(t / 0.7), 0.0):
		var c = Vector2(randf_range(120, 840), randf_range(60, 230))
		var col = cols[randi() % cols.size()]
		for i in 26:
			var a = i * TAU / 26.0
			parts.append({"p": c, "v": Vector2(cos(a), sin(a)) * randf_range(160, 240),
				"life": randf_range(0.7, 1.1), "col": col, "r": randf_range(3, 5), "g": 120.0})
		Sfx.play("pop", randf_range(1.4, 1.9), -10.0)


func _victory_actor(path: String, pos: Vector2, height: float, rot: float = 0.0):
	var tx = DU.tex(path)
	if tx == null:
		return
	var w = height * tx.get_width() / tx.get_height()
	DU.quad(self, tx, Transform2D(rot, pos), Rect2(-w * 0.5, -height, w, height))


func _draw_victory():
	var key = DU.tex("ui/victory_key")
	if key != null:
		draw_texture_rect(key, Rect2(0, 0, 960, 540), false)
	else:
		_room(Vector2.ZERO, 0.0, WATER)
		draw_rect(Rect2(0, 0, 960, 540), Color(0.1, 0.05, 0.2, 0.35))
		var c = Vector2(480, 120)
		for i in 16:
			var a0 = t * 0.3 + i * TAU / 16.0
			var a1 = a0 + TAU / 32.0
			draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * 800.0, c + Vector2(cos(a1), sin(a1)) * 800.0]), Color(1, 0.9, 0.4, 0.12))
		# 그동안 물리친 보스들이 뒤에서, 똥괴물들이 앞에서 축하해 준다 (반창고 붙인 치명타 얼굴)
		_victory_actor("boss/boss_normal", Vector2(150, 470), 150.0, sin(t * 2.0) * 0.05)
		_victory_actor("boss/rainbow_normal", Vector2(810, 470), 170.0, -sin(t * 2.0) * 0.05)
		var cast = [["enemies/mini_hit", 80.0], ["enemies/plain_normal", 250.0], ["enemies/green_normal", 710.0], ["enemies/runner_crit", 880.0]]
		for i in cast.size():
			var bob = abs(sin(t * 5.0 + i * 1.3)) * 22.0
			_victory_actor(cast[i][0], Vector2(cast[i][1], 535 - bob), 100.0)
		var hop = abs(sin(t * 4.0)) * 16.0
		_victory_actor("hero/hero_win", Vector2(480, 530 - hop), 200.0)
	_parts()
	# 대승리! 로고
	var u = t
	var s = 1.0 + exp(-u * 4.0) * sin(u * 16.0) * 0.6
	if u < 0.15:
		s = u / 0.15 * 1.5
	var ly = 70.0 if key != null else 92.0
	var lt = DU.tex("ui/logo_victory")
	if lt != null:
		var lw = 360.0
		var lh = lw * lt.get_height() / lt.get_width()
		DU.quad(self, lt, Transform2D(sin(t * 3.0) * 0.04, Vector2(s, s), 0.0, Vector2(480, ly)), Rect2(-lw * 0.5, -lh * 0.5, lw, lh))
	else:
		draw_set_transform(Vector2(480, ly), sin(t * 3.0) * 0.05, Vector2(s, s))
		DU.text_c(self, Vector2.ZERO, "대승리!", 110, Color("ffd23f").lerp(Color.WHITE, 0.2 + sin(t * 8.0) * 0.2), 18, Color("6b3410"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t > 0.8:
		var y = 470.0 if key != null else 180.0
		if key != null:
			draw_rect(Rect2(0, 440, 960, 100), Color(0, 0, 0, 0.35))
		DU.text_c(self, Vector2(480, y), "모든 하수구를 뻥! 뚫었다! 똥괴물 나라에 평화가 왔어요", 28, Color.WHITE, 7)
		DU.text_c(self, Vector2(480, y + 40), "최종 점수 %d" % main.score, 34, Color("fff2b0"), 8)
		if main.new_record and int(t * 3.0) % 2 == 0:
			DU.text_c(self, Vector2(700, y + 40), "신기록!", 30, Color("ff6b5a"), 7)
	if t > 2.5 and int(t * 2.0) % 2 == 0:
		DU.text_c(self, Vector2(480, 528 if key != null else 300), "누르면 처음으로", 24, Color("b9f5ff"), 6)
