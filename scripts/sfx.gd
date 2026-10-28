extends Node
## 모든 효과음과 BGM을 코드로 합성한다 (외부 사운드 파일 없음).

const RATE = 22050

var sounds = {}
var pool = []
var idx = 0
var bgm_player: AudioStreamPlayer


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 16:
		var p = AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -9.0
	add_child(bgm_player)
	_build()
	bgm_player.stream = sounds["bgm"]


func play(sound_name: String, pitch: float = 1.0, vol_db: float = 0.0):
	if not sounds.has(sound_name):
		return
	var p = pool[idx]
	idx = (idx + 1) % pool.size()
	p.stream = sounds[sound_name]
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


func play_bgm(pitch: float = 1.0):
	bgm_player.pitch_scale = pitch
	if not bgm_player.playing:
		bgm_player.play()


func stop_bgm():
	bgm_player.stop()


# ---------------------------------------------------------------- 합성 도구

func _buf(dur: float) -> PackedFloat32Array:
	var a = PackedFloat32Array()
	a.resize(int(dur * RATE))
	a.fill(0.0)
	return a


func _osc(wave: String, ph: float) -> float:
	var f = ph - floor(ph)
	match wave:
		"sin":
			return sin(f * TAU)
		"sq":
			return 1.0 if f < 0.5 else -1.0
		"tri":
			return 4.0 * abs(f - 0.5) - 1.0
		"saw":
			return 2.0 * f - 1.0
	return 0.0


func _tone(a: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, wave: String,
		vol: float, attack: float = 0.004, curve: float = 1.0, vib: float = 0.0, vib_rate: float = 0.0):
	var n0 = int(start * RATE)
	var n = int(dur * RATE)
	var ph = 0.0
	var ratio = f1 / f0
	for i in n:
		var j = n0 + i
		if j >= a.size():
			break
		var k = float(i) / n
		var f = f0 * pow(ratio, k)
		if vib > 0.0:
			f *= 1.0 + vib * sin(TAU * vib_rate * i / RATE)
		ph += f / RATE
		var env = min(1.0, i / (attack * RATE)) * pow(1.0 - k, curve)
		a[j] += _osc(wave, ph) * vol * env


func _noise(a: PackedFloat32Array, start: float, dur: float, vol: float, lp: float = 1.0,
		curve: float = 1.0, lfo: float = 0.0, lfo_rate: float = 0.0):
	var n0 = int(start * RATE)
	var n = int(dur * RATE)
	var y = 0.0
	for i in n:
		var j = n0 + i
		if j >= a.size():
			break
		var k = float(i) / n
		var cut = lp
		if lfo > 0.0:
			cut = clamp(lp * (1.0 + lfo * sin(TAU * lfo_rate * i / RATE)), 0.005, 1.0)
		y += cut * (randf() * 2.0 - 1.0 - y)
		a[j] += y * vol * pow(1.0 - k, curve) * min(1.0, i / (0.003 * RATE))


func _wav(a: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes = PackedByteArray()
	bytes.resize(a.size() * 2)
	for i in a.size():
		bytes.encode_s16(i * 2, int(clamp(a[i], -1.0, 1.0) * 32000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = a.size()
	return w


func _note(semi: float) -> float:
	return 523.25 * pow(2.0, semi / 12.0)


# ---------------------------------------------------------------- 사운드 목록

func _build():
	var a: PackedFloat32Array

	# 뚜러뻥 던지기: 휙
	a = _buf(0.12)
	_tone(a, 0, 0.09, 700, 1500, "sq", 0.12, 0.002, 1.5)
	_noise(a, 0, 0.1, 0.18, 0.3, 1.5)
	sounds["throw"] = _wav(a)

	# 명중: 뽁!
	a = _buf(0.14)
	_tone(a, 0, 0.11, 900, 240, "sin", 0.6, 0.002, 1.2)
	_tone(a, 0, 0.05, 1800, 900, "sq", 0.1, 0.001, 1.0)
	sounds["hit"] = _wav(a)

	# 치명타: 뽀옹!!
	a = _buf(0.4)
	_tone(a, 0, 0.12, 1000, 200, "sin", 0.7)
	_noise(a, 0, 0.15, 0.45, 0.5, 2.0)
	_tone(a, 0.06, 0.32, 500, 1700, "sq", 0.2, 0.004, 1.0, 0.05, 30)
	sounds["crit"] = _wav(a)

	# 똥괴물 퇴치: 뿌웅~ 뿅
	a = _buf(0.5)
	_tone(a, 0, 0.36, 150, 80, "saw", 0.42, 0.01, 0.7, 0.25, 28)
	_tone(a, 0.3, 0.16, 600, 1300, "sin", 0.3)
	sounds["die"] = _wav(a)

	# 똥 덩어리 착지: 철퍽
	a = _buf(0.22)
	_noise(a, 0, 0.2, 0.7, 0.15, 2.0)
	_tone(a, 0, 0.09, 300, 90, "sin", 0.4)
	sounds["splat"] = _wav(a)

	# 피격
	a = _buf(0.4)
	_tone(a, 0, 0.36, 420, 120, "sq", 0.22, 0.003, 1.0, 0.1, 20)
	_noise(a, 0, 0.12, 0.3, 0.3)
	sounds["hurt"] = _wav(a)

	# 구르기
	a = _buf(0.28)
	_noise(a, 0, 0.26, 0.25, 0.06, 1.0)
	_tone(a, 0, 0.2, 200, 500, "tri", 0.2)
	sounds["roll"] = _wav(a)

	# 왕뚜러뻥 폭발
	a = _buf(0.9)
	_noise(a, 0, 0.85, 0.9, 0.12, 1.6)
	_tone(a, 0, 0.55, 130, 35, "sin", 0.9)
	sounds["boom"] = _wav(a)

	# 아이템
	a = _buf(0.36)
	var arp = [784.0, 988.0, 1175.0, 1568.0]
	for i in arp.size():
		_tone(a, i * 0.07, 0.1, arp[i], arp[i], "sq", 0.16, 0.002, 0.8)
	sounds["item"] = _wav(a)

	# 보스 경고 사이렌
	a = _buf(1.3)
	for i in 4:
		var f = 880.0 if i % 2 == 0 else 660.0
		_tone(a, i * 0.3, 0.28, f, f * 0.9, "sq", 0.2, 0.01, 0.4)
	sounds["warn"] = _wav(a)

	# 풍덩
	a = _buf(0.55)
	_noise(a, 0, 0.5, 0.7, 0.4, 2.0)
	_tone(a, 0, 0.15, 400, 150, "sin", 0.4)
	sounds["splash"] = _wav(a)

	# 변기 물 내리기: 슈와아아~
	a = _buf(1.9)
	_noise(a, 0, 1.85, 0.55, 0.08, 0.6, 0.8, 3.0)
	for i in 10:
		var f = randf_range(200, 420)
		_tone(a, 0.1 + i * 0.15, 0.1, f, f * 1.8, "sin", 0.22)
	sounds["flush"] = _wav(a)

	# 꾸르륵 (클리어 직전)
	a = _buf(1.1)
	_tone(a, 0, 1.05, 62, 48, "saw", 0.22, 0.05, 0.3, 0.2, 8)
	for i in 7:
		var f = randf_range(180, 360)
		_tone(a, 0.05 + i * 0.14, 0.09, f, f * 2.0, "sin", 0.3)
	sounds["rumble"] = _wav(a)

	# 펑! (변기가 뚫리는 경쾌한 소리)
	a = _buf(0.7)
	_tone(a, 0, 0.45, 170, 35, "sin", 1.0, 0.002, 1.0)
	_noise(a, 0, 0.35, 0.8, 0.35, 2.5)
	_tone(a, 0.08, 0.3, 350, 1400, "sin", 0.45)
	_tone(a, 0.08, 0.3, 700, 2800, "sin", 0.12)
	sounds["pop"] = _wav(a)

	# 쾌변 팡파레
	a = _buf(1.9)
	var mel = [[0.0, 0, 0.12], [0.13, 4, 0.12], [0.26, 7, 0.12], [0.39, 12, 0.3],
		[0.72, 9, 0.12], [0.85, 12, 0.9]]
	for m in mel:
		_tone(a, m[0], m[2], _note(m[1]), _note(m[1]), "sq", 0.16, 0.004, 0.6)
		_tone(a, m[0], m[2], _note(m[1] - 5), _note(m[1] - 5), "tri", 0.12, 0.004, 0.6)
	for s in [0, 4, 7]:
		_tone(a, 0.85, 1.0, _note(s - 12), _note(s - 12), "tri", 0.12, 0.01, 1.0)
	sounds["fanfare"] = _wav(a)

	# 보스 쓰러짐: 뿌우우웅~ 뿅
	a = _buf(1.5)
	_tone(a, 0, 1.2, 210, 50, "saw", 0.42, 0.01, 0.5, 0.3, 18)
	_tone(a, 1.1, 0.25, 300, 700, "sin", 0.35)
	sounds["boss_down"] = _wav(a)

	# 게임 오버
	a = _buf(1.6)
	var go = [7, 4, 0]
	for i in go.size():
		_tone(a, i * 0.25, 0.24, _note(go[i] - 12), _note(go[i] - 12), "tri", 0.3, 0.005, 0.5)
	_tone(a, 0.75, 0.8, _note(-24), _note(-25), "tri", 0.3, 0.005, 1.0)
	sounds["gameover"] = _wav(a)

	# 무적 상태에 맞음: 팅!
	a = _buf(0.3)
	_tone(a, 0, 0.28, 2600, 2500, "sin", 0.35, 0.001, 2.0)
	_tone(a, 0, 0.2, 3900, 3800, "sin", 0.15, 0.001, 2.5)
	sounds["ting"] = _wav(a)

	# 보스 분노: 부글부글 크아앙!
	a = _buf(0.9)
	_tone(a, 0, 0.85, 120, 70, "saw", 0.4, 0.02, 0.6, 0.25, 22)
	_noise(a, 0, 0.8, 0.35, 0.15, 1.0, 0.8, 12.0)
	for i in 5:
		var f = randf_range(160, 300)
		_tone(a, i * 0.12, 0.08, f, f * 1.7, "sin", 0.25)
	sounds["rage"] = _wav(a)

	sounds["bgm"] = _build_bgm()


func _build_bgm() -> AudioStreamWAV:
	var e = 0.2  # 8분음표 길이 (150bpm)
	var a = _buf(e * 32)
	var roots = [130.81, 110.0, 87.31, 98.0]
	var mel = [
		0, 4, 7, 4, 12, 7, 4, 7,
		9, 7, 4, 0, 4, -99, 2, 4,
		5, 9, 12, 9, 5, 4, 2, 0,
		2, 7, 11, 14, 12, -99, 11, 7,
	]
	for i in 32:
		var t = i * e
		var r = roots[i / 8]
		var bf = r if i % 2 == 0 else r * 2.0
		_tone(a, t, e * 0.9, bf, bf, "sq", 0.09, 0.003, 1.2)
		if mel[i] != -99:
			var f = _note(mel[i])
			_tone(a, t, e * 0.85, f, f, "sq", 0.07, 0.003, 0.8)
			_tone(a, t, e * 0.85, f * 2.0, f * 2.0, "tri", 0.03, 0.003, 1.5)
		if i % 2 == 1:
			_noise(a, t, 0.04, 0.12, 1.0, 2.0)
		if i % 4 == 0:
			_tone(a, t, 0.1, 150, 50, "sin", 0.35)
	return _wav(a, true)
