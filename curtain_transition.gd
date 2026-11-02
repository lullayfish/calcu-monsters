extends CanvasLayer

# CALCU-MONSTERS — TITLE CURTAIN TRANSITION
# Captures the complete title screen and opens it like two curtains.
# The live battle is revealed underneath. Reparents the music so it
# keeps its playback position through the scene change.

const DURATION := 2.1
const DIM_DURATION := 0.35
const DIM_TINT := Color(0.53, 0.51, 0.61, 1.0)
const CURTAIN_SOUND: AudioStream = preload("res://assets/freesound_community-curtain-82308.mp3")
const MUSIC_NODE_NAME := "CalcuMonstersMusic"

func _init() -> void:
	layer = 100


func begin(next_scene_path: String, music: AudioStreamPlayer) -> void:
	# Capture AFTER the title screen updates to show the correct answer.
	await RenderingServer.frame_post_draw

	var tree := get_tree()
	var image: Image = get_viewport().get_texture().get_image()
	var image_size: Vector2i = image.get_size()
	var halfway: int = floori(float(image_size.x) / 2.0)

	var left_image: Image = image.get_region(Rect2i(0, 0, halfway, image_size.y))
	var right_image: Image = image.get_region(Rect2i(halfway, 0, image_size.x - halfway, image_size.y))

	var left := _make_half(left_image, Vector2.ZERO)
	var right := _make_half(right_image, Vector2(float(halfway), 0.0))

	# Briefly darken the FULL title screen while the halves are still closed.
	# The new battle stays at its normal brightness behind them.
	var dim := create_tween().set_parallel(true)
	dim.tween_property(left, "modulate", DIM_TINT, DIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	dim.tween_property(right, "modulate", DIM_TINT, DIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await dim.finished

	# Preserve the currently playing MP3; do not call play() again.
	if is_instance_valid(music) and music.get_parent() != tree.root:
		music.reparent(tree.root)
		music.name = MUSIC_NODE_NAME

	var error: Error = tree.change_scene_to_file(next_scene_path)
	if error != OK:
		push_error("Unable to open battle scene: " + next_scene_path)
		queue_free()
		return

	# Wait until the battle is actually present behind our two halves.
	await tree.process_frame

	# The curtain SFX begins on the same frame as the opening animation.
	# Keep this player on the transition CanvasLayer, above the scene swap.
	var curtain_player := AudioStreamPlayer.new()
	curtain_player.name = "CurtainSound"
	curtain_player.stream = CURTAIN_SOUND
	curtain_player.volume_db = -5.0
	add_child(curtain_player)
	curtain_player.play()

	var opening := create_tween().set_parallel(true)
	opening.tween_property(left, "position:x", -float(halfway), DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	opening.tween_property(right, "position:x", float(image_size.x), DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await opening.finished
	queue_free()


func _make_half(part: Image, at: Vector2) -> TextureRect:
	var panel := TextureRect.new()
	panel.texture = ImageTexture.create_from_image(part)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.position = at
	panel.size = Vector2(part.get_size())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	return panel
