extends Control

# CALCU-MONSTERS — RANDOM MONSTER CHATTER
# Attach to a new Control child named MonsterDialogue under CalculatorGame.
# Requires sibling nodes Boss and BattleController.

const FONT: Font = preload("res://assets/Silkscreen-Regular.ttf")
const BUBBLE_WIDTH := 360.0
const MAX_BUBBLE_WIDTH := 810.0
const BUBBLE_HEIGHT := 88.0
const VIEW_WIDTH := 1280.0
const LEFT_AREA_RIGHT := 850.0


const GENERAL_LINES: Array[String] = [
	"I studied for this. Sort of.",
	"Please don't use long division.",
	"My weakness? Mathematics.",
	"Does this count as cardio?",
	"I was promised snacks.",
	"I'm actually very intimidating.",
	"Is that a calculator?!",
	"I have a family of integers.",
	"I can count to... several.",
	"Wait. Are you good at math?",
	"I demand a recount!",
	"My accountant warned me.",
	"This battle is tax deductible.",
	"I forgot my evil speech.",
	"If I win, do I get soup?",
	"I'm just here for the vibes.",
	"What is a fraction, anyway?",
	"I majored in dramatic entrances.",
	"I have zero regrets. Zero!",
	"The numbers are judging me.",
	"I don't get paid enough for this.",
	"I hope you're bad at subtraction.",
	"Would you accept a hug instead?",
	"My evil plan has a decimal point.",
	"Please ignore the nervous sweating.",
	"I'm doing my best, okay?!",
	"I peaked in kindergarten.",
	"Can we settle this with rock-paper-scissors?",
	"I have a PhD in being a nuisance.",
	"The calculator knows too much.",
	"I'd like to speak to your denominator.",
	"My lawyer says I can leave.",
	"This wasn't in the job description.",
	"I'm emotionally attached to the number 7.",
	"I have committed several math crimes.",
	"Do I look like a word problem to you?",
	"I brought a pencil. For intimidation.",
	"I ate my homework. And the teacher.",
	"Are we allowed to use our fingers?",
	"My brain is buffering.",
	"I would like to unsubscribe from algebra.",
	"You're ruining my villain origin story.",
	"Nobody told me there'd be numbers.",
	"I'm legally considered a rounding error.",
	"My last opponent used a spreadsheet.",
	"I charge extra for multiplication.",
	"I am powered entirely by bad decisions.",
	"My therapist recommended fewer equations.",
	"I put the FUN in fundamental arithmetic.",
	"Please don't tell my mum I lost."
]

const SPECIAL_LINES := {
	"dragon": ["I breathe fire, not formulas.", "My treasure is mostly coupons."],
	"slime": ["I'm 80% water, 20% panic.", "I have no bones to calculate."],
	"mushroom": ["I'm a pretty fungi, actually.", "I grew here by accident."],
	"goblin": ["I stole my multiplication table.", "This is a legal goblin business."],
	"skeleton": ["I have a bone to pick with math.", "I'm literally falling apart here."],
	"frog": ["Ribbit. That's my final answer.", "I leap to conclusions."],
	"snake": ["Sssssseven is my favourite.", "I have a sssssuspicion."],
	"snowman": ["I'm having a meltdown.", "Can we keep this cool?"],
	"rat": ["I smell cheese. And danger.", "Squeak equals squeak."],
	"bat": ["I'm bat at arithmetic.", "Don't make me do bat-gebra."],
	"moon": ["Don't ask about my phases.", "I'm over the moon. Obviously."],
	"crystal": ["My future looks divisible.", "I have excellent facets."],
	"cloud": ["I'm under a lot of pressure.", "Chance of math: 100%."],
	"golem": ["I am rock solid at guessing.", "This is a grave situation."],
	"bomb": ["No pressure. Tick tock.", "I am a blast at parties."]
}

var rng := RandomNumberGenerator.new()
var boss: TextureRect
var battle: Node
var bubble: Control
var dialogue_label: Label
var active_tween: Tween
var seconds_until_chatter := 0.0
var visible_remaining := 0.0
var is_talking := false
var last_boss_texture: Texture2D
var last_line := ""
# Each monster has its own persistent dialogue shuffle bag.
var dialogue_bags: Dictionary = {}
var last_lines_by_monster: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 4
	position = Vector2.ZERO
	size = Vector2(VIEW_WIDTH, 720)

	boss = get_parent().get_node_or_null("Boss") as TextureRect
	battle = get_parent().get_node_or_null("BattleController")

	if boss == null or battle == null:
		push_warning("MonsterDialogue needs siblings named Boss and BattleController.")
		set_process(false)
		return

	_create_bubble()
	last_boss_texture = boss.texture
	seconds_until_chatter = rng.randf_range(4.0, 8.0)


func _create_bubble() -> void:
	bubble = Control.new()
	bubble.size = Vector2(BUBBLE_WIDTH, BUBBLE_HEIGHT)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.modulate.a = 0.0
	add_child(bubble)

	var panel := Panel.new()
	panel.size = bubble.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFF9F0")
	style.set_border_width_all(0)
	style.shadow_size = 0
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	bubble.add_child(panel)

	dialogue_label = Label.new()
	dialogue_label.position = Vector2(15, 10)
	dialogue_label.size = Vector2(BUBBLE_WIDTH - 30.0, BUBBLE_HEIGHT - 20.0)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_override("font", FONT)
	dialogue_label.add_theme_font_size_override("font_size", 17)
	dialogue_label.add_theme_color_override("font_color", Color("#352843"))
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(dialogue_label)


func _process(delta: float) -> void:
	if boss == null or battle == null:
		return

	# A new monster means a completely fresh speech cycle.
	if boss.texture != last_boss_texture:
		last_boss_texture = boss.texture
		_hide_immediately()
		seconds_until_chatter = rng.randf_range(5.0, 10.0)

	var busy: bool = bool(battle.get("finishing_round"))
	if busy or not boss.visible or boss.modulate.a < 0.99:
		_hide_immediately()
		return

	if is_talking:
		_position_bubble()
		visible_remaining -= delta
		if visible_remaining <= 0.0:
			_fade_away()
		return

	seconds_until_chatter -= delta
	if seconds_until_chatter <= 0.0:
		_say_random_line()


func _draw_dialogue_line(texture: Texture2D) -> String:
	if texture == null:
		return ""

	# Use the complete texture path so regular monsters and
	# boss versions have independent dialogue histories.
	var monster_id: String = texture.resource_path

	var choices: Array[String] = MonsterDialogueLines.for_texture(texture)

	if choices.is_empty():
		return ""

	# Create or refill this monster's personal shuffle bag.
	if not dialogue_bags.has(monster_id) or dialogue_bags[monster_id].is_empty():
		var new_bag: Array[String] = choices.duplicate()
		new_bag.shuffle()

		# Prevent the final line of the previous cycle from
		# immediately repeating as the first of the next.
		var previous_line: String = str(
			last_lines_by_monster.get(monster_id, "")
		)

		if new_bag.size() > 1 and new_bag.back() == previous_line:
			var swap_index: int = rng.randi_range(
				0,
				new_bag.size() - 2
			)

			var temporary: String = new_bag[swap_index]
			new_bag[swap_index] = new_bag[new_bag.size() - 1]
			new_bag[new_bag.size() - 1] = temporary

		dialogue_bags[monster_id] = new_bag

	# Take one unused line from this monster's bag.
	var bag: Array = dialogue_bags[monster_id]
	var selected_line: String = str(bag.pop_back())

	dialogue_bags[monster_id] = bag
	last_lines_by_monster[monster_id] = selected_line

	return selected_line

func _say_random_line() -> void:
	var phrase: String = _draw_dialogue_line(boss.texture)

	if phrase.is_empty():
		seconds_until_chatter = rng.randf_range(6.0, 13.0)
		return

	last_line = phrase
	dialogue_label.text = phrase
	_resize_bubble_to_text()

	is_talking = true
	visible_remaining = 3.2
	_position_bubble()

	if active_tween != null and active_tween.is_running():
		active_tween.kill()

	bubble.modulate.a = 0.0

	active_tween = create_tween()
	active_tween.tween_property(
		bubble,
		"modulate:a",
		1.0,
		0.25
	)

func _resize_bubble_to_text() -> void:
	# Measure the dialogue using the actual Silkscreen font.
	var text_width: float = FONT.get_string_size(
		dialogue_label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		17
	).x

	# Keep the bubble comfortably padded.
	var desired_width: float = clampf(
		text_width + 44.0,
		180.0,
		MAX_BUBBLE_WIDTH
	)

	bubble.size.x = desired_width

	# Resize the existing background panel.
	var panel := bubble.get_child(0) as Panel
	panel.size = bubble.size

	# Keep the text centred within the resized bubble.
	dialogue_label.position = Vector2(15.0, 10.0)
	dialogue_label.size = Vector2(
		desired_width - 30.0,
		BUBBLE_HEIGHT - 20.0
	)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_OFF


func _position_bubble() -> void:
	# Position above the boss without inheriting its squish animation.
	var center_x := boss.position.x + boss.size.x * 0.5
	var bubble_x := clampf(
	center_x - bubble.size.x * 0.5,
	14.0,
	LEFT_AREA_RIGHT - bubble.size.x - 14.0
)
	var bubble_y := maxf(162.0, boss.position.y - BUBBLE_HEIGHT - 22.0)
	bubble.position = Vector2(bubble_x, bubble_y)


func _fade_away() -> void:
	is_talking = false
	seconds_until_chatter = rng.randf_range(6.0, 13.0)
	if active_tween != null and active_tween.is_running():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.tween_property(bubble, "modulate:a", 0.0, 0.35)


func _hide_immediately() -> void:
	if active_tween != null and active_tween.is_running():
		active_tween.kill()
	if bubble != null:
		bubble.modulate.a = 0.0
	if is_talking:
		seconds_until_chatter = rng.randf_range(6.0, 13.0)
	is_talking = false
