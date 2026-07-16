class_name AudioManager
extends Node

const MUSIC_SPACE_AMBIENT_PATH := "res://assets/audio/music/number_orbit_ambient.wav"
const SFX_PATHS := {
	"ui_tap": "res://assets/audio/sfx/ui/tap.wav",
	"popup_open": "res://assets/audio/sfx/popup/open.wav",
	"popup_close": "res://assets/audio/sfx/popup/close.wav",
	"orbit_select": "res://assets/audio/sfx/game/orbit_select.wav",
	"invalid": "res://assets/audio/sfx/game/invalid.wav",
	"hint_reveal": "res://assets/audio/sfx/game/hint_reveal.wav",
	"level_complete": "res://assets/audio/sfx/game/level_complete.wav",
}

const MUSIC_GAIN_DB := -18.0
const SFX_GAIN_DB := 0.0
const QUIET_DB := -80.0
const MUSIC_FADE_IN_SECONDS := 2.0
const MUSIC_FADE_OUT_SECONDS := 0.45
const MUSIC_RESUME_FADE_SECONDS := 0.9
const MUSIC_CROSSFADE_SECONDS := 5.0
const HAPTIC_PREVIEW_MIX_RATE := 44100
const HAPTIC_PREVIEW_GAIN_DB := -8.0

# Семантические события хаптиков (маппятся на паттерны в `_pattern_for`).
# Осознанный минимализм: НЕТ событий на валидный ход и на победу — вибро = редкий
# сигнал «обрати внимание», а не постоянный фидбэк (см. play_level_complete / 2.1-2.2).
#   LIGHT   — тонкое подтверждение (свитчер вибро, отказной тап по серому)
#   WARNING — «нельзя/внимание» (неверный tutorial-ход, закрытый уровень, тупик)
#   ERROR   — самое сильное: опасное/деструктивное действие (сброс всего прогресса)
enum Haptic { LIGHT, WARNING, ERROR }

static var current: AudioManager

var music_player: AudioStreamPlayer
var music_players: Array[AudioStreamPlayer] = []
var music_stream: AudioStream
var music_fade_tween: Tween
var music_crossfade_tween: Tween
var active_music_player_index := 0
var music_loop_duration := 0.0
var music_crossfading := false
var music_faded_for_pause := false
var music_volume := 80
var sound_volume := 80
var haptics_enabled := true
var rng := RandomNumberGenerator.new()
var sfx_streams: Dictionary = {}
var haptic_preview_streams: Dictionary = {}

func _ready() -> void:
	current = self
	rng.randomize()
	load_sfx()
	music_stream = load_audio_stream(MUSIC_SPACE_AMBIENT_PATH)
	if music_stream != null:
		music_loop_duration = music_stream.get_length()
		for i in range(2):
			var player := AudioStreamPlayer.new()
			player.name = "MusicPlayer%d" % (i + 1)
			player.stream = music_stream
			player.volume_db = QUIET_DB
			player.finished.connect(_on_music_finished.bind(player))
			add_child(player)
			music_players.append(player)
		music_player = music_players[0]

func _exit_tree() -> void:
	if music_fade_tween != null and music_fade_tween.is_valid():
		music_fade_tween.kill()
	if music_crossfade_tween != null and music_crossfade_tween.is_valid():
		music_crossfade_tween.kill()
	for child in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
	if current == self:
		current = null

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless" or music_faded_for_pause or music_crossfading:
		return
	if music_loop_duration <= MUSIC_CROSSFADE_SECONDS or music_players.is_empty():
		return
	var active := active_music_player()
	if active == null or not active.playing:
		return
	if active.get_playback_position() >= music_loop_duration - MUSIC_CROSSFADE_SECONDS:
		crossfade_music_loop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		fade_music_for_pause()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		resume_music_from_pause()

func configure(music_percent: int, sound_percent: int, enable_haptics: bool = true) -> void:
	haptics_enabled = enable_haptics
	set_volumes(music_percent, sound_percent)
	start_music()

func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled

func set_volumes(music_percent: int, sound_percent: int) -> void:
	music_volume = int(clamp(music_percent, 0, 100))
	sound_volume = int(clamp(sound_percent, 0, 100))
	if music_crossfading:
		return
	var active := active_music_player()
	if active != null:
		if active.playing and not music_faded_for_pause:
			fade_music_to(target_music_db(), 0.12)
		elif not active.playing:
			set_all_music_volumes(target_music_db())

func start_music() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var active := active_music_player()
	if active == null or active.stream == null:
		return
	if active.playing:
		if music_faded_for_pause:
			resume_music_from_pause()
		return
	music_faded_for_pause = false
	music_crossfading = false
	stop_inactive_music_players()
	active.volume_db = QUIET_DB
	active.play()
	fade_music_to(target_music_db(), MUSIC_FADE_IN_SECONDS)

func fade_music_for_pause() -> void:
	var active := active_music_player()
	if active == null or not active.playing:
		return
	if music_crossfade_tween != null and music_crossfade_tween.is_valid():
		music_crossfade_tween.kill()
	music_crossfading = false
	music_faded_for_pause = true
	fade_music_to(QUIET_DB, MUSIC_FADE_OUT_SECONDS)

func resume_music_from_pause() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var active := active_music_player()
	if active == null or active.stream == null:
		return
	if not active.playing:
		active.volume_db = QUIET_DB
		active.play()
	music_faded_for_pause = false
	fade_music_to(target_music_db(), MUSIC_RESUME_FADE_SECONDS)

func fade_music_to(target_db: float, duration: float) -> void:
	var active := active_music_player()
	if active == null:
		return
	if music_fade_tween != null and music_fade_tween.is_valid():
		music_fade_tween.kill()
	music_fade_tween = create_tween()
	for i in range(music_players.size()):
		var player := music_players[i]
		var player_target := target_db if i == active_music_player_index else QUIET_DB
		var tween := music_fade_tween.tween_property(player, "volume_db", player_target, duration)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if i < music_players.size() - 1:
			music_fade_tween.parallel()

func target_music_db() -> float:
	return volume_db(music_volume, MUSIC_GAIN_DB)

func active_music_player() -> AudioStreamPlayer:
	if active_music_player_index < 0 or active_music_player_index >= music_players.size():
		return null
	return music_players[active_music_player_index]

func inactive_music_player() -> AudioStreamPlayer:
	if music_players.size() < 2:
		return null
	return music_players[1 - active_music_player_index]

func set_all_music_volumes(volume_db_value: float) -> void:
	for player in music_players:
		player.volume_db = volume_db_value

func stop_inactive_music_players() -> void:
	for i in range(music_players.size()):
		if i != active_music_player_index:
			music_players[i].stop()
			music_players[i].volume_db = QUIET_DB

func crossfade_music_loop() -> void:
	var from_player := active_music_player()
	var to_player := inactive_music_player()
	if from_player == null or to_player == null:
		return
	music_crossfading = true
	if music_fade_tween != null and music_fade_tween.is_valid():
		music_fade_tween.kill()
	if music_crossfade_tween != null and music_crossfade_tween.is_valid():
		music_crossfade_tween.kill()
	to_player.stop()
	to_player.volume_db = QUIET_DB
	to_player.play()
	music_crossfade_tween = create_tween()
	music_crossfade_tween.tween_method(apply_music_crossfade.bind(from_player, to_player), 0.0, 1.0, MUSIC_CROSSFADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	music_crossfade_tween.finished.connect(func() -> void:
		from_player.stop()
		from_player.volume_db = QUIET_DB
		to_player.volume_db = target_music_db()
		active_music_player_index = 1 - active_music_player_index
		music_player = to_player
		music_crossfading = false
	)

func apply_music_crossfade(mix: float, from_player: AudioStreamPlayer, to_player: AudioStreamPlayer) -> void:
	var target_db := target_music_db()
	var angle: float = clampf(mix, 0.0, 1.0) * PI * 0.5
	from_player.volume_db = volume_db_with_gain(target_db, cos(angle))
	to_player.volume_db = volume_db_with_gain(target_db, sin(angle))

func load_sfx() -> void:
	sfx_streams.clear()
	for key in SFX_PATHS:
		var stream := load_audio_stream(str(SFX_PATHS[key]))
		if stream != null:
			sfx_streams[key] = stream

func load_audio_stream(path: String) -> AudioStream:
	if path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	if path.ends_with(".mp3"):
		return AudioStreamMP3.load_from_file(path)
	if path.ends_with(".wav"):
		return AudioStreamWAV.load_from_file(path)
	return load(path) as AudioStream

func play_sfx_key(key: String, gain_db: float = SFX_GAIN_DB, pitch_jitter: float = 0.0) -> void:
	play_sfx(sfx_streams.get(key, null) as AudioStream, gain_db, pitch_jitter)

func play_sfx(stream: AudioStream, gain_db: float = SFX_GAIN_DB, pitch_jitter: float = 0.0) -> void:
	if stream == null or sound_volume <= 0:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db(sound_volume, gain_db)
	if pitch_jitter > 0.0:
		player.pitch_scale = rng.randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == null or music_crossfading:
		return
	if player != active_music_player():
		player.stop()
		player.volume_db = QUIET_DB
		return
	player.volume_db = QUIET_DB
	player.play()
	if music_faded_for_pause:
		return
	fade_music_to(target_music_db(), MUSIC_RESUME_FADE_SECONDS)

func volume_db(percent: int, gain_db: float) -> float:
	var normalized: float = clamp(float(percent) / 100.0, 0.0, 1.0)
	if normalized <= 0.001:
		return QUIET_DB
	return linear_to_db(normalized) + gain_db

func volume_db_with_gain(base_db: float, linear_gain: float) -> float:
	if linear_gain <= 0.001:
		return QUIET_DB
	return base_db + linear_to_db(clamp(linear_gain, 0.0, 1.0))

static func play_ui_tap() -> void:
	if current != null:
		current.play_sfx_key("ui_tap", -9.0, 0.025)

static func play_popup_open() -> void:
	if current != null:
		current.play_sfx_key("popup_open", -8.0, 0.015)

static func play_popup_close() -> void:
	if current != null:
		current.play_sfx_key("popup_close", -9.0, 0.015)

# Валидный ход — БЕЗ виброотклика (осознанно): вибро зарезервировано только под
# редкие события-алерты (тупик), чтобы не перенасыщать и не смешивать сигналы.
static func play_orbit_select() -> void:
	if current != null:
		current.play_sfx_key("orbit_select", -7.0, 0.035)

# Тап по недоступному (серому) спутнику — лёгкий «отказной» отклик (см. задачу 1.2).
# Вызывается механикой серых спутников; операцию НЕ применяет.
static func play_orbit_rejected_haptic() -> void:
	if current != null:
		current.emit_haptic(Haptic.LIGHT)

# A valid operation that would break the tutorial's winning path is a real
# warning, unlike tapping an unavailable grey orbit number.
static func play_tutorial_wrong_move_haptic() -> void:
	if current != null:
		current.emit_haptic(Haptic.WARNING)

static func play_invalid() -> void:
	if current != null:
		current.play_sfx_key("invalid", -7.0, 0.015)

# Раскрытие подсказки — БЕЗ вибро (осознанно): потенциальный конфликт с рекламой
# (rewarded-подсказка). Остаётся только звук.
static func play_hint_reveal() -> void:
	if current != null:
		current.play_sfx_key("hint_reveal", -7.0, 0.01)

# Победа — БЕЗ виброотклика (осознанно): вибро = сигнал «обрати внимание» (тупик →
# Рестарт). Если бы победа вибрировала, её финальный тап + вибро дали бы «кашу» и
# путались бы с сигналом провала. Праздник несут звук + конфетти + анимация центра.
static func play_level_complete() -> void:
	if current != null:
		current.play_sfx_key("level_complete", -5.5, 0.0)

static func play_no_valid_moves_haptic() -> void:
	if current != null:
		current.emit_haptic(Haptic.WARNING)

static func play_locked_level_haptic() -> void:
	if current != null:
		current.emit_haptic(Haptic.WARNING)

static func play_reset_progress_haptic() -> void:
	if current != null:
		current.emit_haptic(Haptic.ERROR)

static func confirm_haptics_enabled() -> void:
	if current != null:
		current.emit_haptic(Haptic.LIGHT)

# ============================================================================
# Хаптики: семантические события + по-платформенные бэкенды.
#   iOS → нативный Taptic Engine (задача 2.3, сейчас заглушка) → иначе паттерн-вибро.
#   Android/Web → Input.vibrate_handheld. Desktop → синтез-превью (play_haptic_preview).
# Значения длительностей/амплитуд собраны в одном месте (`_pattern_for`).
# ============================================================================

func emit_haptic(event: Haptic) -> void:
	if DisplayServer.get_name() == "headless" or not haptics_enabled:
		return
	if _try_native_haptic(event):
		return
	_play_pattern(_pattern_for(event))

# Паттерн = массив «пульсов»; шаг = {delay: пауза перед пульсом (с), ms, amp}.
func _pattern_for(event: Haptic) -> Array:
	match event:
		Haptic.LIGHT:
			# Тонкий подтверждающий тик: вкл. свитчер вибро, отказной тап по серому.
			return [{"delay": 0.0, "ms": 18, "amp": 0.30}]
		Haptic.WARNING:
			# «Нельзя/внимание»: неверный tutorial-ход, закрытый уровень или тупик.
			return [{"delay": 0.0, "ms": 26, "amp": 0.48}]
		Haptic.ERROR:
			# Самое сильное — опасное/деструктивное действие (сброс всего прогресса).
			# Самый заметный одиночный импульс, сильнее всех остальных сигналов.
			return [{"delay": 0.0, "ms": 36, "amp": 0.62}]
	return []

func _play_pattern(pattern: Array) -> void:
	for raw_step in pattern:
		var step: Dictionary = raw_step as Dictionary
		var delay := float(step.get("delay", 0.0))
		if delay > 0.0:
			var tree := get_tree()
			if tree == null:
				return
			await tree.create_timer(delay).timeout
			if not is_inside_tree() or not haptics_enabled:
				return
		_pulse(int(step.get("ms", 16)), float(step.get("amp", 0.4)))

func _pulse(duration_ms: int, amplitude: float) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms, amplitude)
	else:
		play_haptic_preview(duration_ms, amplitude)

# Задача 2.3: когда подключён нативный iOS-плагин Taptic Engine — проиграть событие
# через него и вернуть true. Пока плагина нет — false, используется паттерн-вибро.
func _try_native_haptic(_event: Haptic) -> bool:
	return false

# Temporary desktop stand-in for handheld vibration. Streams are generated at
# the requested duration, cached, and never shipped as separate audio assets.
func play_haptic_preview(duration_ms: int, amplitude: float) -> void:
	var cache_key := "%d:%d" % [duration_ms, int(round(amplitude * 100.0))]
	var stream := haptic_preview_streams.get(cache_key, null) as AudioStreamWAV
	if stream == null:
		stream = generate_haptic_preview(duration_ms, amplitude)
		haptic_preview_streams[cache_key] = stream
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = HAPTIC_PREVIEW_GAIN_DB
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func generate_haptic_preview(duration_ms: int, amplitude: float) -> AudioStreamWAV:
	var duration_seconds := maxf(0.001, float(duration_ms) / 1000.0)
	var sample_count := maxi(1, int(round(duration_seconds * HAPTIC_PREVIEW_MIX_RATE)))
	var edge_samples := mini(sample_count / 2, int(round(HAPTIC_PREVIEW_MIX_RATE * 0.003)))
	var peak := lerpf(0.20, 0.46, clampf(amplitude, 0.0, 1.0))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in range(sample_count):
		var time := float(i) / float(HAPTIC_PREVIEW_MIX_RATE)
		var envelope := 1.0
		if edge_samples > 0:
			envelope = minf(
				clampf(float(i) / float(edge_samples), 0.0, 1.0),
				clampf(float(sample_count - 1 - i) / float(edge_samples), 0.0, 1.0)
			)
		var fundamental := sin(TAU * 145.0 * time)
		var body := sin(TAU * 72.5 * time)
		var value := (fundamental * 0.82 + body * 0.18) * envelope * peak
		pcm.encode_s16(i * 2, int(round(clampf(value, -1.0, 1.0) * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = HAPTIC_PREVIEW_MIX_RATE
	stream.stereo = false
	stream.data = pcm
	return stream
