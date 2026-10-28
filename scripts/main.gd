extends Node2D
## 게임 전체 흐름: 타이틀 → 변기 다이빙 → 똥괴물 소탕 → 보스 '설사'
## → 스테이지 2: 그냥똥·녹색똥 소탕 → 마지막 보스 '무지개똥' → 쾌변! 클리어

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Plunger = preload("res://scripts/plunger.gd")
const PoopBall = preload("res://scripts/poop_ball.gd")
const Barricade = preload("res://scripts/barricade.gd")
const Item = preload("res://scripts/item.gd")
const Bg = preload("res://scripts/bg.gd")
const Hud = preload("res://scripts/hud.gd")
const Fx = preload("res://scripts/fx.gd")
const Cutscene = preload("res://scripts/cutscene.gd")
const Touch = preload("res://scripts/touch.gd")

const W = 960.0
const H = 540.0
const GROUND_Y = 505.0      # 주인공 발 위치
const FLOOR_TOP = 320.0     # 바닥이 시작되는 지평선 (배경 그림의 굴 바닥)
const FLOOR_BOTTOM = 430.0  # 똥괴물이 다가올 수 있는 가장 앞쪽
const KILL_QUOTAS = [25, 30]  # 스테이지별로 보스 등장까지 처치해야 하는 똥괴물 수
const BOSS_HP = 120
const RAINBOW_HP = 170
const LAST_STAGE = 2
const PLAY_STATES = ["play", "boss_warn", "boss", "boss_down", "stage_clear"]
const BEST_PATH = "user://best.cfg"

var state = "title"
var t = 0.0
var stage_root: Node2D
var bg
var enemies: Node2D
var shots: Node2D
var front: Node2D
var fx
var hud
var touch
var cutscene
var player
var boss = null
var barricades = []
var kills = 0
var score = 0
var best = 0
var stage = 1
var kill_quota = KILL_QUOTAS[0]
var spawn_timer = 0.0
var shake = 0.0
var stage_banner = 0.0


func _ready():
	randomize()
	_setup_input()
	stage_root = Node2D.new()
	add_child(stage_root)
	bg = Bg.new()
	bg.main = self
	stage_root.add_child(bg)
	enemies = Node2D.new()
	enemies.y_sort_enabled = true
	stage_root.add_child(enemies)
	shots = Node2D.new()
	stage_root.add_child(shots)
	front = Node2D.new()
	stage_root.add_child(front)
	player = Player.new()
	player.main = self
	front.add_child(player)
	for x in [170.0, 480.0, 790.0]:
		var b = Barricade.new()
		b.main = self
		b.x = x
		front.add_child(b)
		barricades.append(b)
	fx = Fx.new()
	stage_root.add_child(fx)
	cutscene = Cutscene.new()
	cutscene.main = self
	add_child(cutscene)
	hud = Hud.new()
	hud.main = self
	add_child(hud)
	touch = Touch.new()
	touch.main = self
	add_child(touch)
	best = _load_best()
	goto("title")


func _load_best() -> int:
	var cf = ConfigFile.new()
	if cf.load(BEST_PATH) == OK:
		return int(cf.get_value("score", "best", 0))
	return 0


func _save_best():
	if score <= best:
		return
	best = score
	var cf = ConfigFile.new()
	cf.set_value("score", "best", best)
	cf.save(BEST_PATH)


func _setup_input():
	var keys = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"throw": [KEY_J, KEY_Z],
		"bomb": [KEY_K, KEY_X],
		"roll": [KEY_SPACE, KEY_SHIFT],
		"start": [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var buttons = {"throw": MOUSE_BUTTON_LEFT, "start": MOUSE_BUTTON_LEFT, "bomb": MOUSE_BUTTON_RIGHT}
	for action in buttons:
		var mb = InputEventMouseButton.new()
		mb.button_index = buttons[action]
		InputMap.action_add_event(action, mb)


func is_playing() -> bool:
	return state in PLAY_STATES


func goto(s: String):
	state = s
	t = 0.0
	match s:
		"title":
			_clear_world()
			_set_stage(1)
			cutscene.start("")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Sfx.play_bgm(1.0)
		"intro":
			Sfx.stop_bgm()
			cutscene.start("intro")
		"play":
			cutscene.start("")
			stage_banner = 3.0
			spawn_timer = 2.5
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			Sfx.play_bgm(1.0 if stage == 1 else 1.08)
		"boss_warn":
			Sfx.stop_bgm()
			Sfx.play("warn")
			Sfx.play("warn", 0.8, -4.0)
		"boss":
			Sfx.play_bgm(1.18 if stage == 1 else 1.26)
		"boss_down":
			Sfx.stop_bgm()
			Sfx.play("boss_down")
			shake = 14.0
			for e in enemies.get_children():
				if e != boss and e.alive:
					e.die(false)
			for s2 in shots.get_children():
				if s2 is PoopBall:
					s2.pop(false)
		"stage_clear":
			Sfx.play("fanfare")
			score += 1000
			player.lives = min(player.lives + 1, player.MAX_LIVES)
		"clear":
			_save_best()
			_clear_world()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			cutscene.start("clear")
		"gameover":
			_save_best()
			Sfx.stop_bgm()
			Sfx.play("gameover")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	front.visible = is_playing() or state == "gameover"


func start_game():
	kills = 0
	score = 0
	boss = null
	_set_stage(1)
	_clear_world()
	player.reset()
	for b in barricades:
		b.reset()
	goto("intro")


func _set_stage(n: int):
	stage = n
	kill_quota = KILL_QUOTAS[n - 1]
	bg.set_stage(n)


## 스테이지 1 보스를 쓰러뜨린 뒤 더 깊은 하수구로 내려간다.
func _next_stage():
	_clear_world()
	_set_stage(stage + 1)
	kills = 0
	for b in barricades:
		b.reset()
	player.position.x = W * 0.5
	goto("play")


func _clear_world():
	for c in enemies.get_children():
		c.queue_free()
	for c in shots.get_children():
		c.queue_free()
	fx.clear()
	boss = null


func _process(delta):
	t += delta
	shake = max(0.0, shake - delta * 25.0)
	stage_root.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	stage_banner = max(0.0, stage_banner - delta)
	if touch.is_portrait():
		return  # 세로 화면이면 가로로 돌릴 때까지 멈춤
	var tapped = touch.consume_tap()
	var pressed = Input.is_action_just_pressed("start") or Input.is_action_just_pressed("throw") or tapped
	match state:
		"title":
			if pressed and t > 0.3:
				start_game()
		"intro":
			if t > 3.8 or (t > 0.6 and (Input.is_action_just_pressed("start") or tapped)):
				goto("play")
		"play", "boss_warn", "boss", "boss_down", "stage_clear":
			_tick_world(delta)
		"clear":
			if t > 3.5 and pressed:
				goto("title")
		"gameover":
			fx.tick(delta)
			if t > 1.5 and pressed:
				goto("title")
	bg.queue_redraw()
	hud.queue_redraw()


func _tick_world(delta):
	player.tick(delta, state != "boss_down")
	for e in enemies.get_children():
		if not e.is_queued_for_deletion():
			e.tick(delta)
	for s in shots.get_children():
		if not s.is_queued_for_deletion():
			s.tick(delta)
	for b in barricades:
		b.tick(delta)
	fx.tick(delta)
	if not is_playing():
		return  # 이번 프레임에 게임 오버 등으로 상태가 바뀜
	match state:
		"play":
			spawn_timer -= delta
			var max_alive = 3 + kills / 6
			if spawn_timer <= 0.0 and minion_count() < max_alive:
				spawn_minion()
				spawn_timer = randf_range(0.8, 1.8) - min(kills * 0.02, 0.5)
			if kills >= kill_quota:
				goto("boss_warn")
		"boss_warn":
			if t > 2.6:
				spawn_boss()
				goto("boss")
		"boss_down":
			if t > 3.4:
				goto("clear" if stage >= LAST_STAGE else "stage_clear")
		"stage_clear":
			if t > 3.2:
				_next_stage()


func depth_scale(y: float) -> float:
	return remap(clamp(y, FLOOR_TOP, FLOOR_BOTTOM + 60.0), FLOOR_TOP, FLOOR_BOTTOM, 0.6, 1.0)


func get_aim() -> Vector2:
	if touch != null and touch.enabled:
		return touch.aim_pos
	var m = get_global_mouse_position()
	return Vector2(clamp(m.x, 0.0, W), clamp(m.y, 0.0, H))


func minion_count() -> int:
	var n = 0
	for e in enemies.get_children():
		if e.alive and not e.is_boss:
			n += 1
	return n


func spawn_minion(at = null):
	var e = Enemy.new()
	var r = randf()
	var kind = "mini"
	if stage == 1:
		if kills > 5 and r < 0.3:
			kind = "runner"
		elif kills > 11 and r < 0.55:
			kind = "tank"
	else:
		kind = "plain"
		if r < 0.25 + min(kills * 0.015, 0.3):
			kind = "green"
	e.setup(self, kind)
	if at == null:
		var side = -1.0 if randf() < 0.5 else 1.0
		e.position = Vector2(W * 0.5 + side * (W * 0.5 + 60.0), randf_range(FLOOR_TOP + 15.0, FLOOR_BOTTOM))
	else:
		e.position = Vector2(clamp(at.x, 40.0, W - 40.0), clamp(at.y, FLOOR_TOP + 15.0, FLOOR_BOTTOM))
	enemies.add_child(e)


func spawn_boss():
	var e = Enemy.new()
	e.setup(self, "boss" if stage == 1 else "rainbow")
	e.position = Vector2(515.0, FLOOR_TOP + 10.0)
	boss = e
	enemies.add_child(e)


func throw_plunger(from: Vector2, to: Vector2, big: bool):
	var p = Plunger.new()
	p.setup(self, from, to, big)
	shots.add_child(p)
	Sfx.play("throw", randf_range(0.9, 1.1) * (0.7 if big else 1.0))


## 뚜러뻥이 조준점에 도착했을 때 판정.
func plunger_land(pos: Vector2, big: bool):
	if big:
		Sfx.play("boom")
		shake = max(shake, 12.0)
		fx.boom(pos)
		for s in shots.get_children():
			if s is PoopBall and s.pos.distance_to(pos) < 140.0:
				s.pop(true)
			elif s is Item and s.pos.distance_to(pos) < 120.0:
				s.collect()
		for e in enemies.get_children():
			if e.alive and e.hit_center().distance_to(pos) < 120.0 + e.hit_radius():
				e.take_hit(pos, 4)
		return
	for s in shots.get_children():
		if s is Item and not s.is_queued_for_deletion() and s.hit_test(pos):
			s.collect()
			return
	for s in shots.get_children():
		if s is PoopBall and not s.is_queued_for_deletion() and s.hit_test(pos):
			s.pop(true)
			return
	var best = null
	for e in enemies.get_children():
		if e.alive and e.hit_test(pos) and (best == null or e.position.y > best.position.y):
			best = e
	if best != null:
		best.take_hit(pos, 1)
	else:
		fx.puff(pos, depth_scale(pos.y))


func enemy_throw(from: Vector2, to: Vector2, s0: float, dur: float = 1.1, kind: String = ""):
	var b = PoopBall.new()
	b.setup(self, from, to, s0, dur, kind)
	shots.add_child(b)


## 똥 덩어리가 주인공 쪽 바닥에 떨어졌을 때 판정.
func ball_land(ball):
	var x = ball.target.x
	for b in barricades:
		if b.blocks(x):
			b.damage(1)
			fx.splat(Vector2(x, b.top_y() + 8.0), 0.9)
			Sfx.play("splat", 1.2)
			return
	if player.can_be_hit() and abs(player.position.x - x) < 34.0:
		player.hurt()
		fx.splat(player.position + Vector2(0, -95), 1.2)
		if player.lives <= 0:
			goto("gameover")
		return
	fx.splat(ball.target, 1.0)
	Sfx.play("splat", randf_range(0.9, 1.1))


func enemy_killed(e):
	score += e.points
	if not e.is_boss:
		kills += 1
	if randf() < 0.14:
		var it = Item.new()
		it.setup(self, e.hit_center(), "life" if randf() < 0.4 else "bomb")
		shots.add_child(it)


func boss_defeated():
	score += 5000 * stage
	goto("boss_down")
