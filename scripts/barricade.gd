extends Node2D
## 주인공 앞의 휴지 바리케이드. 날아오는 똥을 막아 주지만 맞을수록 무너진다.

const DU = preload("res://scripts/draw_util.gd")
const MAX_HP = 9

var main
var x = 480.0
var hp = MAX_HP
var flash = 0.0
# 아래 줄 3개, 위 줄 2개 (주인공의 다리 높이까지만 가린다)
var slots = [Vector2(-38, 0), Vector2(0, 0), Vector2(38, 0), Vector2(-19, -1), Vector2(19, -1)]


func reset():
	hp = MAX_HP
	flash = 0.0
	queue_redraw()


func rolls_left() -> int:
	return int(ceil(float(hp) / MAX_HP * slots.size()))


func blocks(px: float) -> bool:
	return hp > 0 and abs(px - x) < 58.0


func top_y() -> float:
	var n = rolls_left()
	var row = 0 if n <= 3 else 1
	return main.GROUND_Y - 4.0 - row * 22.0


func damage(d: int):
	hp = max(0, hp - d)
	flash = 0.15


func tick(delta: float):
	flash = max(0.0, flash - delta)
	queue_redraw()


func _draw():
	var n = rolls_left()
	var base = main.GROUND_Y + 2.0
	for i in n:
		var s = slots[i]
		var top = Vector2(x + s.x, base - (0 if i < 3 else 22))
		DU.roll(self, top, 34, 26)
	if flash > 0.0:
		DU.ellipse(self, Vector2(x, base - 10), 70, 30, Color(1, 1, 1, flash * 3.0))
