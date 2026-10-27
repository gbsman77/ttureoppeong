extends RefCounted
## 그림 파일 없이 코드로 캐릭터와 배경을 그리는 도구 모음.

const FONT = preload("res://fonts/Jua-Regular.ttf")
const INK = Color(0.14, 0.07, 0.02)

# art/ 폴더의 그림. 파일이 없으면 null 을 돌려주고, 그때는 코드 그림을 쓴다.
static var _tex_cache = {}


static func tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var full = "res://art/" + path + ".png"
	var t = null
	if ResourceLoader.exists(full):
		t = load(full)
	_tex_cache[path] = t
	return t


## 발밑(0,0) 기준으로 그림을 그린다. upp = 그림 1px 당 게임 단위.
static func sprite(ci: CanvasItem, t: Texture2D, upp: float, offset: Vector2 = Vector2.ZERO, modulate: Color = Color.WHITE):
	var sz = t.get_size() * upp
	ci.draw_texture_rect(t, Rect2(offset + Vector2(-sz.x * 0.5, -sz.y), sz), false, modulate)


## 사각형 rect 를 변환 xf 로 돌려서 그린다 (캔버스 변환을 건드리지 않음).
static func quad(ci: CanvasItem, t: Texture2D, xf: Transform2D, rect: Rect2, modulate: Color = Color.WHITE):
	var pts = PackedVector2Array([xf * rect.position, xf * Vector2(rect.end.x, rect.position.y),
		xf * rect.end, xf * Vector2(rect.position.x, rect.end.y)])
	var uvs = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	ci.draw_colored_polygon(pts, modulate, uvs, t)


static func ell_pts(c: Vector2, rx: float, ry: float, n: int = 28, a0: float = 0.0, a1: float = TAU) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var full = is_equal_approx(a1 - a0, TAU)
	var count = n if full else n + 1
	for i in count:
		var a = a0 + (a1 - a0) * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, n: int = 28):
	if rx < 0.5 or ry < 0.5:
		return
	ci.draw_colored_polygon(ell_pts(c, rx, ry, n), col)


static func ellipse_line(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w: float = 2.0):
	var pts = ell_pts(c, rx, ry, 28)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, w, true)


static func text_size(txt: String, size: int) -> Vector2:
	return FONT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size)


## pos 를 중심으로 글자를 그린다.
static func text_c(ci: CanvasItem, pos: Vector2, txt: String, size: int, col: Color,
		outline: int = 8, ocol: Color = INK):
	var w = text_size(txt, size).x
	var p = pos - Vector2(w * 0.5, -size * 0.35)
	if outline > 0:
		ci.draw_string_outline(FONT, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ocol)
	ci.draw_string(FONT, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## pos 를 왼쪽 기준선으로 글자를 그린다.
static func text_l(ci: CanvasItem, pos: Vector2, txt: String, size: int, col: Color,
		outline: int = 6, ocol: Color = INK):
	if outline > 0:
		ci.draw_string_outline(FONT, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ocol)
	ci.draw_string(FONT, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


# ---------------------------------------------------------------- 똥괴물

## 발밑(0,0) 기준, 키 약 110 의 SD 똥괴물.
static func poop(ci: CanvasItem, col: Color, face: String, look: Vector2, time: float,
		wobble: float = 0.0, arm_up: bool = false, walk: float = 0.0, drip: bool = false):
	var dark = col.darkened(0.5)
	var light = col.lightened(0.35)
	# 발
	var lf = sin(walk) * 4.0
	ellipse(ci, Vector2(-20, -4 - max(0.0, lf)), 13, 7, dark)
	ellipse(ci, Vector2(20, -4 - max(0.0, -lf)), 13, 7, dark)
	# 팔
	ellipse(ci, Vector2(-46, -40 + sin(time * 5.0) * 2.0), 10, 7, dark)
	ellipse(ci, Vector2(-46, -40 + sin(time * 5.0) * 2.0), 7.5, 5, col)
	if arm_up:
		ellipse(ci, Vector2(40, -84), 7, 10, dark)
		ellipse(ci, Vector2(40, -84), 5, 8, col)
		ci.draw_circle(Vector2(44, -98), 11, dark)
		ci.draw_circle(Vector2(44, -98), 9, col.darkened(0.15))
	else:
		ellipse(ci, Vector2(46, -40 - sin(time * 5.0) * 2.0), 10, 7, dark)
		ellipse(ci, Vector2(46, -40 - sin(time * 5.0) * 2.0), 7.5, 5, col)
	# 몸통 (3단 + 꼭지)
	var tiers = [[0.0, -20.0, 48.0, 22.0], [0.0, -48.0, 39.0, 21.0], [2.0, -73.0, 26.0, 15.0], [5.0, -90.0, 13.0, 9.0]]
	for i in tiers.size():
		var tr = tiers[i]
		var wb = 1.0 + wobble * sin(time * 7.0 + i * 1.3)
		var c = Vector2(tr[0], tr[1])
		var rx = tr[2] * wb
		var ry = tr[3] * (2.0 - wb)
		ellipse(ci, c, rx + 3.0, ry + 3.0, dark)
		ellipse(ci, c, rx, ry, col)
		ellipse(ci, c + Vector2(-rx * 0.45, -ry * 0.35), rx * 0.22, ry * 0.3, light)
	var tip = PackedVector2Array([Vector2(-2, -95), Vector2(15, -111), Vector2(12, -91)])
	ci.draw_colored_polygon(tip, col)
	ci.draw_polyline(PackedVector2Array([Vector2(-2, -96), Vector2(15, -111), Vector2(12, -91)]), dark, 3.0, true)
	if drip:
		for k in 3:
			var x = -30.0 + k * 30.0
			var dy = fmod(time * 30.0 + k * 17.0, 24.0)
			var dc = col.lightened(0.15)
			dc.a = 1.0 - dy / 24.0
			ellipse(ci, Vector2(x, -2 + dy), 4, 6, dc)
	poop_face(ci, face, look, time)


static func spiral(ci: CanvasItem, c: Vector2, r: float, rot: float, col: Color):
	var pts = PackedVector2Array()
	for i in 22:
		var a = rot + i * 0.6
		var rr = r * float(i) / 21.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_polyline(pts, col, 2.2, true)


static func poop_face(ci: CanvasItem, face: String, look: Vector2, time: float):
	var ey = -54.0
	var cheek = Color(1.0, 0.5, 0.6, 0.65)
	match face:
		"normal", "angry":
			for sx in [-1.0, 1.0]:
				var e = Vector2(13.0 * sx, ey)
				ellipse(ci, e, 9, 11, Color.WHITE)
				ellipse_line(ci, e, 9, 11, INK, 2.0)
				var pp = e + Vector2(look.x * 3.0, 2.0 + look.y * 2.0)
				ellipse(ci, pp, 5.5, 6.5, INK)
				ci.draw_circle(pp + Vector2(-2, -2.5), 2.0, Color.WHITE)
			if face == "angry":
				ci.draw_line(Vector2(-23, ey - 15), Vector2(-6, ey - 9), INK, 4.0)
				ci.draw_line(Vector2(23, ey - 15), Vector2(6, ey - 9), INK, 4.0)
				ci.draw_arc(Vector2(0, -34), 6, PI + 0.4, TAU - 0.4, 10, INK, 2.5)
			else:
				ci.draw_arc(Vector2(0, -41), 7, 0.25, PI - 0.25, 12, INK, 2.5)
		"hit":
			ci.draw_polyline(PackedVector2Array([Vector2(-20, ey - 7), Vector2(-8, ey), Vector2(-20, ey + 7)]), INK, 3.5, true)
			ci.draw_polyline(PackedVector2Array([Vector2(20, ey - 7), Vector2(8, ey), Vector2(20, ey + 7)]), INK, 3.5, true)
			ellipse(ci, Vector2(0, -37), 6, 7, INK)
			ellipse(ci, Vector2(0, -34), 4, 3, Color(0.9, 0.3, 0.35))
			ellipse(ci, Vector2(31, -68), 4, 6, Color(0.6, 0.85, 1.0))
			cheek = Color(1.0, 0.35, 0.4, 0.8)
		"crit":
			spiral(ci, Vector2(-13, ey), 10, time * 12.0, INK)
			spiral(ci, Vector2(13, ey), 10, -time * 12.0, INK)
			ellipse(ci, Vector2(0, -36), 12, 9, INK)
			ellipse(ci, Vector2(4, -30), 6, 6, Color(0.95, 0.4, 0.5))
			ellipse(ci, Vector2(-31, -70), 4, 6, Color(0.6, 0.85, 1.0))
			ellipse(ci, Vector2(32, -64), 4, 6, Color(0.6, 0.85, 1.0))
			cheek = Color(1.0, 0.25, 0.3, 0.9)
		"dead":
			for sx in [-1.0, 1.0]:
				var e = Vector2(13.0 * sx, ey)
				ci.draw_line(e + Vector2(-6, -6), e + Vector2(6, 6), INK, 3.5)
				ci.draw_line(e + Vector2(-6, 6), e + Vector2(6, -6), INK, 3.5)
			ci.draw_line(Vector2(-8, -38), Vector2(8, -38), INK, 3.0)
			ellipse(ci, Vector2(4, -33), 5, 6, Color(0.95, 0.4, 0.5))
	ellipse(ci, Vector2(-26, -42), 6, 3.5, cheek)
	ellipse(ci, Vector2(26, -42), 6, 3.5, cheek)


static func stars(ci: CanvasItem, c: Vector2, r: float, time: float, n: int = 3):
	for i in n:
		var a = time * 4.0 + i * TAU / n
		star(ci, c + Vector2(cos(a) * r, sin(a) * r * 0.35), 7.0, Color("ffe14d"))


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color):
	var pts = PackedVector2Array()
	for i in 10:
		var a = -PI / 2 + i * PI / 5
		var rr = r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)


# ---------------------------------------------------------------- 주인공과 뚜러뻥

static func plunger(ci: CanvasItem, pos: Vector2 = Vector2.ZERO, rot: float = 0.0, s: float = 1.0):
	var xf = Transform2D(rot, Vector2(s, s), 0.0, pos)
	var t = tex("props/plunger")
	if t != null:
		var h = 52.0
		var w = h * t.get_width() / t.get_height()
		quad(ci, t, xf, Rect2(-w * 0.5, 4 - h, w, h))
		return
	ci.draw_line(xf * Vector2(0, 4), xf * Vector2(0, -34), Color("5a3416"), 7.0 * s)
	ci.draw_line(xf * Vector2(0, 4), xf * Vector2(0, -34), Color("c98a4b"), 4.5 * s)
	var cup = ell_pts(Vector2(0, -36), 15, 13, 14, PI, TAU)
	var pts = PackedVector2Array()
	for p in cup:
		pts.append(xf * p)
	ci.draw_colored_polygon(pts, Color("e2342d"))
	var outline = pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, Color("7a1512"), 2.0 * s, true)
	ci.draw_line(xf * Vector2(-16, -36), xf * Vector2(16, -36), Color("9e1c17"), 4.0 * s)
	ci.draw_circle(xf * Vector2(-6, -42), 2.5 * s, Color(1, 1, 1, 0.6))


## 뒷모습 주인공. 발밑(0,0) 기준.
static func hero(ci: CanvasItem, aim_dir: Vector2, walk: float, arm_up: bool, holding: bool, splat: bool = false):
	var skin = Color("f2c29b")
	var blue = Color("2f6fd6")
	var dblue = Color("1f4a99")
	var yel = Color("ffcc22")
	var dyel = Color("d9a300")
	var l1 = sin(walk) * 5.0
	ci.draw_rect(Rect2(-15, -32 + max(0.0, l1), 11, 28), dblue)
	ci.draw_rect(Rect2(4, -32 + max(0.0, -l1), 11, 28), dblue)
	ellipse(ci, Vector2(-10, -4 + max(0.0, l1)), 9, 5, Color("6b3e1f"))
	ellipse(ci, Vector2(10, -4 + max(0.0, -l1)), 9, 5, Color("6b3e1f"))
	ellipse(ci, Vector2(0, -50), 25, 26, INK)
	ellipse(ci, Vector2(0, -50), 23, 24, blue)
	ci.draw_line(Vector2(-12, -72), Vector2(-8, -40), yel, 4.0)
	ci.draw_line(Vector2(12, -72), Vector2(8, -40), yel, 4.0)
	ci.draw_rect(Rect2(-8, -46, 16, 11), dblue)
	ci.draw_line(Vector2(-21, -66), Vector2(-29, -42), skin, 9.0)
	ci.draw_circle(Vector2(-29, -40), 6, skin)
	var sh = Vector2(20, -66)
	var hand = sh + Vector2(8, 22)
	if arm_up:
		hand = sh + aim_dir.normalized() * 28.0
	ci.draw_line(sh, hand, skin, 9.0)
	ci.draw_circle(hand, 6, skin)
	if holding:
		var rot = 0.25
		if arm_up:
			rot = aim_dir.angle() + PI / 2
		plunger(ci, hand, rot, 0.9)
	ci.draw_circle(Vector2(0, -88), 20, Color("4a2c17"))
	ci.draw_circle(Vector2(-20, -85), 5, skin)
	ci.draw_circle(Vector2(20, -85), 5, skin)
	ci.draw_colored_polygon(ell_pts(Vector2(0, -95), 23, 19, 20, PI, TAU), yel)
	ci.draw_rect(Rect2(-27, -97, 54, 6), dyel)
	ci.draw_line(Vector2(0, -113), Vector2(0, -97), dyel, 4.0)
	if splat:
		ellipse(ci, Vector2(-4, -104), 14, 7, Color("7a4a1e"))
		ellipse(ci, Vector2(8, -98), 7, 9, Color("7a4a1e"))


# ---------------------------------------------------------------- 소품

static func roll(ci: CanvasItem, top: Vector2, w: float, h: float):
	var t = tex("props/tp_roll")
	if t != null:
		var tw = w * 1.15
		var th = tw * t.get_height() / t.get_width()
		ci.draw_texture_rect(t, Rect2(top.x - tw * 0.5, top.y + h + 6 - th, tw, th), false)
		return
	var white = Color("f7f7f2")
	var shade = Color("c9c9bf")
	ci.draw_rect(Rect2(top.x - w / 2, top.y, w, h), white)
	ellipse(ci, top + Vector2(0, h), w / 2, 6, white)
	ci.draw_line(Vector2(top.x - w / 2, top.y), Vector2(top.x - w / 2, top.y + h), shade, 2.0)
	ci.draw_line(Vector2(top.x + w / 2, top.y), Vector2(top.x + w / 2, top.y + h), shade, 2.0)
	ellipse(ci, top, w / 2, 6, Color("ffffff"))
	ellipse_line(ci, top, w / 2, 6, shade, 1.5)
	ellipse(ci, top, w * 0.16, 3, Color("a89f8a"))


static func bathroom(ci: CanvasItem):
	ci.draw_rect(Rect2(0, 0, 960, 390), Color("bfe3f0"))
	for x in range(0, 961, 48):
		ci.draw_line(Vector2(x, 0), Vector2(x, 390), Color("e8f6fb"), 2.0)
	for y in range(0, 391, 48):
		ci.draw_line(Vector2(0, y), Vector2(960, y), Color("e8f6fb"), 2.0)
	ci.draw_rect(Rect2(0, 380, 960, 12), Color("8fb9c9"))
	for gx in 16:
		for gy in 3:
			var col = Color("f3e7cf") if (gx + gy) % 2 == 0 else Color("e0cfae")
			ci.draw_rect(Rect2(gx * 60, 392 + gy * 60, 60, 60), col)


static func toilet(ci: CanvasItem, c: Vector2, swirl: float, water_col: Color):
	var white = Color("fbfbfb")
	var line = Color("8f9ca3")
	ci.draw_rect(Rect2(c.x - 70, c.y - 130, 140, 95), line)
	ci.draw_rect(Rect2(c.x - 67, c.y - 127, 134, 89), white)
	ci.draw_rect(Rect2(c.x - 78, c.y - 142, 156, 18), line)
	ci.draw_rect(Rect2(c.x - 75, c.y - 139, 150, 12), white)
	ci.draw_rect(Rect2(c.x - 58, c.y - 112, 24, 8), Color("b9c3c8"))
	var body = PackedVector2Array([c + Vector2(-92, 0), c + Vector2(92, 0), c + Vector2(62, 80),
		c + Vector2(42, 112), c + Vector2(-42, 112), c + Vector2(-62, 80)])
	ci.draw_colored_polygon(body, white)
	var bl = body.duplicate()
	bl.append(body[0])
	ci.draw_polyline(bl, line, 3.0, true)
	ellipse(ci, c, 101, 37, line)
	ellipse(ci, c, 98, 34, white)
	ellipse(ci, c + Vector2(0, 3), 76, 23, water_col)
	if swirl != 0.0:
		for arm in 3:
			var pts = PackedVector2Array()
			for i in 24:
				var a = swirl + i * 0.32 + arm * TAU / 3.0
				var r = 70.0 * (1.0 - i / 24.0)
				pts.append(c + Vector2(0, 3) + Vector2(cos(a) * r, sin(a) * r * 0.3))
			ci.draw_polyline(pts, Color(1, 1, 1, 0.75), 3.0, true)
	ellipse(ci, c + Vector2(-60, 40), 8, 22, Color(0.85, 0.9, 0.93))
