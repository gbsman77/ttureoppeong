extends Node2D
## 점수, 목숨, 게이지, 조준점, 타이틀/게임오버 화면.

const DU = preload("res://scripts/draw_util.gd")

var main


func _draw():
	match main.state:
		"title":
			_title()
		"play", "boss_warn", "boss", "boss_down":
			_game_hud()
		"gameover":
			_game_hud()
			_gameover()


func _bar(r: Rect2, k: float, col: Color, label: String):
	draw_rect(r.grow(3), DU.INK)
	draw_rect(r, Color("3a2a1a"))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clamp(k, 0.0, 1.0), r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(r.size.x * clamp(k, 0.0, 1.0), r.size.y * 0.35)), Color(1, 1, 1, 0.25))
	DU.text_c(self, r.get_center() + Vector2(0, -1), label, 18, Color.WHITE, 5)


func _game_hud():
	var m = main
	var p = m.player
	DU.text_l(self, Vector2(16, 36), "점수 %d" % m.score, 28, Color("fff2b0"))
	for i in p.lives:
		DU.roll(self, Vector2(28 + i * 30, 52), 24, 20)
	for i in p.bombs:
		DU.plunger(self, Vector2(26 + i * 22, 118), 0.0, 0.7)
	DU.text_l(self, Vector2(16 + max(1, p.bombs) * 22 + 6, 112), "왕뚜러뻥", 16, Color("ffb3a8"), 4)

	if m.state == "play":
		var left = max(0, m.KILL_QUOTA - m.kills)
		_bar(Rect2(330, 16, 300, 22), float(left) / m.KILL_QUOTA, Color("8b5a2b"), "막힘 게이지 - 남은 똥괴물 %d" % left)
	elif m.boss != null:
		var b = m.boss
		_bar(Rect2(280, 16, 400, 24), float(max(0, b.hp)) / b.max_hp, Color("d0452f"), "보스 설사")

	if m.stage_banner > 0.0 and m.state == "play":
		var a = clamp(m.stage_banner, 0.0, 1.0)
		var c = Color(1, 0.87, 0.3, a)
		var o = DU.INK
		o.a = a
		DU.text_c(self, Vector2(480, 210), "STAGE 1 - 막힌 하수구", 56, c, 10, o)
		DU.text_c(self, Vector2(480, 268), "똥괴물 %d마리를 무찌르면 보스가 나온다!" % m.KILL_QUOTA, 28, Color(1, 1, 1, a), 7, o)
		DU.text_c(self, Vector2(480, 310), _controls_text(), 20, Color(0.9, 0.95, 1, a), 5, o)

	if m.state == "boss_warn":
		var on = int(m.t * 5.0) % 2 == 0
		draw_rect(Rect2(0, 180, 960, 110), Color(0.8, 0.1, 0.05, 0.45 if on else 0.25))
		DU.text_c(self, Vector2(480, 215), "경고!  WARNING!", 48, Color("ffe14d") if on else Color.WHITE, 10)
		DU.text_c(self, Vector2(480, 262), "보스 '설사'가 몰려온다! 꾸르르륵...", 30, Color.WHITE, 7)

	if m.state == "boss_down":
		var k = min(m.t / 0.4, 1.0)
		var s = 1.0 + (1.0 - k) * 1.5 + sin(m.t * 8.0) * 0.04
		draw_set_transform(Vector2(480, 150), sin(m.t * 3.0) * 0.05, Vector2(s, s))
		DU.text_c(self, Vector2.ZERO, "설사 격파!", 72, Color("ffdd33"), 12)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if m.is_playing() and not (m.touch.enabled and not m.touch.aim_active):
		var aim = m.get_aim()
		var red = Color("ff4b3a")
		draw_arc(aim, 18, 0, TAU, 32, DU.INK, 5.0)
		draw_arc(aim, 18, 0, TAU, 32, Color.WHITE, 2.5)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_line(aim + d * 10, aim + d * 26, DU.INK, 5.0)
			draw_line(aim + d * 10, aim + d * 26, Color.WHITE, 2.5)
		draw_circle(aim, 3.5, red)


func _controls_text() -> String:
	if main.touch.enabled:
		return "누른 곳으로 뚜러뻥! (누르고 있으면 연사)  /  좌우 버튼으로 이동  /  구르기  /  왕뚜러뻥"
	return "이동 A/D  /  조준 마우스  /  던지기 좌클릭(누르고 있기)  /  구르기 Space  /  왕뚜러뻥 우클릭"


func _title():
	var t = main.t
	draw_rect(Rect2(0, 0, 960, 540), Color(0.05, 0.08, 0.06, 0.55))
	var cols = [Color("8b5a2b"), Color("bb853f"), Color("5a3818")]
	for i in 3:
		var x = 230.0 + i * 250.0
		var bob = abs(sin(t * 3.0 + i)) * 18.0
		var face = "normal"
		if int(t * 1.2 + i) % 4 == 0:
			face = "hit"
		var pt = DU.tex("enemies/%s_%s" % [["mini", "runner", "tank"][i], face])
		if pt != null:
			var base = DU.tex("enemies/%s_normal" % ["mini", "runner", "tank"][i])
			DU.sprite(self, pt, 115.0 / base.get_height(), Vector2(x, 470 - bob))
			continue
		draw_set_transform(Vector2(x, 455 - bob), 0.0, Vector2(0.9, 0.9 + bob * 0.004))
		DU.poop(self, cols[i], face, Vector2(sin(t + i), 0.5), t + i, 0.0, false, t * 8.0, i == 1)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var s = 1.0 + sin(t * 2.5) * 0.03
	var logo = DU.tex("ui/logo_title")
	var sub_y = 205
	if logo != null:
		var lw = 400.0
		var lh = lw * logo.get_height() / logo.get_width()
		DU.quad(self, logo, Transform2D(sin(t * 1.7) * 0.03, Vector2(s, s), 0.0, Vector2(480, 112)), Rect2(-lw * 0.5, -lh * 0.5, lw, lh))
		sub_y = 238
	else:
		draw_set_transform(Vector2(480, 130), sin(t * 1.7) * 0.03, Vector2(s, s))
		DU.text_c(self, Vector2.ZERO, "뚜러뻥 대작전", 92, Color("ffd23f"), 16, Color("4a2510"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		DU.plunger(self, Vector2(170, 175), -0.5 + sin(t * 3.0) * 0.2, 1.6)
		DU.plunger(self, Vector2(790, 175), 0.5 - sin(t * 3.0) * 0.2, 1.6)
	DU.text_c(self, Vector2(480, sub_y), "~ 똥괴물을 무찌르고 하수구를 뚫어라! ~", 30, Color.WHITE, 7)
	if int(t * 2.0) % 2 == 0:
		DU.text_c(self, Vector2(480, 285), "화면을 톡 눌러 시작!" if main.touch.enabled else "클릭 또는 Enter 로 시작!", 36, Color("b9f5ff"), 8)
	DU.text_c(self, Vector2(480, 330), _controls_text(), 18, Color(0.9, 0.9, 0.9), 5)
	DU.text_c(self, Vector2(480, 362), "같은 똥괴물을 연속으로 %d번 맞히면 치명타!" % 4, 18, Color("ffe08a"), 5)


func _gameover():
	draw_rect(Rect2(0, 0, 960, 540), Color(0.1, 0.05, 0.02, 0.7))
	var s = 1.0 + sin(main.t * 2.0) * 0.03
	draw_set_transform(Vector2(480, 220), 0.0, Vector2(s, s))
	DU.text_c(self, Vector2.ZERO, "변비 걸렸다...", 76, Color("c9a27a"), 12)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DU.text_c(self, Vector2(480, 300), "점수 %d" % main.score, 34, Color.WHITE, 7)
	if main.t > 1.5 and int(main.t * 2.0) % 2 == 0:
		DU.text_c(self, Vector2(480, 360), "누르면 처음으로", 30, Color("b9f5ff"), 7)
