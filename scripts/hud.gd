extends Node2D
## 점수, 목숨, 게이지, 조준점, 타이틀/게임오버 화면.

const DU = preload("res://scripts/draw_util.gd")

var main
var title_boss: Sprite2D  # 시작 화면에서 오른쪽 뒤에 버티고 선 무지개똥


func _ready():
	title_boss = Sprite2D.new()
	title_boss.show_behind_parent = true
	var t = DU.tex("boss/rainbow_normal")
	if t == null:
		t = DU.tex("boss/boss_normal")
		title_boss.material = DU.recolor("rainbow")
	title_boss.visible = false
	if t != null:
		title_boss.texture = t
		title_boss.offset = Vector2(0, -t.get_height() * 0.5)
	add_child(title_boss)


func _process(_delta):
	title_boss.visible = main.state == "title" and title_boss.texture != null and DU.tex("ui/title_key") == null
	if title_boss.visible:
		var t = main.t
		var s = 215.0 / title_boss.texture.get_height()
		title_boss.position = Vector2(838, 512)
		title_boss.scale = Vector2(s * (1.0 + sin(t * 2.2) * 0.03), s * (1.0 - sin(t * 2.2) * 0.03))


func _draw():
	match main.state:
		"title":
			_title()
		"play", "boss_warn", "boss", "boss_down", "stage_clear":
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
		var left = max(0, m.kill_quota - m.kills)
		var gc = Color("8b5a2b") if m.stage == 1 else Color("6bbf3a")
		_bar(Rect2(330, 16, 300, 22), float(left) / m.kill_quota, gc, "막힘 게이지 - 남은 똥괴물 %d" % left)
	elif m.boss != null and m.state != "stage_clear":
		var b = m.boss
		var bc = Color("d0452f")
		if b.kind == "rainbow":
			bc = Color.from_hsv(fmod(m.t * 0.4, 1.0), 0.65, 0.95)
		_bar(Rect2(280, 16, 400, 24), float(max(0, b.hp)) / b.max_hp, bc, "보스 " + b.boss_name)
		if b.is_raging() and int(m.t * 8.0) % 2 == 0:
			DU.text_l(self, Vector2(692, 38), "무적!", 26, Color("ff6b5a"), 6)

	if m.stage_banner > 0.0 and m.state == "play":
		var a = clamp(m.stage_banner, 0.0, 1.0)
		var c = Color(1, 0.87, 0.3, a)
		var o = DU.INK
		o.a = a
		if m.stage == 1:
			DU.text_c(self, Vector2(480, 210), "STAGE 1 - 막힌 하수구", 56, c, 10, o)
			DU.text_c(self, Vector2(480, 268), "똥괴물 %d마리를 무찌르면 보스가 나온다!" % m.kill_quota, 28, Color(1, 1, 1, a), 7, o)
		else:
			DU.text_c(self, Vector2(480, 210), "STAGE 2 - 무지개 하수구", 56, Color(0.75, 1, 0.55, a), 10, o)
			DU.text_c(self, Vector2(480, 268), "그냥똥과 녹색똥 %d마리를 무찌르면 마지막 보스!" % m.kill_quota, 28, Color(1, 1, 1, a), 7, o)
		DU.text_c(self, Vector2(480, 310), _controls_text(), 20, Color(0.9, 0.95, 1, a), 5, o)

	if m.state == "boss_warn":
		var on = int(m.t * 5.0) % 2 == 0
		draw_rect(Rect2(0, 180, 960, 110), Color(0.8, 0.1, 0.05, 0.45 if on else 0.25))
		DU.text_c(self, Vector2(480, 215), "경고!  WARNING!", 48, Color("ffe14d") if on else Color.WHITE, 10)
		var warn = "보스 '설사'가 몰려온다! 꾸르르륵..." if m.stage == 1 else "마지막 보스 '무지개똥'이 반짝반짝 다가온다!"
		DU.text_c(self, Vector2(480, 262), warn, 30, Color.WHITE, 7)

	if m.state == "boss_down" and m.boss != null:
		var k = min(m.t / 0.4, 1.0)
		var s = 1.0 + (1.0 - k) * 1.5 + sin(m.t * 8.0) * 0.04
		draw_set_transform(Vector2(480, 150), sin(m.t * 3.0) * 0.05, Vector2(s, s))
		DU.text_c(self, Vector2.ZERO, m.boss.boss_name + " 격파!", 72, Color("ffdd33"), 12)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if m.state == "stage_clear":
		_stage_clear()

	if m.is_playing() and not (m.touch.enabled and not m.touch.aim_active):
		var aim = m.get_aim()
		var red = Color("ff4b3a")
		draw_arc(aim, 18, 0, TAU, 32, DU.INK, 5.0)
		draw_arc(aim, 18, 0, TAU, 32, Color.WHITE, 2.5)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_line(aim + d * 10, aim + d * 26, DU.INK, 5.0)
			draw_line(aim + d * 10, aim + d * 26, Color.WHITE, 2.5)
		draw_circle(aim, 3.5, red)


func _stage_clear():
	var t = main.t
	var k = min(t / 0.35, 1.0)
	var s = 1.0 + (1.0 - k) * 1.2
	draw_set_transform(Vector2(480, 170), sin(t * 3.0) * 0.04, Vector2(s, s))
	DU.text_c(self, Vector2.ZERO, "STAGE 1 CLEAR!", 72, Color("ffdd33"), 12)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t > 0.6:
		DU.text_c(self, Vector2(480, 245), "보너스 +1000   두루마리 목숨 +1", 30, Color.WHITE, 7)
	if t > 1.2:
		DU.text_c(self, Vector2(480, 295), "더 깊은 하수구로 슝~!", 34, Color("b9f5ff"), 8)
	if t > 2.3:
		# 다음 스테이지로 넘어가기 전에 화면을 어둡게
		draw_rect(Rect2(0, 0, 960, 540), Color(0, 0, 0, clamp((t - 2.3) / 0.8, 0.0, 1.0)))


func _controls_text() -> String:
	if main.touch.enabled:
		return "누른 곳으로 뚜러뻥! (누르고 있으면 연사)  /  좌우 버튼으로 이동  /  구르기  /  왕뚜러뻥"
	return "이동 A/D  /  조준 마우스  /  던지기 좌클릭(누르고 있기)  /  구르기 Space  /  왕뚜러뻥 우클릭"


func _title():
	var t = main.t
	var key = DU.tex("ui/title_key")
	if key != null:
		draw_texture_rect(key, Rect2(0, 0, 960, 540), false)
	else:
		_title_scene(t)
	# 로고: 위에서 통 떨어져 튕기고, 그다음엔 살랑살랑
	var drop = clamp(t / 0.7, 0.0, 1.0)
	var bounce = 1.0 - pow(1.0 - drop, 3.0)
	var ly = lerp(-140.0, 108.0, bounce) - abs(sin(min(t, 1.2) * 9.0)) * 18.0 * max(0.0, 1.0 - t / 1.2)
	var s = 1.0 + sin(t * 2.5) * 0.03
	var logo = DU.tex("ui/logo_title")
	if logo != null:
		var lw = 430.0
		var lh = lw * logo.get_height() / logo.get_width()
		DU.quad(self, logo, Transform2D(sin(t * 1.7) * 0.03, Vector2(s, s), 0.0, Vector2(480, ly)), Rect2(-lw * 0.5, -lh * 0.5, lw, lh))
	else:
		draw_set_transform(Vector2(480, ly + 20), sin(t * 1.7) * 0.03, Vector2(s, s))
		DU.text_c(self, Vector2.ZERO, "뚜러뻥 대작전", 92, Color("ffd23f"), 16, Color("4a2510"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t < 0.7:
		return
	DU.text_c(self, Vector2(480, 222), "~ 똥괴물을 무찌르고 하수구를 뚫어라! ~", 28, Color.WHITE, 7)
	_start_button(Vector2(480, 288), t)
	if main.best > 0:
		DU.text_c(self, Vector2(480, 350), "최고 점수 %d" % main.best, 24, Color("ffe08a"), 6)


## 시작 화면 그림이 아직 없을 때: 햇살, 주인공, 똥괴물들, 날아가는 뚜러뻥으로 꾸민다.
func _title_scene(t: float):
	draw_rect(Rect2(0, 0, 960, 540), Color(0.05, 0.06, 0.08, 0.5))
	# 로고 뒤로 빙글빙글 도는 햇살
	var c = Vector2(480, 120)
	for i in 14:
		var a0 = t * 0.25 + i * TAU / 14.0
		var a1 = a0 + TAU / 28.0
		var pts = PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * 700.0, c + Vector2(cos(a1), sin(a1)) * 700.0])
		draw_colored_polygon(pts, Color(1, 0.85, 0.3, 0.09))
	# 바닥 쪽 그늘
	draw_rect(Rect2(0, 430, 960, 110), Color(0, 0, 0, 0.25))
	# 주인공: 뚜러뻥을 든 채 신나게 들썩
	var hero = DU.tex("hero/hero_win")
	var hop = abs(sin(t * 4.0)) * 8.0
	if hero != null:
		DU.sprite(self, hero, 175.0 / hero.get_height(), Vector2(120, 528 - hop))
	# 가운데 똥괴물 셋. 뚜러뻥이 날아와 차례로 맞는다
	var period = 0.85
	var n = int(t / period)
	var ph = fmod(t, period)
	var target = n % 3
	var crit = n % 4 == 3
	var kinds = ["mini", "runner", "tank"]
	var xs = [340.0, 480.0, 620.0]
	for i in 3:
		var face = "normal"
		if i == target and ph > 0.4:
			face = "crit" if crit else "hit"
		var bob = abs(sin(t * 3.0 + i)) * 14.0
		var tx = DU.tex("enemies/%s_%s" % [kinds[i], face])
		var base = DU.tex("enemies/%s_normal" % kinds[i])
		if tx != null and base != null:
			DU.sprite(self, tx, 105.0 / base.get_height(), Vector2(xs[i], 512 - bob))
		else:
			draw_set_transform(Vector2(xs[i], 505 - bob), 0.0, Vector2(0.85, 0.85))
			DU.poop(self, Color("8b5a2b"), face, Vector2(0, 0.5), t + i, 0.0, false, t * 8.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 날아가는 뚜러뻥
	var from = Vector2(150, 380 - hop)
	var to = Vector2(xs[target], 455)
	if ph < 0.4:
		var k = ph / 0.4
		var p = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 120.0)
		DU.plunger(self, p, k * 7.0, 0.9)
	elif ph < 0.75:
		var label = "치명타!" if crit else "뽁!"
		var col = Color("ffdd33") if crit else Color.WHITE
		DU.text_c(self, to + Vector2(0, -60 - (ph - 0.4) * 60.0), label, 30 if crit else 26, col, 7)
		if crit:
			DU.stars(self, to + Vector2(0, -40), 30, t)


func _start_button(c: Vector2, t: float):
	var s = 1.0 + sin(t * 5.0) * 0.05
	var w = 330.0
	var h = 74.0
	var btn = DU.tex("ui/btn_start")
	draw_set_transform(c, 0.0, Vector2(s, s))
	if btn != null:
		var bh = w * btn.get_height() / btn.get_width()
		draw_texture_rect(btn, Rect2(-w * 0.5, -bh * 0.5, w, bh), false)
	else:
		_pill(Rect2(-w * 0.5 - 5, -h * 0.5 - 5 + 6, w + 10, h + 10), DU.INK)
		_pill(Rect2(-w * 0.5 - 5, -h * 0.5 - 5, w + 10, h + 10), DU.INK)
		_pill(Rect2(-w * 0.5, -h * 0.5, w, h), Color("ff8a3d"))
		_pill(Rect2(-w * 0.5, -h * 0.5, w, h * 0.55), Color("ffb347"))
		_pill(Rect2(-w * 0.5 + 24, -h * 0.5 + 8, w * 0.35, 12), Color(1, 1, 1, 0.45))
	var label = "터치해서 시작!" if main.touch.enabled else "클릭해서 시작!"
	DU.text_c(self, Vector2(0, 0), label, 38, Color.WHITE, 9, Color("6b2a00"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 알약 모양 (양 끝이 둥근 직사각형)
func _pill(r: Rect2, col: Color):
	var rad = r.size.y * 0.5
	draw_rect(Rect2(r.position.x + rad, r.position.y, r.size.x - rad * 2.0, r.size.y), col)
	draw_circle(Vector2(r.position.x + rad, r.position.y + rad), rad, col)
	draw_circle(Vector2(r.end.x - rad, r.position.y + rad), rad, col)


func _gameover():
	draw_rect(Rect2(0, 0, 960, 540), Color(0.1, 0.05, 0.02, 0.7))
	var s = 1.0 + sin(main.t * 2.0) * 0.03
	draw_set_transform(Vector2(480, 220), 0.0, Vector2(s, s))
	DU.text_c(self, Vector2.ZERO, "변비 걸렸다...", 76, Color("c9a27a"), 12)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DU.text_c(self, Vector2(480, 300), "점수 %d" % main.score, 34, Color.WHITE, 7)
	if main.best > 0:
		DU.text_c(self, Vector2(480, 334), "최고 점수 %d" % main.best, 22, Color("ffe08a"), 6)
	if main.t > 1.5 and int(main.t * 2.0) % 2 == 0:
		DU.text_c(self, Vector2(480, 380), "누르면 처음으로", 30, Color("b9f5ff"), 7)
