extends Node2D
## 주인공 앞의 휴지 바리케이드. 날아오는 똥을 막아 주지만 맞을수록 무너진다.

const DU = preload("res://scripts/draw_util.gd")
const MAX_HP = 12
const ROW_H = 25.0

var main
var x = 480.0
var hp = MAX_HP
var flash = 0.0
# 휴지를 4-3-2 로 쌓은 벽. 주인공 허리까지 가려서 그 뒤에 숨은 게 보인다.
# 맞을수록 위쪽부터 하나씩 없어진다.
var slots = [Vector2(-60, 0), Vector2(-20, 0), Vector2(20, 0), Vector2(60, 0),
	Vector2(-40, 1), Vector2(0, 1), Vector2(40, 1),
	Vector2(-20, 2), Vector2(20, 2)]


func reset():
	hp = MAX_HP
	flash = 0.0
	queue_redraw()


func rolls_left() -> int:
	return int(ceil(float(hp) / MAX_HP * slots.size()))


func blocks(px: float) -> bool:
	return hp > 0 and abs(px - x) < 72.0


func top_y() -> float:
	var n = rolls_left()
	var row = slots[max(n - 1, 0)].y
	return main.GROUND_Y + 4.0 - row * ROW_H


func damage(d: int):
	hp = max(0, hp - d)
	flash = 0.15


func tick(delta: float):
	flash = max(0.0, flash - delta)
	# 주인공이 뒤에 숨으면 휴지 벽을 반투명하게 해서 숨은 모습이 보이게 한다
	var behind = abs(main.player.position.x - x) < 90.0
	modulate.a = lerp(modulate.a, 0.55 if behind else 1.0, min(1.0, delta * 10.0))
	queue_redraw()


func _draw():
	var n = rolls_left()
	var base = main.GROUND_Y + 8.0
	for i in n:
		var s = slots[i]
		DU.roll(self, Vector2(x + s.x, base - s.y * ROW_H), 40, 26)
	if flash > 0.0:
		DU.ellipse(self, Vector2(x, base - 20), 90, 45, Color(1, 1, 1, flash * 3.0))
