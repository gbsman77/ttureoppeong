extends Node2D
## SD 똥괴물과 보스 '설사'.
## 뚜러뻥에 맞으면 맞은 얼굴, 연속 COMBO_CRIT 대 맞으면 치명타 얼굴이 된다.

const DU = preload("res://scripts/draw_util.gd")
const COMBO_CRIT = 4      # 이만큼 연속으로 맞으면 치명타
const COMBO_WINDOW = 0.9  # 이 시간 안에 다음 타격이 들어와야 연속으로 친다

var main
var kind = "mini"
var is_boss = false
var hp = 2
var max_hp = 2
var size = 1.0
var color = Color("8b5a2b")
var speed = 80.0
var points = 100
var drip = false
var wobble = 0.0
var angry = false
var alive = true
var time = 0.0
var mode = "walk"
var mode_t = 0.0
var idle_time = 0.8
var target_x = 480.0
var throw_cd = 2.0
var face = "normal"
var face_t = 0.0
var combo = 0
var combo_t = 0.0
var squash = 0.0
var stuck = []
var death_t = 0.0
var walk = 0.0
var attack_n = 0
var spray_i = 0
var spray_from = 0.0
var spray_to = 0.0


func setup(m, k: String):
	main = m
	kind = k
	time = randf() * 10.0
	match kind:
		"mini":
			hp = 2; size = 1.0; speed = 85.0; color = Color("8b5a2b"); points = 100
			throw_cd = randf_range(1.5, 3.0)
		"runner":
			hp = 1; size = 0.85; speed = 200.0; color = Color("bb853f"); points = 150; drip = true
			throw_cd = randf_range(3.5, 5.5)
		"tank":
			hp = 7; size = 1.3; speed = 45.0; color = Color("5a3818"); points = 300; angry = true
			throw_cd = randf_range(1.0, 2.0)
		"boss":
			is_boss = true
			hp = main.BOSS_HP; size = 2.7; speed = 90.0; color = Color("b07534"); points = 0
			drip = true; wobble = 0.06
			mode = "enter"
			throw_cd = 1.0
	max_hp = hp
	target_x = randf_range(80.0, main.W - 80.0)


func _scale() -> float:
	return main.depth_scale(position.y) * size


func hit_center() -> Vector2:
	return position + Vector2(0, -50) * _scale()


func hit_radius() -> float:
	return 46.0 * _scale()


func hit_test(p: Vector2) -> bool:
	return p.distance_to(hit_center()) < hit_radius()


func _set_mode(m: String):
	mode = m
	mode_t = 0.0


func tick(delta: float):
	time += delta
	mode_t += delta
	face_t -= delta
	if face_t <= 0.0:
		face = "normal"
	combo_t -= delta
	if combo_t <= 0.0:
		combo = 0
	squash = lerp(squash, 0.0, min(1.0, delta * 9.0))
	for s in stuck:
		s.t -= delta
	stuck = stuck.filter(func(s): return s.t > 0.0)
	if not alive:
		death_t += delta
		if is_boss and DU.tex("boss/boss_down") != null:
			rotation = 0.0
		elif is_boss:
			# 옆으로 꽈당 쓰러졌다가 살짝 튕긴다
			var k = min(death_t / 0.7, 1.0)
			rotation = -1.45 * (k * k) + sin(min(death_t, 1.5) * 9.0) * 0.12 * max(0.0, 1.0 - death_t)
		elif death_t > 0.6:
			queue_free()
	else:
		if is_boss:
			_boss_ai(delta)
		else:
			_minion_ai(delta)
	var s = _scale()
	var flat = 1.0
	if not alive and not is_boss:
		flat = max(0.15, 1.0 - death_t * 1.6)
		modulate.a = 1.0 - death_t / 0.6
	scale = Vector2(s * (1.0 + squash) * (2.0 - flat), s * (1.0 - squash) * flat)
	queue_redraw()


func _minion_ai(delta: float):
	throw_cd -= delta
	var on_screen = position.x > 50.0 and position.x < main.W - 50.0
	match mode:
		"walk":
			var dx = target_x - position.x
			var step = speed * main.depth_scale(position.y) * delta
			walk += delta * 12.0
			if abs(dx) <= step:
				position.x = target_x
				_set_mode("idle")
				idle_time = randf_range(0.4, 1.4)
			else:
				position.x += sign(dx) * step
		"idle":
			if throw_cd <= 0.0 and on_screen and main.state in ["play", "boss"]:
				_set_mode("windup")
			elif mode_t > idle_time:
				target_x = randf_range(60.0, main.W - 60.0)
				_set_mode("walk")
		"windup":
			if mode_t > 0.55:
				_throw_at_player(Vector2(30, -98), randf_range(-50, 50), 1.1)
				throw_cd = randf_range(2.0, 4.0) if kind != "tank" else randf_range(1.2, 2.2)
				_set_mode("idle")
				idle_time = randf_range(0.3, 1.0)
		"stun":
			if mode_t > 0.6:
				_set_mode("idle")
				idle_time = 0.2


func _throw_at_player(hand: Vector2, spread: float, dur: float):
	var s = _scale()
	var from = position + hand * s
	var to = Vector2(clamp(main.player.position.x + spread, 20.0, main.W - 20.0), main.GROUND_Y - 50.0)
	main.enemy_throw(from, to, s * 0.45, dur)


func _boss_ai(delta: float):
	var rage = hp < max_hp * 0.5
	var spd = speed * (1.4 if rage else 1.0)
	match mode:
		"enter":
			var k = min(mode_t / 1.6, 1.0)
			position.y = lerp(main.FLOOR_TOP + 10.0, main.FLOOR_TOP + 70.0, k)
			modulate.a = k
			if k >= 1.0:
				_set_mode("walk")
				target_x = randf_range(220.0, 740.0)
		"walk":
			walk += delta * 8.0
			var dx = target_x - position.x
			var step = spd * delta
			if abs(dx) <= step:
				position.x = target_x
				_set_mode("idle")
				idle_time = 0.35 if rage else 0.7
			else:
				position.x += sign(dx) * step
		"idle":
			if mode_t > idle_time:
				_set_mode("windup")
		"windup":
			if mode_t > (0.5 if rage else 0.8):
				_boss_attack()
		"spray":
			if mode_t > 0.13:
				mode_t = 0.0
				var k = float(spray_i) / 9.0
				var to = Vector2(lerp(spray_from, spray_to, k), main.GROUND_Y - 50.0)
				main.enemy_throw(position + Vector2(36, -110) * _scale(), to, _scale() * 0.3, 0.9)
				spray_i += 1
				if spray_i >= 10:
					_set_mode("walk")
					target_x = randf_range(220.0, 740.0)
		"stun":
			if mode_t > 0.7:
				_set_mode("walk")
				target_x = randf_range(220.0, 740.0)


func _boss_attack():
	var pattern = attack_n % 3
	attack_n += 1
	match pattern:
		0:  # 똥 부채꼴 던지기
			var n = 7 if hp < max_hp * 0.5 else 5
			for i in n:
				var spread = (i - (n - 1) / 2.0) * 70.0
				_throw_at_player(Vector2(36, -110), spread, 1.15)
			Sfx.play("throw", 0.6)
			_set_mode("walk")
			target_x = randf_range(220.0, 740.0)
		1:  # 설사 스프레이: 바닥을 좌→우(또는 우→좌)로 훑는다
			spray_i = 0
			if randf() < 0.5:
				spray_from = 40.0; spray_to = main.W - 40.0
			else:
				spray_from = main.W - 40.0; spray_to = 40.0
			_set_mode("spray")
		2:  # 꼬마똥 소환
			if main.minion_count() < 4:
				for sx in [-1.0, 1.0]:
					main.spawn_minion(position + Vector2(sx * 160.0, randf_range(10.0, 50.0)))
				main.fx.text(hit_center() + Vector2(0, -60), "나와라 얘들아!", Color("ffe08a"), 26)
			_set_mode("walk")
			target_x = randf_range(220.0, 740.0)


func take_hit(p: Vector2, dmg: int):
	if not alive:
		return
	combo += 1
	combo_t = COMBO_WINDOW
	var crit = combo >= COMBO_CRIT
	var s = _scale()
	if crit:
		combo = 0
		dmg *= 3
		face = "crit"
		face_t = 0.8
		squash = 0.4
		main.fx.text(p + Vector2(0, -40), "치명타!", Color("ffdd33"), 44, 1.0)
		main.fx.sparks(p, Color("ffe14d"), 14)
		Sfx.play("crit")
		main.shake = max(main.shake, 7.0)
		if mode != "enter":
			_set_mode("stun")
	else:
		face = "hit"
		face_t = 0.35
		squash = 0.22
		var label = "뽁!" if combo < 2 else "뽁! x%d" % combo
		main.fx.text(p + Vector2(randf_range(-10, 10), -20), label, Color.WHITE, 26, 0.6)
		Sfx.play("hit", randf_range(0.9, 1.15))
	# 얼굴에 붙은 뚜러뻥
	var local = (p - position) / Vector2(s, s)
	stuck.append({"p": local, "t": 0.5, "r": randf_range(-0.4, 0.4)})
	hp -= dmg
	if hp <= 0:
		die(true)


func die(award: bool):
	if not alive:
		return
	alive = false
	death_t = 0.0
	face = "dead"
	face_t = 999.0
	if is_boss:
		main.fx.text(hit_center() + Vector2(0, -80), "으아아~ 설사 멈췄다...", Color("ffe08a"), 30, 2.0)
		main.boss_defeated()
		return
	if award:
		Sfx.play("die", randf_range(0.9, 1.25))
		main.fx.text(hit_center() + Vector2(0, -30), "+%d" % points, Color("fff2b0"), 24, 0.8)
		main.enemy_killed(self)
	main.fx.burst(hit_center(), color, 10, 220.0)


## 그림 파일이 있으면 그것으로 그린다. 성공하면 true.
func _draw_textured(f: String, hop: float) -> bool:
	var base = DU.tex("boss/boss_normal" if is_boss else "enemies/%s_normal" % kind)
	if base == null:
		return false
	var t = null
	var upp = 1.0
	if is_boss:
		var name = "normal"
		if not alive:
			name = "down"
		elif mode == "windup" or mode == "spray":
			name = "attack"
		elif f == "hit" or f == "crit":
			name = f
		elif hp < max_hp * 0.5:
			name = "angry"
		t = DU.tex("boss/boss_" + name)
		# 보스 그림들은 해상도가 서로 달라서 몸통 너비로 맞춘다
		var width_units = {"normal": 125.0, "angry": 125.0, "hit": 125.0, "crit": 125.0, "attack": 200.0, "down": 190.0}[name]
		upp = width_units / t.get_width()
	else:
		var name = f
		if alive and (mode == "windup"):
			name = "throw"
		t = DU.tex("enemies/%s_%s" % [kind, name])
		upp = 118.0 / base.get_height()
	if t == null:
		return false
	DU.sprite(self, t, upp, Vector2(0, hop))
	var st_tex = DU.tex("props/plunger_stuck")
	for st in stuck:
		if st_tex != null:
			draw_texture_rect(st_tex, Rect2(st.p + Vector2(0, hop) - Vector2(14, 14), Vector2(28, 28)), false)
	return true


func _draw():
	var hop = 0.0
	if kind == "runner" and alive and mode == "walk":
		hop = -abs(sin(time * 12.0)) * 14.0
	DU.ellipse(self, Vector2.ZERO, 46, 10, Color(0, 0, 0, 0.25))
	if is_boss:
		var pc = color.lightened(0.1)
		pc.a = 0.55
		DU.ellipse(self, Vector2(0, -2), 70 + sin(time * 3.0) * 4.0, 13, pc)
	var f = face
	if f == "normal" and (angry or mode == "windup" or mode == "spray"):
		f = "angry"
	var look = Vector2.ZERO
	if main.player != null:
		look = Vector2(clamp((main.player.position.x - position.x) / 300.0, -1.0, 1.0), 0.7)
	if _draw_textured(f, hop):
		return
	var arm_up = alive and (mode == "windup" or mode == "spray")
	draw_set_transform(Vector2(0, hop), 0.0, Vector2.ONE)
	DU.poop(self, color, f, look, time, wobble, arm_up, walk, drip)
	if is_boss:
		# 설사의 땀방울과 왕관
		var crown = PackedVector2Array([Vector2(-14, -104), Vector2(-14, -122), Vector2(-6, -112),
			Vector2(2, -126), Vector2(10, -112), Vector2(18, -122), Vector2(18, -104)])
		draw_colored_polygon(crown, Color("ffd23f"))
		draw_polyline(crown, Color("a8790a"), 2.0, true)
		if alive:
			var dy = fmod(time * 40.0, 30.0)
			DU.ellipse(self, Vector2(-44, -76 + dy), 4, 6, Color(0.6, 0.85, 1.0, 1.0 - dy / 30.0))
	for st in stuck:
		DU.ellipse(self, st.p, 14, 11, Color("7a1512"))
		DU.ellipse(self, st.p, 12, 9, Color("e2342d"))
		draw_line(st.p, st.p + Vector2(8, 16).rotated(st.r), Color("c98a4b"), 5.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if (face == "crit" and alive) or (not alive and is_boss):
		DU.stars(self, Vector2(0, -112), 34, time)
