extends Node2D
## 주인공: 화면 아래에서 좌우로 움직이며 조준점으로 뚜러뻥을 던진다.

const DU = preload("res://scripts/draw_util.gd")
const MAX_LIVES = 7
const HURT_TIME = 0.9

var main
var lives = 5
var bombs = 3
var roll_t = 0.0
var roll_dir = 1.0
var invuln = 0.0
var throw_cd = 0.0
var throw_anim = 0.0
var hurt_t = 0.0
var time = 0.0
var walk = 0.0


func reset():
	position = Vector2(main.W * 0.5, main.GROUND_Y)
	lives = 5
	bombs = 3
	roll_t = 0.0
	invuln = 0.0
	hurt_t = 0.0


func can_be_hit() -> bool:
	return roll_t <= 0.0 and invuln <= 0.0


func hand_pos() -> Vector2:
	return position + Vector2(24, -80)


func tick(delta: float, active: bool):
	time += delta
	invuln = max(0.0, invuln - delta)
	hurt_t = max(0.0, hurt_t - delta)
	throw_cd -= delta
	throw_anim = max(0.0, throw_anim - delta)
	var aim = main.get_aim()
	if roll_t > 0.0:
		roll_t -= delta
		position.x += roll_dir * 560.0 * delta
	else:
		var ax = Input.get_axis("move_left", "move_right")
		var spd = 290.0
		var firing = active and Input.is_action_pressed("throw")
		if firing:
			spd *= 0.4  # 카발처럼 던지는 중엔 느려진다
		position.x += ax * spd * delta
		if ax != 0.0:
			walk += delta * 14.0
		if active and Input.is_action_just_pressed("roll"):
			roll_t = 0.42
			roll_dir = sign(ax) if ax != 0.0 else (1.0 if aim.x > position.x else -1.0)
			Sfx.play("roll")
		elif firing and throw_cd <= 0.0:
			throw_cd = 0.17
			throw_anim = 0.12
			main.throw_plunger(hand_pos(), aim, false)
		if active and Input.is_action_just_pressed("bomb") and bombs > 0 and roll_t <= 0.0:
			bombs -= 1
			throw_anim = 0.2
			main.throw_plunger(hand_pos(), aim, true)
	position.x = clamp(position.x, 40.0, main.W - 40.0)
	queue_redraw()


func hurt():
	lives -= 1
	invuln = 1.6
	hurt_t = HURT_TIME
	Sfx.play("hurt")
	main.fx.text(position + Vector2(0, -150), ["으악!", "으엑!", "똥 맞았다!"][randi() % 3], Color("ffb3a8"), 30, 0.8)
	main.shake = max(main.shake, 9.0)


func add_life():
	lives = min(lives + 1, MAX_LIVES)


func _draw():
	DU.ellipse(self, Vector2.ZERO, 32, 8, Color(0, 0, 0, 0.3))
	if invuln > 0.0 and hurt_t <= 0.0 and int(time * 16.0) % 2 == 0:
		return
	if roll_t > 0.0:
		var a = (0.42 - roll_t) / 0.42 * TAU * roll_dir
		var rt = DU.tex("hero/hero_roll")
		if rt != null:
			var sz = rt.get_size() * (70.0 / rt.get_height())
			DU.quad(self, rt, Transform2D(a, Vector2(0, -36)), Rect2(-sz * 0.5, sz))
			return
		draw_set_transform(Vector2(0, -32), a, Vector2.ONE)
		draw_circle(Vector2.ZERO, 30, DU.INK)
		draw_circle(Vector2.ZERO, 28, Color("2f6fd6"))
		draw_colored_polygon(DU.ell_pts(Vector2(0, -6), 26, 22, 16, PI, TAU), Color("ffcc22"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var aim_dir = main.get_aim() - (position + Vector2(20, -66))
	var arm_up = throw_anim > 0.0 or (main.is_playing() and Input.is_action_pressed("throw"))
	var idle = DU.tex("hero/hero_idle")
	if idle != null and hurt_t > 0.0:
		_draw_hurt(idle)
		return
	if idle != null:
		var name = "idle"
		if hurt_t > 0.0:
			name = "hurt"
		elif arm_up:
			name = "throw"
		var t = DU.tex("hero/hero_" + name)
		var bob = -abs(sin(walk)) * 5.0
		DU.sprite(self, t if t != null else idle, 125.0 / idle.get_height(), Vector2(0, bob))
		return
	DU.hero(self, aim_dir, walk, arm_up, throw_anim <= 0.0, hurt_t > 0.0)


## 똥에 맞은 모습: 뒤로 휘청이고, 안전모에 똥이 철퍽 붙어 흘러내리고, 별이 빙글빙글
func _draw_hurt(idle: Texture2D):
	var k = hurt_t / HURT_TIME
	var tilt = sin(time * 28.0) * 0.1 * k
	var lift = -sin((1.0 - k) * PI) * 10.0
	var hit = DU.tex("hero/hero_hit")
	var t = hit if hit != null else DU.tex("hero/hero_hurt")
	if t == null:
		t = idle
	var h = 125.0 * (float(t.get_height()) / idle.get_height() if hit == null else 1.0)
	var w = h * t.get_width() / t.get_height()
	DU.quad(self, t, Transform2D(tilt, Vector2(0, lift)), Rect2(-w * 0.5, -h, w, h))
	if hit == null:
		# 안전모 위에 붙은 똥과 흘러내리는 똥물
		var head = Vector2(0, -108 + lift).rotated(tilt)
		var brown = Color("7a4a1e")
		DU.ellipse(self, head + Vector2(-4, -4), 26, 14, Color("4a2a10"))
		DU.ellipse(self, head + Vector2(-4, -6), 23, 11, brown)
		DU.ellipse(self, head + Vector2(6, -14), 12, 9, brown)
		DU.ellipse(self, head + Vector2(10, -20), 6, 5, Color("9a6232"))
		for i in 3:
			var x = -18.0 + i * 15.0
			var d = (1.0 - k) * 26.0 + i * 3.0
			DU.ellipse(self, head + Vector2(x, 4 + d * 0.5), 4, 4 + d * 0.5, brown)
	DU.stars(self, Vector2(0, -150 + lift), 26, time * 1.5)
