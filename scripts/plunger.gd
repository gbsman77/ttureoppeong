extends Node2D
## 날아가는 뚜러뻥. 화면 안쪽(조준점)으로 작아지며 날아가고 도착하면 판정한다.

const DU = preload("res://scripts/draw_util.gd")

var main
var from = Vector2.ZERO
var to = Vector2.ZERO
var big = false
var t = 0.0
var dur = 0.25


func setup(m, f: Vector2, target: Vector2, is_big: bool):
	main = m
	from = f
	to = target
	big = is_big
	dur = 0.16 + f.distance_to(target) / 2200.0
	if big:
		dur *= 1.7
	position = from


func tick(delta: float):
	t += delta
	var k = min(t / dur, 1.0)
	position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * (80.0 if big else 30.0))
	var s1 = main.depth_scale(to.y) * 0.85
	scale = Vector2.ONE * lerp(1.0, s1, k) * (2.0 if big else 1.0)
	rotation = k * TAU * (1.0 if big else 1.5)
	queue_redraw()
	if k >= 1.0:
		queue_free()
		main.plunger_land(to, big)


func _draw():
	DU.plunger(self, Vector2(0, 16))
