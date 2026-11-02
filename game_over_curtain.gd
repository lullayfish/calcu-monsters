extends CanvasLayer

# CALCU-MONSTERS — GAME OVER CLOSING CURTAINS (Godot 4.x)
# Call game_over_curtain.gd's begin() once when the final heart is lost.
# Curtains slide IN over the live battle, then click/tap anywhere to replay.

const CURTAIN_DURATION := 2.1
const BATTLE_SCENE := "res://main.tscn"
const FONT: Font = preload("res://assets/Silkscreen-Regular.ttf")
const CURTAIN_SFX: AudioStream = preload("res://assets/freesound_community-curtain-82308.mp3")
const MUSIC_NODE_NAME := "CalcuMonstersMusic"
const CURTAIN_COLOUR := Color("#292038")
const TEXT_COLOUR := Color("#FFE0C5")

var _ready_to_restart := false
var _restarting := false
var _left: ColorRect
var _right: ColorRect
var _message: Label
var _prompt: Label
var _replay_pulse: Tween
var _split_text: Array[Label] = []

func _init() -> void:
	layer = 120

func begin() -> void:
	# Add the CanvasLayer to get_tree().root before calling begin().
	var viewport_size := get_viewport().get_visible_rect().size
	var width := viewport_size.x
	var height := viewport_size.y
	var half := width * 0.5

	_left = _make_curtain(Vector2(-half, 0.0), Vector2(half, height), false)
	_right = _make_curtain(Vector2(width, 0.0), Vector2(half, height), true)
	_message = _make_label("GAME OVER", 72, TEXT_COLOUR, Vector2(0.0, height * 0.33), Vector2(width, 105.0))
	_prompt = _make_label("CLICK ANYWHERE TO PLAY AGAIN", 24, Color("#E9D4F5"), Vector2(0.0, height * 0.52), Vector2(width, 60.0))
	_message.modulate.a = 0.0
	_prompt.modulate.a = 0.0

	var sound := AudioStreamPlayer.new()
	sound.name = "ClosingCurtainSound"
	sound.stream = CURTAIN_SFX
	sound.volume_db = -5.0
	add_child(sound)
	sound.play()

	var close := create_tween().set_parallel(true)
	close.tween_property(_left, "position:x", 0.0, CURTAIN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	close.tween_property(_right, "position:x", half, CURTAIN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await close.finished

	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(_message, "modulate:a", 1.0, 0.35)
	reveal.tween_property(_prompt, "modulate:a", 1.0, 0.5)

	await reveal.finished
	_ready_to_restart = true


	# Make the replay instruction pulse in size and brightness.
	_prompt.pivot_offset = _prompt.size / 2.0

	_replay_pulse = create_tween()
	var pulse := _replay_pulse
	pulse.set_loops()
	pulse.set_parallel(true)

	pulse.tween_property(
		_prompt, "scale", Vector2(1.10, 1.10), 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	pulse.tween_property(
		_prompt, "modulate:a", 0.65, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	pulse.chain().tween_property(
		_prompt, "scale", Vector2.ONE, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	pulse.tween_property(
		_prompt, "modulate:a", 1.0, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _make_curtain(at: Vector2, dimensions: Vector2, _right_side: bool) -> ColorRect:
	var panel := ColorRect.new()
	panel.position = at
	panel.size = dimensions
	panel.color = CURTAIN_COLOUR
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	return panel

func _make_label(value: String, font_size: int, colour: Color, at: Vector2, dimensions: Vector2) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _input(event: InputEvent) -> void:
	if not _ready_to_restart or _restarting:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_restart()


func _attach_split_text(panel: ColorRect, is_right: bool) -> void:
	# Clip each half of the words to its own moving curtain.
	panel.clip_contents = true

	var half_width: float = panel.size.x
	var full_width: float = half_width * 2.0
	var height: float = panel.size.y
	var text_offset: float = -half_width if is_right else 0.0

	var game_over := _make_label(
		"GAME OVER", 72, TEXT_COLOUR,
		Vector2(text_offset, height * 0.33),
		Vector2(full_width, 105.0)
	)
	game_over.reparent(panel, false)
	game_over.position = Vector2(text_offset, height * 0.33)
	_split_text.append(game_over)

	var replay := _make_label(
		"CLICK ANYWHERE TO PLAY AGAIN", 24,
		Color("#E9D4F5"),
		Vector2(text_offset, height * 0.52),
		Vector2(full_width, 60.0)
	)
	replay.reparent(panel, false)
	replay.position = Vector2(text_offset, height * 0.52)
	_split_text.append(replay)



func _restart() -> void:
	if _restarting:
		return

	_restarting = true
	_ready_to_restart = false

	# Stop the original pulsing so the split text doesn't move.
	if _replay_pulse != null and _replay_pulse.is_running():
		_replay_pulse.kill()

	# Reset the instruction to its normal size and brightness.
	_prompt.scale = Vector2.ONE
	_prompt.modulate.a = 1.0

	# Attach matching left/right halves of both text labels.
	_attach_split_text(_left, false)
	_attach_split_text(_right, true)

	# Hide the stationary originals only after the split copies exist.
	_message.hide()
	_prompt.hide()

	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var half: float = viewport_width * 0.5

	# Load the new encounter behind the closed curtains.
	var error: Error = get_tree().change_scene_to_file(BATTLE_SCENE)

	if error != OK:
		push_error("Could not restart Calcu-Monsters: " + BATTLE_SCENE)
		_restarting = false
		_message.show()
		_prompt.show()
		_ready_to_restart = true
		for label in _split_text:
			if is_instance_valid(label):
				label.queue_free()
		_split_text.clear()
		return

	await get_tree().process_frame

	# Play the 2.1-second opening curtain sound.
	var sound := AudioStreamPlayer.new()
	sound.name = "ReplayCurtainSound"
	sound.stream = CURTAIN_SFX
	sound.volume_db = -5.0
	add_child(sound)
	sound.play()

	# Both curtain halves and their attached text slide outward.
	var opening := create_tween()
	opening.set_parallel(true)

	opening.tween_property(
		_left, "position:x", -half, CURTAIN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	opening.tween_property(
		_right, "position:x", viewport_width, CURTAIN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await opening.finished

	queue_free()
