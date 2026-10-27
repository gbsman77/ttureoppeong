extends Node2D
## 똥괴물이 떨어뜨리는 아이템. 뚜러뻥으로 맞히면 얻는다.

const DU = preload("res://scripts/draw_util.gd")

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


func hit_test(p: Vector2) -> bool:
	return p.distance_to(pos) < 34.0


func collect():
	if is_queued_for_deletion():
		return
	if kind == "life":
		main.player.add_life()
		main.fx.text(pos, "휴지 +1!", Color("b9f5ff"), 28, 0.9)
	else:
		main.player.bombs = min(main.player.bombs + 1, 9)
		main.fx.text(pos, "왕뚜러뻥 +1!", Color("ffb3a8"), 28, 0.9)
	Sfx.play("item")
	queue_free()


func tick(delta: float):
	t += delta
	pos = base + Vector2(sin(t * 2.0) * 10.0, -t * 8.0 + sin(t * 5.0) * 4.0)
	if t > 6.0:
		queue_free()
	queue_redraw()


func _draw():
	if t > 4.5 and int(t * 10.0) % 2 == 0:
		return
	var t = DU.tex("props/item_" + kind)
	if t != null:
		draw_texture_rect(t, Rect2(pos - Vector2(30, 30), Vector2(60, 60)), false)
		return
	draw_circle(pos, 26, Color(1, 1, 1, 0.25))
	draw_arc(pos, 26, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0)
	if kind == "life":
		DU.roll(self, pos + Vector2(0, -12), 26, 22)
	else:
		DU.plunger(self, pos + Vector2(0, 16), 0.3, 0.8)
