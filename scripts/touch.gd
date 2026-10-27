extends Node2D
## 핸드폰 터치 조작.
## 화면을 누르면 그곳으로 뚜러뻥을 던지고(누르고 있으면 연사, 끌면 조준이 따라감),
## 왼쪽 아래 ◀ ▶ 로 이동, 오른쪽 아래 버튼으로 구르기와 왕뚜러뻥.
## 버튼은 기존 키보드 동작(move_left 등)을 눌러 주는 방식이라 게임 코드는 그대로 쓴다.

const DU = preload("res://scripts/draw_util.gd")
const BUTTONS = {
	"left": [Vector2(78, 462), 56.0],
	"right": [Vector2(200, 462), 56.0],
	"roll": [Vector2(882, 462), 54.0],
	"bomb": [Vector2(882, 340), 44.0],
}
const ACTIONS = {"left": "move_left", "right": "move_right", "roll": "roll", "bomb": "bomb"}

var main
var enabled = false
var touches = {}  # 손가락 번호 -> "left" / "right" / "roll" / "bomb" / "aim"
var aim_pos = Vector2(480, 330)
var aim_active = false
var _tapped = false


func _ready():
	enabled = DisplayServer.is_touchscreen_available()


## 이번 프레임에 화면을 톡 쳤는지 (타이틀·엔딩에서 시작용). 한 번 읽으면 지워진다.
func consume_tap() -> bool:
	var t = _tapped
	_tapped = false
	return t


func is_portrait() -> bool:
	var s = DisplayServer.window_get_size()
	return enabled and s.y > s.x


func _button_at(p: Vector2) -> String:
	for b in BUTTONS:
		if p.distance_to(BUTTONS[b][0]) < BUTTONS[b][1] + 14.0:
			return b
	return ""


func _press(b: String):
	Input.action_press(ACTIONS[b])


func _release(b: String):
	if not b in touches.values():
		Input.action_release(ACTIONS[b])


func release_all():
	for b in ACTIONS:
		Input.action_release(ACTIONS[b])
	Input.action_release("throw")
	touches.clear()
	aim_active = false


func _input(event):
	if event is InputEventScreenTouch:
		enabled = true
		var p = make_input_local(event).position
		if event.pressed:
			_tapped = true
			if not main.is_playing():
				return
			var b = _button_at(p)
			if b != "":
				touches[event.index] = b
				_press(b)
			else:
				touches[event.index] = "aim"
				aim_pos = p
				aim_active = true
				Input.action_press("throw")
		else:
			var b = touches.get(event.index, "")
			touches.erase(event.index)
			if b == "aim":
				if not "aim" in touches.values():
					aim_active = false
					Input.action_release("throw")
			elif b != "":
				_release(b)
	elif event is InputEventScreenDrag:
		var p = make_input_local(event).position
		var cur = touches.get(event.index, "")
		if cur == "aim":
			aim_pos = p
		elif cur == "left" or cur == "right":
			# 손가락을 떼지 않고 ◀ ▶ 사이를 미끄러지면 방향 전환
			var b = _button_at(p)
			if (b == "left" or b == "right") and b != cur:
				touches[event.index] = b
				_release(cur)
				_press(b)


func _process(_delta):
	if not main.is_playing() and not touches.is_empty():
		release_all()
	queue_redraw()


func _draw():
	if is_portrait():
		draw_rect(Rect2(0, 0, 960, 540), Color(0.08, 0.05, 0.02, 0.92))
		DU.text_c(self, Vector2(480, 230), "핸드폰을 가로로 돌려 주세요!", 56, Color("ffd23f"), 10)
		return
	if not enabled or not main.is_playing():
		return
	for b in BUTTONS:
		var c = BUTTONS[b][0]
		var r = BUTTONS[b][1]
		var on = b in touches.values()
		draw_circle(c, r, Color(1, 1, 1, 0.38 if on else 0.18))
		draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.75), 3.0, true)
		match b:
			"left", "right":
				var sx = -1.0 if b == "left" else 1.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(22 * sx, 0), c + Vector2(-14 * sx, -22), c + Vector2(-14 * sx, 22)]), Color(1, 1, 1, 0.85))
			"roll":
				DU.text_c(self, c, "구르기", 22, Color.WHITE, 5)
			"bomb":
				DU.plunger(self, c + Vector2(-6, 18), -0.3, 0.75)
				DU.text_c(self, c + Vector2(20, 22), "x%d" % main.player.bombs, 20, Color("ffb3a8"), 5)
	if aim_active:
		draw_arc(aim_pos, 30, 0, TAU, 32, Color(1, 0.3, 0.2, 0.5), 3.0)
