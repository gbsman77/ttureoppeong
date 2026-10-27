extends Node2D
## 파티클, 튀는 똥, 글자 효과를 한곳에서 그린다.

const DU = preload("res://scripts/draw_util.gd")

var parts = []
var texts = []


func clear():
	parts.clear()
	texts.clear()
	queue_redraw()


func text(p: Vector2, s: String, col: Color, size: int = 28, life: float = 0.8):
	texts.append({"p": p, "s": s, "col": col, "size": size, "life": life, "max": life})


func _part(p: Vector2, v: Vector2, col: Color, r: float, life: float, g: float, kind: String = "dot"):
	parts.append({"p": p, "v": v, "col": col, "r": r, "life": life, "max": life, "g": g, "kind": kind})


func burst(p: Vector2, col: Color, n: int, spd: float):
	for i in n:
		var a = randf() * TAU
		_part(p, Vector2(cos(a), sin(a)) * randf_range(0.3, 1.0) * spd, col, randf_range(4, 9), randf_range(0.4, 0.7), 500.0)


func sparks(p: Vector2, col: Color, n: int):
	for i in n:
		var a = randf() * TAU
		_part(p, Vector2(cos(a), sin(a)) * randf_range(120, 300), col, randf_range(5, 8), 0.5, 0.0, "star")


func splat(p: Vector2, s: float):
	_part(p, Vector2.ZERO, Color(0.42, 0.25, 0.1, 0.85), 26.0 * s, 0.9, 0.0, "decal")
	for i in 7:
		var a = randf_range(PI, TAU)
		_part(p, Vector2(cos(a), sin(a)) * randf_range(80, 240) * s, Color("7a4a1e"), randf_range(4, 8) * s, 0.5, 700.0)
	text(p + Vector2(0, -20), "철퍽!", Color("e8c49a"), 22, 0.5)


func puff(p: Vector2, s: float):
	for i in 5:
		var a = randf() * TAU
		_part(p, Vector2(cos(a), sin(a)) * 60.0, Color(0.85, 0.85, 0.8, 0.8), 6.0 * s, 0.3, 0.0)


func boom(p: Vector2):
	_part(p, Vector2.ZERO, Color(1, 0.9, 0.5, 0.9), 130.0, 0.4, 0.0, "ring")
	burst(p, Color("e2342d"), 12, 400.0)
	sparks(p, Color("ffe14d"), 16)
	text(p + Vector2(0, -30), "뚜러뻐어엉!!", Color("ffdd33"), 40, 0.9)


func tick(delta: float):
	for q in parts:
		q.life -= delta
		q.v.y += q.g * delta
		q.p += q.v * delta
	parts = parts.filter(func(q): return q.life > 0.0)
	for q in texts:
		q.life -= delta
		q.p.y -= 45.0 * delta
	texts = texts.filter(func(q): return q.life > 0.0)
	queue_redraw()


func _draw():
	for q in parts:
		var k = q.life / q.max
		var c = q.col
		match q.kind:
			"decal":
				c.a *= min(1.0, k * 2.0)
				var st = DU.tex("props/splat")
				if st != null:
					draw_texture_rect(st, Rect2(q.p - Vector2(q.r * 1.2, q.r * 0.5), Vector2(q.r * 2.4, q.r * 1.0)), false, Color(1, 1, 1, c.a))
					continue
				DU.ellipse(self, q.p, q.r, q.r * 0.4, c)
				DU.ellipse(self, q.p + Vector2(q.r * 0.6, -q.r * 0.15), q.r * 0.3, q.r * 0.18, c)
			"ring":
				c.a *= k
				draw_arc(q.p, q.r * (1.2 - k), 0, TAU, 40, c, 16.0 * k + 2.0)
			"star":
				c.a = k
				DU.star(self, q.p, q.r, c)
			_:
				c.a *= min(1.0, k * 2.0)
				draw_circle(q.p, q.r, c)
	for q in texts:
		var k = q.life / q.max
		var age = q.max - q.life
		var pop = 1.0 + 0.6 * max(0.0, 1.0 - age * 8.0)
		var c = q.col
		c.a = min(1.0, k * 3.0)
		var o = DU.INK
		o.a = c.a
		draw_set_transform(q.p, 0.0, Vector2(pop, pop))
		DU.text_c(self, Vector2.ZERO, q.s, q.size, c, 6, o)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
