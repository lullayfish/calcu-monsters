extends Control

const ROUND_SECONDS := 120.0
const FONT = preload("res://assets/Silkscreen-Regular.ttf")
const SYMBOL_FONT = preload("res://assets/NotoSansSymbols-VariableFont_wght.ttf")
const MONSTER_DEFEAT_SOUND = preload("res://assets/universfield-impact-thud-291047.mp3")
const PLAYER_DAMAGE_SOUND = preload("res://assets/freesound_community-short-beep-tone-47916.mp3")
const SKIP_SOUND = preload("res://assets/dragon-studio-simple-whoosh-382724.mp3")


const BOSS_MUSIC: AudioStream = preload("res://assets/bossmusic.mp3")
const MUSIC_FADE_DURATION := 1.5
const BOSS_MUSIC_VOLUME := -18.0

var boss_music_player: AudioStreamPlayer
var music_fade: Tween
var boss_music_active := false

@onready var boss_aura: Control = get_parent().get_node_or_null("Boss/BossAura") as Control

var rng := RandomNumberGenerator.new()
var encounter := 0
var target := 0
var current_challenge: Dictionary = {}
var rule_type := ""
var required_value := ""
var current_boss_name := "Monster"

var encounter_label: Label
var timer_label: Label
var monster_label: Label
var target_heading_label: Label
var target_value_label: Label
var rule_label: RichTextLabel
var status_label: Label

var finishing_round := false
const MAX_LIVES := 3
var lives := MAX_LIVES
const MAX_SKIPS := 3
var skips := MAX_SKIPS
var skip_panel: Panel
var skip_icon_panels: Array[Panel] = []
var skip_key_panel: Panel
var round_timer: Timer
var damage_overlay: ColorRect
var damage_tween: Tween


func _ready() -> void:
	rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 8

	_create_ui()
	var damage_sound_player := AudioStreamPlayer.new()
	damage_sound_player.name = "PlayerDamageSound"
	damage_sound_player.stream = PLAYER_DAMAGE_SOUND
	damage_sound_player.volume_db = -8.0
	add_child(damage_sound_player)
	var defeat_sound_player := AudioStreamPlayer.new()
	defeat_sound_player.name = "MonsterDefeatSound"
	defeat_sound_player.stream = MONSTER_DEFEAT_SOUND
	defeat_sound_player.volume_db = 3.0
	add_child(defeat_sound_player)
	_create_damage_overlay()
	_setup_boss_music()

	var skip_sound_player := AudioStreamPlayer.new()
	skip_sound_player.name = "SkipSound"
	skip_sound_player.stream = SKIP_SOUND
	skip_sound_player.volume_db = -8.0
	add_child(skip_sound_player)

	round_timer = Timer.new()
	round_timer.one_shot = true
	round_timer.wait_time = ROUND_SECONDS
	add_child(round_timer)
	round_timer.timeout.connect(_on_time_out)

	var calculator := get_parent()
	calculator.calculation_submitted.connect(_check_answer)

	set_process(true)
	call_deferred("_start_encounter")


func _process(_delta: float) -> void:
	if round_timer == null:
		return

	var total_seconds := maxi(0, ceili(round_timer.time_left))
	var minutes := floori(float(total_seconds) / 60.0)
	var seconds := total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _create_ui() -> void:
	# Compact 790x132 HUD; layout uses fixed coordinates so elements cannot overlap.
	position = Vector2(22, 18)
	size = Vector2(790, 132)

	# Use Panel, not PanelContainer: PanelContainer automatically manages child layout.
	var panel := Panel.new()
	panel.position = Vector2.ZERO
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.23, 0.18, 0.33, 0.94)
	panel_style.border_color = Color("#B9A7D1")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(9)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	encounter_label = _make_label(Vector2(18, 9), Vector2(410, 24), 18, Color("#F3D8ED"))
	monster_label = _make_label(Vector2(18, 38), Vector2(490, 29), 19, Color("#FFF6EA"))
	rule_label = RichTextLabel.new()
	rule_label.position = Vector2(18, 65)
	rule_label.size = Vector2(490, 32)
	rule_label.bbcode_enabled = false
	rule_label.scroll_active = false
	rule_label.fit_content = false
	rule_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rule_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule_label.add_theme_font_override("normal_font", FONT)
	rule_label.add_theme_font_size_override("normal_font_size", 17)
	rule_label.add_theme_color_override("default_color", Color("#E7D8EE"))
	add_child(rule_label)
	status_label = _make_label(Vector2(18, 99), Vector2(490, 22), 14, Color("#FFDFAF"))

	# Timer separated from the encounter message.
	var timer_panel := Panel.new()
	timer_panel.position = Vector2(670, 8)
	timer_panel.size = Vector2(102, 30)
	timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var timer_style := StyleBoxFlat.new()
	timer_style.bg_color = Color("#514167")
	timer_style.border_color = Color("#B9A7D1")
	timer_style.set_border_width_all(2)
	timer_style.set_corner_radius_all(7)
	timer_panel.add_theme_stylebox_override("panel", timer_style)
	add_child(timer_panel)
	timer_label = _make_label(Vector2(670, 3), Vector2(102, 27), 19, Color("#FFF0DD"))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Target uses a single container, but its text has separate, non-overlapping slots.
	var target_panel := Panel.new()
	target_panel.position = Vector2(540, 44)
	target_panel.size = Vector2(232, 78)
	target_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var target_style := StyleBoxFlat.new()
	target_style.bg_color = Color("#564576")
	target_style.border_color = Color("#C8B7DD")
	target_style.set_border_width_all(2)
	target_style.set_corner_radius_all(9)
	target_panel.add_theme_stylebox_override("panel", target_style)
	add_child(target_panel)

	target_heading_label = _make_label(Vector2(544, 48), Vector2(224, 20), 13, Color("#E7D8EE"))
	target_heading_label.text = "TARGET"
	target_heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_value_label = _make_label(Vector2(544, 59), Vector2(224, 45), 33, Color("#FFF4DA"))
	target_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Golden skip counter, displayed beside the hearts.
	_update_skip_display()

func _make_label(at: Vector2, dimensions: Vector2, font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _setup_boss_music() -> void:
	boss_music_player = AudioStreamPlayer.new()
	boss_music_player.name = "BossMusic"
	boss_music_player.stream = BOSS_MUSIC
	boss_music_player.volume_db = -80.0

	if boss_music_player.stream is AudioStreamMP3:
		boss_music_player.stream.loop = true

	add_child(boss_music_player)

	# Restore normal volume when starting a fresh run.
	var normal_music := _get_normal_music()
	if normal_music != null:
		normal_music.volume_db = -18.0


func _get_normal_music() -> AudioStreamPlayer:
	# Music preserved by the opening title-screen curtains.
	var music := get_tree().root.get_node_or_null(
		"CalcuMonstersMusic"
	) as AudioStreamPlayer

	if music != null:
		return music

	# Fallback for launching the battle scene directly in Godot.
	return get_parent().get_node_or_null(
		"BackgroundMusic"
	) as AudioStreamPlayer


func _switch_boss_music(enable: bool) -> void:
	if boss_music_active == enable:
		return

	boss_music_active = enable

	if music_fade != null and music_fade.is_running():
		music_fade.kill()

	var normal_music := _get_normal_music()

	if enable:
		boss_music_player.volume_db = -80.0
		boss_music_player.play()

		music_fade = create_tween()
		music_fade.set_parallel(true)

		if normal_music != null:
			music_fade.tween_property(
				normal_music, "volume_db", -80.0,
				MUSIC_FADE_DURATION
			)

		music_fade.tween_property(
			boss_music_player, "volume_db",
			BOSS_MUSIC_VOLUME, MUSIC_FADE_DURATION
		)

	else:
		music_fade = create_tween()
		music_fade.set_parallel(true)

		music_fade.tween_property(
			boss_music_player, "volume_db",
			-80.0, MUSIC_FADE_DURATION
		)

		if normal_music != null:
			music_fade.tween_property(
				normal_music, "volume_db",
				-18.0, MUSIC_FADE_DURATION
			)


func _start_encounter(_fade_in: bool = false) -> void:
	finishing_round = true
	encounter += 1

	var director = get_parent().get_node("EncounterDirector")

	# Spawn a regular monster, or a boss every fifth encounter.
	director.spawn_for_round(encounter)

	# Every fifth encounter gets the special boss soundtrack.
	_switch_boss_music(encounter % 5 == 0)

	# Give bosses a glowing aura.
	if boss_aura != null:
		boss_aura.set_active(encounter % 5 == 0)

	# Randomize the battlefield after the first encounter.
	if encounter > 1:
		var previous_floor = get_parent().get_node_or_null("Floor")
		if previous_floor != null:
			previous_floor.randomize_floor()

	# Clear the calculator.
	get_parent().expression_text = ""
	get_parent().just_calculated = false
	get_parent()._update_display()

	# Generate the challenge using our new difficulty system.
	current_challenge = director.generate_for_round(encounter)
	target = int(current_challenge["target"])

	current_boss_name = _get_boss_name()
	_refresh_ui()


	# Fade in the new monster and floor together.
	var boss_node := get_parent().get_node_or_null("Boss") as CanvasItem
	var floor_node := get_parent().get_node_or_null("Floor") as CanvasItem

	if boss_node != null:
		boss_node.modulate = Color.WHITE
		boss_node.modulate.a = 0.0

	if floor_node != null:
		floor_node.modulate.a = 0.0

	# The first monster and floor appear instantly.
	if encounter == 1:
		if boss_node != null:
			boss_node.modulate.a = 1.0

		if floor_node != null:
			floor_node.modulate.a = 1.0

		finishing_round = false
		round_timer.start()
		return

	var fade_in_tween := create_tween()
	fade_in_tween.set_parallel(true)

	if boss_node != null:
		fade_in_tween.tween_property(
			boss_node,
			"modulate:a",
			1.0,
			2.0
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if floor_node != null:
		fade_in_tween.tween_property(
			floor_node,
			"modulate:a",
			1.0,
			2.0
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await fade_in_tween.finished


	finishing_round = false
	round_timer.start()

func _refresh_ui() -> void:
	encounter_label.text = "ENCOUNTER %02d" % encounter

	if encounter % 5 == 0:
		monster_label.text = "A wild boss %s has appeared!" % current_boss_name
	else:
		monster_label.text = "A wild %s has appeared!" % current_boss_name

	# Fit the text for BOTH regular monsters and bosses.
	_fit_monster_name_text()

	target_value_label.text = str(target)
	_set_rule_text(str(current_challenge["instruction"]))
	status_label.text = "PRESS = TO ATTACK  •  SHIFT TO SKIP"

# Use Noto for every mathematical symbol in the battle prompt,
# while keeping Silkscreen for all letters and numbers.
func _set_rule_text(instruction: String) -> void:
	rule_label.clear()
	for character in instruction:
		if character in ["+", "−", "-", "×", "÷", "=", "%", "±", "*", "/", "•"]:
			rule_label.push_font(SYMBOL_FONT)
			rule_label.add_text(character)
			rule_label.pop()
		else:
			rule_label.add_text(character)


func _get_boss_name() -> String:
	var boss = get_parent().get_node_or_null("Boss")
	if boss == null:
		return "Monster"

	# Prefer the explicit name if the boss script supplies one.
	var registered_name: String = str(boss.get("current_boss_name"))
	if registered_name != "" and registered_name != "<null>" and registered_name != "Monster":
		return registered_name

	# Fall back to the texture's file name; works with the original boss script.
	if boss is TextureRect and boss.texture != null:
		var raw: String = boss.texture.resource_path.get_file().get_basename()
		if not raw.is_empty():
			return raw.replace("_", " ").capitalize()

	return "Monster"



func _generate_challenge() -> void:
	var a: int
	var b: int
	var c: int
	var d: int
	var solution: String
	var difficulty: int = mini(encounter, 35)

	# Introduce increasingly difficult challenge types.
	var challenge_pool: Array[String] = ["mixed", "three_ops"]

	if encounter >= 4:
		challenge_pool.append("required_digit")

	if encounter >= 7:
		challenge_pool.append("forbidden_digit")

	if encounter >= 10:
		challenge_pool.append("four_ops")

	rule_type = challenge_pool[rng.randi_range(
		0, challenge_pool.size() - 1
	)]

	# Numbers gradually increase with progression.
	var upper: int = 12 + difficulty * 2

	a = rng.randi_range(8, upper)
	b = rng.randi_range(3, 12 + floori(float(difficulty) / 4.0))
	c = rng.randi_range(2, 9)
	d = rng.randi_range(2, 8)

	match rule_type:
		"mixed":
			var combinations: Array[String] = [
				"+−", "+×", "+÷",
				"−×", "−÷", "×÷"
			]

			if encounter >= 4:
				combinations.append_array([
					"+−×", "+−÷", "+×÷", "−×÷"
				])

			if encounter >= 9:
				combinations.append("+−×÷")

			required_value = combinations.pick_random()

			var challenge := _build_mixed_solution(required_value)
			target = challenge["target"]

		"three_ops":
			# Example: 24 + 7 × 5 − 6 = 53
			target = a + b * c - d
			required_value = "3"

		"required_digit":
			# Construct a guaranteed solution first.
			target = a + b * c
			solution = str(a) + "+" + str(b) + "×" + str(c)

			var digits: Array[String] = []
			for character in solution:
				if character in "0123456789":
					digits.append(character)

			required_value = digits.pick_random()

		"forbidden_digit":
			# Select a digit absent from the known solution.
			target = a + b * c
			solution = str(a) + "+" + str(b) + "×" + str(c)

			var candidates: Array[String] = []
			for digit in "0123456789":
				if not solution.contains(digit):
					candidates.append(digit)

			required_value = candidates.pick_random()

		"four_ops":
			# Example: 30 + 8 × 5 − 6 + 3 = 67
			target = a + b * c - d + rng.randi_range(2, 9)
			required_value = "4"

func _get_rule_short_text() -> String:
	match rule_type:
		"mixed":
			return "USE ONLY " + " ".join(
				required_value.split("")
			)

		"three_ops":
			return "USE AT LEAST 3 OPERATIONS"

		"required_digit":
			return "INCLUDE DIGIT %s; USE ONLY + AND ×" % required_value

		"forbidden_digit":
			return "AVOID DIGIT %s; USE ONLY + AND ×" % required_value
			
		"four_ops":
			return "USE AT LEAST 4 OPERATIONS"

	return "REACH THE TARGET"


func _check_answer(raw_expression: String, result: float) -> void:
	if finishing_round or round_timer.is_stopped():
		return

	var director = get_parent().get_node("EncounterDirector")

	# Check the target, allowed operations, and digit restrictions.
	var valid: bool = director.validate(
		raw_expression,
		result,
		current_challenge
	)

	if valid:
		get_parent().show_reaction(true)
		_win_encounter()
	else:
		get_parent().show_reaction(false)
		_lose_life()

func _win_encounter() -> void:
	if finishing_round:
		return
	finishing_round = true
	round_timer.stop()
	status_label.text = "%s defeated!" % current_boss_name
	$MonsterDefeatSound.play()

	if encounter % 5 == 0:
		_switch_boss_music(false)

		if boss_aura != null:
			boss_aura.set_active(false)

	var boss_node := get_parent().get_node_or_null("Boss") as Control
	if boss_node != null:
		_flash_boss_red(boss_node)
		# Shake around the current anchored position; do not touch the
		# boss's separate squishy scale tween.
		var original_position := boss_node.position
		var shake := create_tween()
		for i in range(16):
			var direction := -1.0 if i % 2 == 0 else 1.0
			var strength := 18.0 * (1.0 - float(i) / 20.0)
			shake.tween_property(
				boss_node, "position:x", original_position.x + direction * strength, 0.045
			)
		shake.tween_property(boss_node, "position", original_position, 0.06)
		await shake.finished

	# Swaps the boss and floor while the old boss is invisible,
	# then fades in the new boss before starting the next timer.
	await _fade_out_battlefield()
	_start_encounter()


func _skip_encounter() -> void:
	# No skipping during transitions, Game Over,
	# or when there are no skips remaining.
	if finishing_round or lives <= 0 or skips <= 0:
		return

	if round_timer.is_stopped():
		return

	finishing_round = true
	round_timer.stop()

	# Spend one free skip.
	skips -= 1
	_update_skip_display()
	$SkipSound.play()

	status_label.text = "MONSTER SKIPPED! %d SKIPS LEFT" % skips

	# Fade out both monster and floor together.
	await _fade_out_battlefield()

	# Instantly reveal the next encounter.
	_start_encounter()

func _on_time_out() -> void:
	if finishing_round or lives <= 0:
		return

	finishing_round = true
	round_timer.stop()

	# Running out of time costs one heart.
	lives -= 1
	queue_redraw()
	_flash_damage()
	$PlayerDamageSound.play()

	# If no hearts remain, end the game.
	if lives <= 0:
		_show_game_over_curtains()
		return

	# Otherwise, the monster escapes.
	status_label.text = "TIME'S UP! ONE HEART LOST!"

	# Fade out both monster and floor together.
	await _fade_out_battlefield()

	# Instantly reveal the next encounter.
	_start_encounter()

func _flash_boss_red(boss_node: Control) -> void:
	if boss_node == null:
		return

	# Apply a red tint directly to the monster sprite.
	boss_node.modulate = Color("#FF4444")

	# Gradually restore its original colours.
	var flash_tween := create_tween()
	flash_tween.tween_property(
		boss_node,
		"modulate",
		Color.WHITE,
		0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _count_operations(raw_expression: String) -> int:
	var count := 0

	for i in range(raw_expression.length()):
		var character := raw_expression.substr(i, 1)

		if character in ["+", "×", "÷"]:
			count += 1
		elif character == "−" and i > 0:
			count += 1

	return count

# PIXEL HEARTS — DRAWN DIRECTLY IN GODOT

func _draw() -> void:
	var heart_pixels := [
		"01100110",
		"11111111",
		"11111111",
		"01111110",
		"00111100",
		"00011000"
	]

	# Golden pixel tickets, aligned with the existing hearts.
	var ticket_start := Vector2(220, 148)
	var ticket_spacing := 48.0
	var ticket_pixel := 4.0

	var ticket_pixels := [
		"011111110",
		"111111111",
		"110111011",
		"110111011",
		"110111011",
		"111111111",
		"011111110"
	]

	for ticket_index in range(MAX_SKIPS):
		var ticket_colour := Color("#F4C975")

		if ticket_index >= skips:
			ticket_colour = Color("#695969")

		var ticket_origin := ticket_start + Vector2(
			float(ticket_index) * ticket_spacing,
			0
		)

		for row_index in range(ticket_pixels.size()):
			var pixel_row: String = ticket_pixels[row_index]

			for col_index in range(pixel_row.length()):
				if pixel_row.substr(col_index, 1) != "1":
					continue

				draw_rect(
					Rect2(
						ticket_origin + Vector2(
							float(col_index) * ticket_pixel,
							float(row_index) * ticket_pixel
						),
						Vector2(ticket_pixel, ticket_pixel)
					),
					ticket_colour
				)

	var pixel_size := 5.0
	var heart_spacing := 55.0
	var heart_start := Vector2(18, 148)

	for heart_index in range(MAX_LIVES):
		var heart_colour := Color("#EB525D")

		if heart_index >= lives:
			heart_colour = Color("#695969")

		var origin := heart_start + Vector2(
			float(heart_index) * heart_spacing,
			0
		)

		for row_index in range(heart_pixels.size()):
			var row: String = heart_pixels[row_index]

			for column_index in range(row.length()):
				if row.substr(column_index, 1) != "1":
					continue

				var pixel_position := origin + Vector2(
					float(column_index) * pixel_size,
					float(row_index) * pixel_size
				)

				draw_rect(
					Rect2(
						pixel_position,
						Vector2(pixel_size, pixel_size)
					),
					heart_colour
				)

func _show_game_over_curtains() -> void:
	var game_over: Node = load("res://game_over_curtain.gd").new()
	get_tree().root.add_child(game_over)
	game_over.begin()

func _lose_life() -> void:
	if finishing_round or lives <= 0:
		return

	lives -= 1
	queue_redraw()
	_flash_damage()
	$PlayerDamageSound.play()

	if lives > 0:
		status_label.text = "WRONG ANSWER! %d LIVES LEFT" % lives

	else:
		finishing_round = true
		round_timer.stop()
		_show_game_over_curtains()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.keycode == KEY_SHIFT and lives > 0:
		if skips > 0 and not finishing_round and not round_timer.is_stopped():
			_skip_encounter()
			get_viewport().set_input_as_handled()
		return

func _build_mixed_solution(operators: String) -> Dictionary:
	var difficulty: int = mini(encounter, 35)

	var has_add := operators.contains("+")
	var has_sub := operators.contains("−")
	var has_mul := operators.contains("×")
	var has_div := operators.contains("÷")

	var expression := ""
	var result := 0

	if has_mul:
		var factor := rng.randi_range(3, 8 + floori(float(difficulty) / 5.0))
		var multiplier := rng.randi_range(3, 9)

		if has_div:
			var divisor := rng.randi_range(2, 6)
			var numerator := factor * divisor
			expression = "%d×%d÷%d" % [
				numerator, multiplier, divisor
			]
			result = factor * multiplier
		else:
			expression = "%d×%d" % [factor, multiplier]
			result = factor * multiplier

	elif has_div:
		var divisor := rng.randi_range(2, 9)
		var quotient := rng.randi_range(8, 20 + difficulty)
		expression = "%d÷%d" % [
			quotient * divisor, divisor
		]
		result = quotient

	else:
		result = rng.randi_range(20, 40 + difficulty * 2)
		expression = str(result)

	if has_add:
		var addition := rng.randi_range(5, 15 + difficulty)
		expression += "+%d" % addition
		result += addition

	if has_sub:
		var maximum_subtraction: int = maxi(2, result - 1)
		var subtraction := rng.randi_range(
			2, mini(maximum_subtraction, 15 + difficulty)
		)
		expression += "−%d" % subtraction
		result -= subtraction

	return {
		"expression": expression,
		"target": result
	}

func _update_skip_display() -> void:
	queue_redraw()

	if status_label == null:
		return

	if skips <= 0:
		status_label.text = "PRESS = TO ATTACK  •  OUT OF SKIPS"
	else:
		status_label.text = "PRESS = TO ATTACK  •  SHIFT TO SKIP"


func _make_skip_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _make_skip_pip_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if active:
		style.bg_color = Color("#F4C975")
		style.border_color = Color("#FFF4D0")
	else:
		style.bg_color = Color("#665B7E")
		style.border_color = Color("#8D82A8")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


func _create_skip_ui() -> void:
	skip_panel = Panel.new()
	skip_panel.position = Vector2(210, 156)
	skip_panel.size = Vector2(220, 44)
	skip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_panel.add_theme_stylebox_override(
		"panel",
		_make_skip_style(Color("#3B3155"), Color("#C4B8E2"))
	)
	add_child(skip_panel)

	var title := Label.new()
	title.text = "SKIPS"
	title.position = Vector2(12, 10)
	title.size = Vector2(60, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#FFE7A8"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_panel.add_child(title)

	skip_icon_panels.clear()
	for i in range(MAX_SKIPS):
		var pip := Panel.new()
		pip.position = Vector2(78 + i * 28, 12)
		pip.size = Vector2(22, 18)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.add_theme_stylebox_override("panel", _make_skip_pip_style(true))
		skip_panel.add_child(pip)
		skip_icon_panels.append(pip)

	skip_key_panel = Panel.new()
	skip_key_panel.position = Vector2(172, 8)
	skip_key_panel.size = Vector2(36, 26)
	skip_key_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_key_panel.add_theme_stylebox_override(
		"panel",
		_make_skip_style(Color("#544874"), Color("#D4C8EF"))
	)
	skip_panel.add_child(skip_key_panel)

	var key_label := Label.new()
	key_label.text = "S"
	key_label.position = Vector2(0, 0)
	key_label.size = skip_key_panel.size
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_override("font", FONT)
	key_label.add_theme_font_size_override("font_size", 15)
	key_label.add_theme_color_override("font_color", Color("#FFF9F0"))
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_key_panel.add_child(key_label)

func _create_damage_overlay() -> void:
	damage_overlay = ColorRect.new()
	damage_overlay.name = "DamageOverlay"
	damage_overlay.color = Color("#D94A57", 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Cover the entire 1280x720 game screen.
	damage_overlay.position = -position
	damage_overlay.size = Vector2(1280, 720)

	# Draw over the battlefield, HUD, and calculator.
	damage_overlay.z_index = 100

	add_child(damage_overlay)

func _flash_damage() -> void:
	if damage_overlay == null:
		return

	# Prevent overlapping flashes if multiple hearts are lost.
	if damage_tween != null and damage_tween.is_running():
		damage_tween.kill()

	# Soft red tint, not an opaque full-screen flash.
	damage_overlay.color = Color("#E63946", 0.45)

	damage_tween = create_tween()
	damage_tween.tween_property(
		damage_overlay,
		"color:a",
		0.0,
		0.45
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _fade_out_battlefield() -> void:
	var boss_node := get_parent().get_node_or_null("Boss") as CanvasItem
	var floor_node := get_parent().get_node_or_null("Floor") as CanvasItem

	var fade := create_tween()
	fade.set_parallel(true)

	if boss_node != null:
		fade.tween_property(
			boss_node,
			"modulate:a",
			0.0,
			2.0
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if floor_node != null:
		fade.tween_property(
			floor_node,
			"modulate:a",
			0.0,
			2.0
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await fade.finished

func _fit_monster_name_text() -> void:
	var available_width: float = monster_label.size.x - 8.0

	for font_size in range(22, 13, -1):
		var text_width: float = FONT.get_string_size(
			monster_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		).x

		if text_width <= available_width:
			monster_label.add_theme_font_size_override(
				"font_size",
				font_size
			)
			return

	monster_label.add_theme_font_size_override("font_size", 12)
