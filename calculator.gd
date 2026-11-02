extends Control
signal calculation_submitted(raw_expression: String, result: float)

# Standalone four-function calculator.
# Clean version with all extra UI words removed.

const ART = preload("res://assets/calculator.png")
const BGM = preload("res://assets/8bit.mp3")
const BUTTON_CLICK = preload("res://assets/denielcz-immersivecontrol-button-click-sound-463065.mp3")
const CALCULATOR_FONT = preload("res://assets/Silkscreen-Regular.ttf")

const SCALE_FACTOR := 3.2
const MAX_DISPLAY_FONT_SIZE := 110
const MIN_DISPLAY_FONT_SIZE := 22
const DISPLAY_SIDE_PADDING := 12.0
const ART_WIDTH := 128.0
const ART_HEIGHT := 224.0

var expression_text := ""
var just_calculated := false
var showing_reaction := false
var reaction_id := 0

var result_label: Label
var expression_label: Label
var calculator_origin := Vector2.ZERO
var button_click_player: AudioStreamPlayer

const KEYS: Array = [
	["C", "DEL", "%", "÷"],
	["7", "8", "9", "×"],
	["4", "5", "6", "+"],
	["1", "2", "3", "−"],
	["±", "0", ".", "="]
]

func _ready() -> void:
	button_click_player = AudioStreamPlayer.new()
	button_click_player.name = "ButtonClickSound"
	button_click_player.stream = BUTTON_CLICK
	button_click_player.volume_db = 2.0
	add_child(button_click_player)

	_start_music()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_create_ui()
	_update_display()

func _create_ui() -> void:

	var background := ColorRect.new()
	background.color = Color.WHITE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -1

	var gradient_shader := Shader.new()
	gradient_shader.code = """
	shader_type canvas_item;

	void fragment() {
	    vec4 top_color = vec4(0.129, 0.102, 0.204, 1.0);
	    vec4 middle_color = vec4(0.400, 0.329, 0.486, 1.0);
	    vec4 bottom_color = vec4(0.616, 0.514, 0.635, 1.0);

	    float t = smoothstep(0.0, 1.0, UV.y);

	    vec4 color;

	    if (t < 0.5) {
	        color = mix(top_color, middle_color, smoothstep(0.0, 0.5, t));
	    } else {
	        color = mix(middle_color, bottom_color, smoothstep(0.5, 1.0, t));
	    }

	    COLOR = color;
	}
	"""

	var gradient_material := ShaderMaterial.new()
	gradient_material.shader = gradient_shader
	background.material = gradient_material

	add_child(background)


	calculator_origin = Vector2(
	1280.0 - ART_WIDTH * SCALE_FACTOR,
	720.0 - ART_HEIGHT * SCALE_FACTOR
)

	var art := TextureRect.new()
	art.texture = ART
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.position = calculator_origin
	art.size = Vector2(ART_WIDTH, ART_HEIGHT) * SCALE_FACTOR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.z_index = 2
	add_child(art)

	expression_label = Label.new()
	expression_label.position = calculator_origin + Vector2(18, 27)
	expression_label.size = Vector2(346, 40)
	expression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	expression_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	expression_label.add_theme_font_size_override("font_size", 17)
	expression_label.add_theme_color_override("font_color", Color("#d4cbe6"))
	expression_label.clip_text = true
	add_child(expression_label)

	result_label = Label.new()
	result_label.position = calculator_origin + Vector2(20, -10) * (SCALE_FACTOR / 3.0)
	result_label.size = Vector2(340, 160) * (SCALE_FACTOR / 3.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	result_label.add_theme_font_override("font", CALCULATOR_FONT)
	result_label.add_theme_font_size_override("font_size", 56)
	result_label.add_theme_color_override("font_color", Color("#fff6e8"))
	result_label.clip_text = true
	add_child(result_label)
	result_label.z_index = 3

	for row in range(5):
		for column in range(4):
			var symbol: String = KEYS[row][column]
			var hitbox := Button.new()
			hitbox.text = ""
			hitbox.flat = true
			hitbox.focus_mode = Control.FOCUS_NONE
			hitbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			hitbox.position = calculator_origin + Vector2(
				3.0 + column * 32.0,
				60.0 + row * 32.0
			) * SCALE_FACTOR

			hitbox.size = Vector2(27.0, 28.0) * SCALE_FACTOR
			hitbox.pressed.connect(_press.bind(symbol))
			add_child(hitbox)
			hitbox.z_index = 3

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
		KEY_KP_ADD: symbol = "+"
		KEY_KP_SUBTRACT, KEY_MINUS: symbol = "−"
		KEY_KP_MULTIPLY: symbol = "×"
		KEY_KP_DIVIDE, KEY_SLASH: symbol = "÷"
		KEY_PERIOD, KEY_KP_PERIOD: symbol = "."
		KEY_ENTER, KEY_KP_ENTER, KEY_EQUAL: symbol = "="
		KEY_BACKSPACE: symbol = "DEL"
		KEY_ESCAPE, KEY_DELETE: symbol = "C"

	if event.shift_pressed and event.keycode == KEY_8:
		symbol = "×"

	if event.shift_pressed and event.keycode == KEY_EQUAL:
		symbol = "+"

	if symbol != "":
		_press(symbol)
		get_viewport().set_input_as_handled()


func _press(symbol: String) -> void:
	if showing_reaction:
		showing_reaction = false
	button_click_player.stop()
	button_click_player.play()
	# Remember the previous expression so an input that
	# would overflow can be rejected safely.
	var previous_expression: String = expression_text
	var previous_calculated: bool = just_calculated

	if symbol == "C":
		expression_text = ""
		just_calculated = false

	elif symbol == "DEL":
		if just_calculated:
			just_calculated = false

		if not expression_text.is_empty():
			expression_text = expression_text.substr(
				0,
				expression_text.length() - 1
			)

	elif symbol == "=":
		_calculate()

	elif symbol == "±":
		_change_sign()

	elif symbol == "%":
		_percent()

	elif symbol in ["+", "−", "×", "÷"]:
		_add_operator(symbol)

	elif symbol == ".":
		_add_decimal()

	else:
		if just_calculated:
			expression_text = ""
			just_calculated = false

		if expression_text.length() < 44:
			expression_text += symbol

	# Reject any new input that exceeds the display's
	# minimum readable font size.
	if not _can_fit_display(expression_text):
		expression_text = previous_expression
		just_calculated = previous_calculated

	_update_display()


func _add_operator(symbol: String) -> void:
	if expression_text.is_empty():
		if symbol == "−":
			expression_text = "−"
		return

	if expression_text.ends_with("."):
		expression_text += "0"

	var last := expression_text.substr(expression_text.length() - 1)
	if last in ["+", "−", "×", "÷"]:
		expression_text = expression_text.substr(0, expression_text.length() - 1)

	expression_text += symbol
	just_calculated = false

func _add_decimal() -> void:
	if just_calculated:
		expression_text = ""
		just_calculated = false

	var section := expression_text
	for operator in ["+", "−", "×", "÷"]:
		section = section.get_slice(operator, section.get_slice_count(operator) - 1)

	if "." in section:
		return

	if expression_text.is_empty() or expression_text.ends_with("+") or expression_text.ends_with("−") or expression_text.ends_with("×") or expression_text.ends_with("÷"):
		expression_text += "0"

	expression_text += "."

func _change_sign() -> void:
	if expression_text.is_empty():
		expression_text = "−"
		return

	var split_at := -1
	for i in range(1, expression_text.length()):
		if expression_text.substr(i, 1) in ["+", "−", "×", "÷"]:
			split_at = i

	var prefix := expression_text.substr(0, split_at + 1)
	var number := expression_text.substr(split_at + 1)

	if number.is_empty():
		return

	if number.begins_with("−"):
		number = number.substr(1)
	else:
		number = "−" + number

	expression_text = prefix + number

func _percent() -> void:
	if expression_text.is_empty():
		return

	var computed = _evaluate_expression(expression_text)
	if computed == null:
		return

	calculation_submitted.emit(expression_text, float(computed))

	expression_text = _format_number(float(computed) / 100.0)
	just_calculated = true

func _calculate() -> void:
	if expression_text.is_empty():
		return

	var computed = _evaluate_expression(expression_text)
	if computed == null:
		return

	# Send the original equation to the battle controller.
	calculation_submitted.emit(expression_text, float(computed))

	# Then display the calculated result normally.
	expression_text = _format_number(float(computed))
	just_calculated = true

func _evaluate_expression(raw: String) -> Variant:
	# Evaluate strictly left to right.
	# Example: 54−27×2 = (54−27)×2 = 54.
	var clean := raw.replace("×", "*").replace("÷", "/").replace("−", "-")
	clean = clean.replace(" ", "")

	if clean.is_empty():
		return null

	var number_regex := RegEx.new()
	number_regex.compile("-?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)")

	var cursor := 0
	var first := number_regex.search(clean, cursor)

	if first == null or first.get_start() != cursor:
		return null

	var result := float(first.get_string())
	cursor = first.get_end()

	while cursor < clean.length():
		var operator := clean.substr(cursor, 1)

		if not operator in ["+", "-", "*", "/"]:
			return null

		cursor += 1

		var next_number := number_regex.search(clean, cursor)

		if next_number == null or next_number.get_start() != cursor:
			return null

		var number := float(next_number.get_string())
		cursor = next_number.get_end()

		match operator:
			"+":
				result += number
			"-":
				result -= number
			"*":
				result *= number
			"/":
				if is_zero_approx(number):
					return null
				result /= number

		if not is_finite(result) or absf(result) > 999999999999.0:
			return null

	return result

func _format_number(number: float) -> String:
	if absf(number) < 0.0000000001:
		return "0"

	if absf(number - roundf(number)) < 0.000000001:
		return str(int(roundf(number)))

	return ("%.8f" % number).trim_suffix("0").trim_suffix(".")


func _get_fitting_font_size(display_text: String) -> int:
	if result_label == null:
		return MAX_DISPLAY_FONT_SIZE

	var available_width: float = (
		result_label.size.x - DISPLAY_SIDE_PADDING
	)

	# Try progressively smaller fonts until the whole
	# expression fits inside the calculator screen.
	for font_size in range(
		MAX_DISPLAY_FONT_SIZE,
		MIN_DISPLAY_FONT_SIZE - 1,
		-1
	):
		var text_width: float = CALCULATOR_FONT.get_string_size(
			display_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		).x

		if text_width <= available_width:
			return font_size

	return MIN_DISPLAY_FONT_SIZE


func _can_fit_display(display_text: String) -> bool:
	if result_label == null:
		return true

	var available_width: float = (
		result_label.size.x - DISPLAY_SIDE_PADDING
	)

	var minimum_text_width: float = CALCULATOR_FONT.get_string_size(
		display_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		MIN_DISPLAY_FONT_SIZE
	).x

	return minimum_text_width <= available_width

func show_reaction(correct: bool) -> void:
	if result_label == null:
		return

	showing_reaction = true

	if correct:
		result_label.text = ":)"
	else:
		result_label.text = ":("

	# Match the normal calculator number display.
	result_label.add_theme_font_size_override(
		"font_size",
		_get_fitting_font_size("0")
	)

func _update_display() -> void:
	if result_label == null or showing_reaction:
		return

	var display_text: String = expression_text

	if display_text.is_empty():
		display_text = "0"

	# Always display the complete expression.
	result_label.text = display_text

	# Choose the largest font that actually fits.
	var fitted_size: int = _get_fitting_font_size(
		display_text
	)

	result_label.add_theme_font_size_override(
		"font_size",
		fitted_size
	)

	expression_label.text = ""

func _start_music() -> void:

	if get_tree().root.get_node_or_null("CalcuMonstersMusic") != null:
		return

	var music := AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	music.stream = BGM
	music.volume_db = -18.0
	music.autoplay = false
	add_child(music)

	# Loop continuously.
	if music.stream is AudioStreamMP3:
		music.stream.loop = true

	music.play()
