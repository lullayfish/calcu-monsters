extends Control

# CALCU-MONSTERS — INTERACTIVE TITLE SCREEN (Godot 4.x)
# Full-height calculator: solve an easy equation and press = to begin.
# Uses two distinct random original bosses and foot-anchored squish tweens.
# Attach to the root of the existing title_screen.tscn.

const FONT: Font = preload("res://assets/Silkscreen-Regular.ttf")
const CALCULATOR: Texture2D = preload("res://assets/calculator.png")
const GAME_SCENE := "res://main.tscn"
const CURTAIN_SCENE_SCRIPT = preload("res://curtain_transition.gd")
const TITLE_BGM: AudioStream = preload("res://assets/8bit.mp3")
const TITLE_CLICK: AudioStream = preload("res://assets/denielcz-immersivecontrol-button-click-sound-463065.mp3")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const CALCULATOR_ART_SIZE := Vector2(128.0, 224.0)
const CALCULATOR_SCALE := 720.0 / 224.0
const CREAM := Color("#FFF2DE")
const PEACH := Color("#FFD7A6")
const LAVENDER := Color("#D8BFE7")

const GRASS_TOP := 610.0
const LEFT_BOSS_FEET := Vector2(218.0, 655.0)
const RIGHT_BOSS_FEET := Vector2(1062.0, 655.0)


# Original bosses only; deliberately excludes colour variants.
const BOSS_FILES: Array[String] = [
	"bamboo", "bamouth", "beetle_leaf", "butterfleye", "candlesnake",
	"centipede", "crystal", "dragon", "electric_bat", "electric_rat",
	"flamevil", "frog", "goblinbat", "goblinboss", "goblinmage",
	"golem", "hatchegg", "hornheart", "lamp", "mimic_fountain",
	"molicorn", "mushroom", "mustarock", "mutant", "racoon",
	"radish_plant", "shell", "skeleton", "slime", "slime_bat",
	"snowman", "spidercloud", "spiritflam", "thunder_cloud",
	"triple_goblin_king", "volcanocrab", "walking_bomb", "walking_moon",
	"water_snake"
]

const KEYS: Array = [
	["C", "DEL", "%", "÷"],
	["7", "8", "9", "×"],
	["4", "5", "6", "+"],
	["1", "2", "3", "−"],
	["±", "0", ".", "="]
]

var rng := RandomNumberGenerator.new()
var calculator_origin := Vector2.ZERO
var screen_title: Label
var screen_equation: Label
var screen_hint: Label
var entered_answer := ""
var correct_answer := 0
var question_text := ""
var starting := false
var music_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var title_bosses: Array[TextureRect] = []


func _ready() -> void:
	rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_gameplay_sky()
	_start_audio()
	_generate_equation()
	_build_scene()
	_update_screen()
	queue_redraw()
	_add_credit_label()


func _start_audio() -> void:
	music_player = get_node("/root/CalcuMonstersMusic") as AudioStreamPlayer
	music_player.volume_db = -18.0

	if not music_player.playing:
		music_player.play()

	click_player = AudioStreamPlayer.new()
	click_player.name = "TitleButtonClick"
	click_player.stream = TITLE_CLICK
	click_player.volume_db = 2.0
	add_child(click_player)


func _draw() -> void:
	var sky_top := Color("#211A35")
	var sky_bottom := Color("#987DA4")
	for y in range(0, 720, 5):
		var t := float(y) / 720.0
		var smooth_t := t * t * (3.0 - 2.0 * t)
		draw_rect(Rect2(0, y, 1280, 5), sky_top.lerp(sky_bottom, smooth_t))

	# The clouds, moon, and floating particles are drawn by the SAME
	# scripts as the battle scene, rather than title-only imitations.
	# Keep grass and shadows in the title screen's own drawing.
	_draw_grass_strip()

	# Animated shadows that squash and stretch with each monster.
	for creature in title_bosses:
		if not is_instance_valid(creature):
			continue

		# Keep the shadow anchored to the monster's feet.
		var feet: Vector2 = creature.get_meta("shadow_feet")

		# Read the monster's existing squish animation.
		var squash_x: float = creature.scale.x
		var squash_y: float = creature.scale.y

		# Scale the shadow to the monster's size.
		var base_width: float = clampf(
			creature.size.x * 0.30, 30.0, 95.0
		)
		var base_height: float = clampf(
			creature.size.y * 0.06, 8.0, 20.0
		)

		# Wider when squashed, narrower when stretched.
		var shadow_width: float = base_width * squash_x
		var shadow_height: float = base_height * squash_x / squash_y

		# Subtle opacity changes make the shadow feel alive.
		var shadow_opacity: float = clampf(
			0.24 + (squash_x - 1.0) * 0.35,
			0.18,
			0.32
		)

		_draw_ground_shadow(
			feet + Vector2(0.0, -2.0),
			Vector2(shadow_width, shadow_height),
			Color(0.20, 0.27, 0.23, shadow_opacity)
		)

func _draw_ground_shadow(centre: Vector2, radii: Vector2, tint: Color) -> void:
	var vertices := PackedVector2Array()
	for i in range(33):
		var angle := TAU * float(i) / 32.0
		vertices.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(vertices, tint)


func _add_gameplay_sky() -> void:
	# Reuse gameplay clouds and moon, but show only the sections that
	# belong in the open sky beside the giant central calculator.
	var sky_path := "res://night_sky.gd"
	var particles_path := "res://ambient_particles.gd"

	if ResourceLoader.exists(sky_path):
		var sky_script: Script = load(sky_path)

		# Original left-hand clouds. The far-right cloud in this copy
		# stays outside the clipped left panel.
		_add_clipped_sky_layer(
			sky_script, "LeftClouds",
			Rect2(0.0, 0.0, 430.0, 610.0), Vector2(0.0, -70.0)
		)

		# Right clouds are staged separately so neither wanders
		# across the moon. Both are still drawn/animated by night_sky.gd.
		# The first uses the game's large cloud, farther left and higher.
		_add_clipped_sky_layer(
			sky_script, "RightLowerCloud",
			Rect2(820.0, 195.0, 240.0, 120.0), Vector2(760.0, -45.0)
		)

		# The second uses the game's smaller cloud in the far-right
		# sky, safely below and to the right of the crescent moon.
		_add_clipped_sky_layer(
			sky_script, "RightFarCloud",
			Rect2(1080.0, 235.0, 200.0, 95.0), Vector2(825.0, 60.0)
		)

		# Keep the real pixel crescent from gameplay in its own window.
		# Clipping it separately avoids bringing along extra clouds.
		_add_clipped_sky_layer(
			sky_script, "RightMoon",
			Rect2(990.0, 85.0, 190.0, 165.0), Vector2(375.0, -70.0)
		)
	else:
		push_warning("Could not find the in-game night sky: " + sky_path)

	# Sparkles are intentionally NOT clipped: keep the full, beautiful
	# title-screen coverage that is already working.
	if ResourceLoader.exists(particles_path):
		var particle_script: Script = load(particles_path)
		_add_title_sky_layer(particle_script, "LeftSparkles", Vector2.ZERO)
		_add_title_sky_layer(particle_script, "RightSparkles", Vector2(420.0, 0.0))
	else:
		push_warning("Could not find the in-game particles: " + particles_path)


func _add_clipped_sky_layer(source_script: Script, layer_name: String, visible_area: Rect2, offset: Vector2) -> void:
	# Only show the desired screen region. Child can animate freely;
	# its drawing never crosses outside this title-screen panel.
	var window := Control.new()
	window.name = layer_name + "Window"
	window.position = visible_area.position
	window.size = visible_area.size
	window.clip_contents = true
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.z_index = 0
	add_child(window)

	# Offset the scripted scene within the clip window. The wrapper
	# protects against gameplay scripts setting their own position.
	var placement := Control.new()
	placement.name = layer_name + "Placement"
	placement.position = offset - visible_area.position
	placement.size = DESIGN_SIZE
	placement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(placement)

	var effect := Control.new()
	effect.name = layer_name
	effect.size = DESIGN_SIZE
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.set_script(source_script)
	placement.add_child(effect)


func _add_title_sky_layer(source_script: Script, layer_name: String, offset: Vector2) -> void:
	# Existing full-width particle-layer behaviour is unchanged.
	var placement := Control.new()
	placement.name = layer_name + "Placement"
	placement.position = offset
	placement.size = DESIGN_SIZE
	placement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placement.z_index = 0
	add_child(placement)

	var effect := Control.new()
	effect.name = layer_name
	effect.size = DESIGN_SIZE
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.set_script(source_script)
	placement.add_child(effect)


func _draw_grass_strip() -> void:
	# A straight, gently shaded meadow — no hills or curves.
	# The bosses' feet are near y = 645, so the edge sits at y = 610.
	var grass_y := int(GRASS_TOP)
	var grass_bottom := 720
	var top_colour := Color("#A0CF76")
	var bottom_colour := Color("#568B48")

	for y in range(grass_y, grass_bottom, 2):
		var t := float(y - grass_y) / float(grass_bottom - grass_y)
		var shade := top_colour.lerp(bottom_colour, t)
		draw_rect(Rect2(0.0, float(y), 1280.0, 2.0), shade)

	# Clean, straight top edge — no jagged lawn silhouette.
	draw_rect(Rect2(0.0, float(grass_y), 1280.0, 3.0), Color("#C5E8A2"))

	# Tiny pixel tufts and flowers, fixed in place so they never flicker.
	# The calculator covers the centre, so details focus on each side.
	var tufts := [
		Vector2(32, 648), Vector2(82, 699), Vector2(129, 660),
		Vector2(194, 686), Vector2(256, 655), Vector2(331, 704),
		Vector2(397, 665), Vector2(873, 696), Vector2(919, 653),
		Vector2(991, 701), Vector2(1053, 667), Vector2(1121, 703),
		Vector2(1181, 654), Vector2(1240, 693)
	]
	for spot in tufts:
		_draw_pixel_grass_tuft(spot)

	var flowers := [
		Vector2(53, 680), Vector2(105, 642), Vector2(173, 705),
		Vector2(228, 670), Vector2(294, 693), Vector2(375, 646),
		Vector2(906, 681), Vector2(971, 644), Vector2(1031, 695),
		Vector2(1098, 659), Vector2(1162, 704), Vector2(1231, 648)
	]
	for i in range(flowers.size()):
		_draw_pixel_flower(flowers[i], i % 3)


func _draw_pixel_grass_tuft(at: Vector2) -> void:
	var blade := Color("#47783E")
	draw_rect(Rect2(at.x, at.y, 3.0, 8.0), blade)
	draw_rect(Rect2(at.x - 4.0, at.y + 3.0, 3.0, 5.0), blade)
	draw_rect(Rect2(at.x + 4.0, at.y + 2.0, 3.0, 6.0), blade)


func _draw_pixel_flower(at: Vector2, colour_index: int) -> void:
	var petals := [Color("#FFE7F1"), Color("#E8CDF8"), Color("#FFF7DA")]
	var petal: Color = petals[colour_index]
	var stem := Color("#47783E")
	var middle := Color("#FFD47D")
	# Each petal is a crisp 4x4 pixel square.
	draw_rect(Rect2(at.x, at.y + 5.0, 3.0, 12.0), stem)
	draw_rect(Rect2(at.x, at.y - 4.0, 4.0, 4.0), petal)
	draw_rect(Rect2(at.x - 4.0, at.y, 4.0, 4.0), petal)
	draw_rect(Rect2(at.x + 4.0, at.y, 4.0, 4.0), petal)
	draw_rect(Rect2(at.x, at.y + 4.0, 4.0, 4.0), petal)
	draw_rect(Rect2(at.x, at.y, 4.0, 4.0), middle)


func _generate_equation() -> void:
	# Always positive, one-operation arithmetic, answer 0..18.
	var mode := rng.randi_range(0, 2)
	var a := rng.randi_range(2, 9)
	var b := rng.randi_range(1, 9)
	match mode:
		0:
			correct_answer = a + b
			question_text = "%d + %d = ?" % [a, b]
		1:
			if a < b:
				var swap := a
				a = b
				b = swap
			correct_answer = a - b
			question_text = "%d - %d = ?" % [a, b]
		2:
			a = rng.randi_range(2, 5)
			b = rng.randi_range(2, 4)
			correct_answer = a * b
			question_text = "%d × %d = ?" % [a, b]


func _build_scene() -> void:
	# Exactly from the top edge to the bottom edge: 224 x (720 / 224).
	calculator_origin = Vector2((DESIGN_SIZE.x - CALCULATOR_ART_SIZE.x * CALCULATOR_SCALE) * 0.5, 0.0)

	# Two different original boss sprites from res://assets/boss/.
	var options: Array[String] = BOSS_FILES.duplicate()
	options.shuffle()
	_add_boss(options[0], LEFT_BOSS_FEET, 302.0)
	_add_boss(options[1], RIGHT_BOSS_FEET, 302.0)

	var calc := TextureRect.new()
	calc.name = "TitleCalculator"
	calc.texture = CALCULATOR
	calc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	calc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	calc.stretch_mode = TextureRect.STRETCH_SCALE
	calc.position = calculator_origin
	calc.size = CALCULATOR_ART_SIZE * CALCULATOR_SCALE
	calc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calc.z_index = 3
	add_child(calc)

	# All the lettering belongs ON the calculator screen.
	var screen_x := calculator_origin.x + 12.0 * CALCULATOR_SCALE
	var screen_width := 104.0 * CALCULATOR_SCALE

	screen_title = _make_screen_label(
		"CALCU-MONSTERS",
		Vector2(screen_x, 10.0),
		Vector2(screen_width, 48.0),
		32,
		PEACH
	)

	screen_equation = _make_screen_label(
		"",
		Vector2(screen_x, 65.0),
		Vector2(screen_width, 65.0),
		30,
		CREAM
	)

	screen_hint = _make_screen_label(
		"",
		Vector2(screen_x, 149.0),
		Vector2(screen_width, 22.0),
		13,
		LAVENDER
	)


	# Invisible hitboxes calibrated to the actual printed keys.
	for row in range(5):
		for column in range(4):
			var key_symbol: String = KEYS[row][column]
			var hitbox := Button.new()
			hitbox.text = ""
			hitbox.flat = true
			hitbox.focus_mode = Control.FOCUS_NONE
			hitbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			hitbox.position = calculator_origin + Vector2(3.0 + column * 32.0, 60.0 + row * 32.0) * CALCULATOR_SCALE
			hitbox.size = Vector2(27.0, 28.0) * CALCULATOR_SCALE
			hitbox.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			hitbox.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
			hitbox.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
			hitbox.z_index = 4
			hitbox.pressed.connect(_press_key.bind(key_symbol))
			add_child(hitbox)


func _make_screen_label(value: String, pos: Vector2, dims: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = dims
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 4
	add_child(label)
	return label


func _add_boss(boss_name: String, feet: Vector2, maximum_size: float) -> void:
	var path := "res://assets/boss/%s.png" % boss_name
	if not ResourceLoader.exists(path):
		push_warning("Title boss missing: " + path)
		return
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var creature := TextureRect.new()
	creature.texture = texture
	creature.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	creature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	creature.stretch_mode = TextureRect.STRETCH_SCALE
	var dimensions := texture.get_size()
	var scale_value := minf(maximum_size / dimensions.x, maximum_size / dimensions.y)
	creature.size = dimensions * scale_value
	creature.position = feet - Vector2(creature.size.x * 0.5, creature.size.y)
	creature.pivot_offset = Vector2(creature.size.x * 0.5, creature.size.y)
	creature.mouse_filter = Control.MOUSE_FILTER_IGNORE
	creature.z_index = 2
	add_child(creature)
	title_bosses.append(creature)
	creature.set_meta("shadow_feet", feet)
	# Foot-anchored squish: same three poses as the battle sprites.
	var squish := create_tween().set_loops()
	squish.tween_property(creature, "scale", Vector2(1.07, 0.93), 0.48).set_trans(Tween.TRANS_SINE)
	squish.tween_property(creature, "scale", Vector2(0.95, 1.06), 0.48).set_trans(Tween.TRANS_SINE)
	squish.tween_property(creature, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_SINE)

func _update_screen(message: String = "") -> void:
	# Replace the question mark with the player's typed answer.
	var displayed_answer: String = "?"

	if not entered_answer.is_empty():
		displayed_answer = entered_answer

	screen_equation.text = question_text.replace(
		"?",
		displayed_answer
	)

	# Keep the existing bottom instruction.
	screen_hint.text = (
		message if not message.is_empty()
		else "ANSWER, THEN PRESS ="
	)

	var text_width: float = FONT.get_string_size(
		screen_hint.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14
	).x

	if text_width > screen_hint.size.x:
		screen_hint.add_theme_font_size_override("font_size", 11)
	else:
		screen_hint.add_theme_font_size_override("font_size", 14)

func _press_key(symbol: String) -> void:
	if music_player != null and not music_player.playing:
		music_player.play()
	if starting:
		return
	if click_player != null:
		click_player.stop()
		click_player.play()
	if symbol in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
		if entered_answer.length() < 2:
			entered_answer += symbol
		_update_screen()
	elif symbol == "C":
		entered_answer = ""
		_update_screen()
	elif symbol == "DEL":
		if not entered_answer.is_empty():
			entered_answer = entered_answer.substr(0, entered_answer.length() - 1)
		_update_screen()
	elif symbol == "=":
		_submit_answer()

func _submit_answer() -> void:
	if entered_answer.is_empty() or starting:
		return

	if int(entered_answer) == correct_answer:
		starting = true
		screen_equation.text = question_text.replace(
			"?",
			entered_answer
		)
		screen_hint.text = "CORRECT!"
		var curtain := CURTAIN_SCENE_SCRIPT.new()
		get_tree().root.add_child(curtain)
		curtain.begin(GAME_SCENE, music_player)
	else:
		entered_answer = ""
		_update_screen("TRY AGAIN")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var symbol := ""
	match event.keycode:
		KEY_0, KEY_KP_0: symbol = "0"
		KEY_1, KEY_KP_1: symbol = "1"
		KEY_2, KEY_KP_2: symbol = "2"
		KEY_3, KEY_KP_3: symbol = "3"
		KEY_4, KEY_KP_4: symbol = "4"
		KEY_5, KEY_KP_5: symbol = "5"
		KEY_6, KEY_KP_6: symbol = "6"
		KEY_7, KEY_KP_7: symbol = "7"
		KEY_8, KEY_KP_8: symbol = "8"
		KEY_9, KEY_KP_9: symbol = "9"
		KEY_ENTER, KEY_KP_ENTER, KEY_EQUAL: symbol = "="
		KEY_BACKSPACE: symbol = "DEL"
		KEY_ESCAPE, KEY_DELETE: symbol = "C"
	if symbol != "":
		_press_key(symbol)
		get_viewport().set_input_as_handled()

func _add_credit_label() -> void:
	var credit := Label.new()
	credit.name = "LullayfishCredit"
	credit.text = "MADE BY LULLAYFISH"

	credit.position = Vector2(440, 700)
	credit.size = Vector2(390, 18)

	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	credit.add_theme_font_override(
		"font",
		preload("res://assets/Silkscreen-Regular.ttf")
	)
	credit.add_theme_font_size_override("font_size", 11)
	credit.add_theme_color_override(
		"font_color",
		Color("#E8D9F3")
	)

	credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit.z_index = 20
	add_child(credit)

func _process(_delta: float) -> void:
	queue_redraw()
