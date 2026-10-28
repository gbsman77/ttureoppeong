extends Node2D
## 주인공 앞의 휴지 바리케이드. 날아오는 똥을 막아 주지만 맞을수록 무너진다.

const DU = preload("res://scripts/draw_util.gd")
const MAX_HP = 10
const ROW_H = 27.0
const ROLL_W = 44.0

var main
var x = 480.0
var hp = MAX_HP
var flash = 0.0
# 휴지를 3-2 로 쌓은 벽. 주인공 다리를 가려서 그 뒤에 숨은 것처럼 보인다.
# 맞을수록 위쪽부터 하나씩 없어진다.
var slots = [Vector2(-44, 0), Vector2(0, 0), Vector2(44, 0), Vector2(-22, 1), Vector2(22, 1)]


func reset():
	hp = MAX_HP
	flash = 0.0
	queue_redraw()


func rolls_left() -> int:
	return int(ceil(float(hp) / MAX_HP * slots.size()))


func blocks(px: float) -> bool:
	return hp > 0 and abs(px - x) < 66.0


func top_y() -> float:
	var n = rolls_left()
	var row = slots[max(n - 1, 0)].y
	return main.GROUND_Y + 4.0 - row * ROW_H


func damage(d: int):
	hp = max(0, hp - d)
	flash = 0.15


func tick(delta: float):
	flash = max(0.0, flash - delta)
	queue_redraw()


func _draw():
	var n = rolls_left()
	var base = main.GROUND_Y + 8.0
	for i in n:
		var s = slots[i]
		DU.roll(self, Vector2(x + s.x, base - s.y * ROW_H), ROLL_W, 26)
	if flash > 0.0:
		DU.ellipse(self, Vector2(x, base - 20), 90, 45, Color(1, 1, 1, flash * 3.0))
