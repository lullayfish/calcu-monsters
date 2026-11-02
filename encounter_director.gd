extends Node

# CALCU-MONSTERS — ENCOUNTER DIRECTOR
# Exactly four regular monsters followed by one boss.
# All original textures explicitly preloaded for web exports.

const NORMAL_MONSTERS: Array[Texture2D] = [
	preload("res://assets/monster/baby_dragon.png"),
	preload("res://assets/monster/bamboo.png"),
	preload("res://assets/monster/bamouth.png"),
	preload("res://assets/monster/beetle_leaf.png"),
	preload("res://assets/monster/bird.png"),
	preload("res://assets/monster/candlesnake.png"),
	preload("res://assets/monster/centipede.png"),
	preload("res://assets/monster/crystal.png"),
	preload("res://assets/monster/egg.png"),
	preload("res://assets/monster/electric_bat.png"),
	preload("res://assets/monster/electric_rat.png"),
	preload("res://assets/monster/fish.png"),
	preload("res://assets/monster/flamevil.png"),
	preload("res://assets/monster/frog.png"),
	preload("res://assets/monster/goblin_king.png"),
	preload("res://assets/monster/goblinball.png"),
	preload("res://assets/monster/goblinbat.png"),
	preload("res://assets/monster/golem.png"),
	preload("res://assets/monster/hornheart.png"),
	preload("res://assets/monster/lamp.png"),
	preload("res://assets/monster/lantern.png"),
	preload("res://assets/monster/mimic.png"),
	preload("res://assets/monster/mimic_barrel.png"),
	preload("res://assets/monster/mimic_campfire.png"),
	preload("res://assets/monster/miniflam.png"),
	preload("res://assets/monster/mole.png"),
	preload("res://assets/monster/molicorn.png"),
	preload("res://assets/monster/monkey.png"),
	preload("res://assets/monster/mount_goblin.png"),
	preload("res://assets/monster/mushroom.png"),
	preload("res://assets/monster/mutant.png"),
	preload("res://assets/monster/racoon.png"),
	preload("res://assets/monster/radish_plant.png"),
	preload("res://assets/monster/rock.png"),
	preload("res://assets/monster/rock_crab.png"),
	preload("res://assets/monster/shell.png"),
	preload("res://assets/monster/skeleton.png"),
	preload("res://assets/monster/slime.png"),
	preload("res://assets/monster/slime_bat.png"),
	preload("res://assets/monster/snake.png"),
	preload("res://assets/monster/snowman.png"),
	preload("res://assets/monster/spidercloud.png"),
	preload("res://assets/monster/spiritflam.png"),
	preload("res://assets/monster/thunder_cloud.png"),
	preload("res://assets/monster/walking_bomb.png"),
	preload("res://assets/monster/walking_moon.png"),
	preload("res://assets/monster/worm.png")
]

const BOSS_MONSTERS: Array[Texture2D] = [
	preload("res://assets/boss/bamboo.png"),
	preload("res://assets/boss/bamouth.png"),
	preload("res://assets/boss/beetle_leaf.png"),
	preload("res://assets/boss/butterfleye.png"),
	preload("res://assets/boss/candlesnake.png"),
	preload("res://assets/boss/centipede.png"),
	preload("res://assets/boss/crystal.png"),
	preload("res://assets/boss/dragon.png"),
	preload("res://assets/boss/electric_bat.png"),
	preload("res://assets/boss/electric_rat.png"),
	preload("res://assets/boss/flamevil.png"),
	preload("res://assets/boss/frog.png"),
	preload("res://assets/boss/goblinbat.png"),
	preload("res://assets/boss/goblinboss.png"),
	preload("res://assets/boss/goblinmage.png"),
	preload("res://assets/boss/golem.png"),
	preload("res://assets/boss/hatchegg.png"),
	preload("res://assets/boss/hornheart.png"),
	preload("res://assets/boss/lamp.png"),
	preload("res://assets/boss/mimic_fountain.png"),
	preload("res://assets/boss/molicorn.png"),
	preload("res://assets/boss/mushroom.png"),
	preload("res://assets/boss/mustarock.png"),
	preload("res://assets/boss/mutant.png"),
	preload("res://assets/boss/racoon.png"),
	preload("res://assets/boss/radish_plant.png"),
	preload("res://assets/boss/shell.png"),
	preload("res://assets/boss/skeleton.png"),
	preload("res://assets/boss/slime.png"),
	preload("res://assets/boss/slime_bat.png"),
	preload("res://assets/boss/snowman.png"),
	preload("res://assets/boss/spidercloud.png"),
	preload("res://assets/boss/spiritflam.png"),
	preload("res://assets/boss/thunder_cloud.png"),
	preload("res://assets/boss/triple_goblin_king.png"),
	preload("res://assets/boss/volcanocrab.png"),
	preload("res://assets/boss/walking_bomb.png"),
	preload("res://assets/boss/walking_moon.png"),
	preload("res://assets/boss/water_snake.png")
]

var rng := RandomNumberGenerator.new()
var normal_bag: Array[Texture2D] = []
var boss_bag: Array[Texture2D] = []

var last_normal_monster: Texture2D
var last_boss_monster: Texture2D

func _ready() -> void:
	rng.randomize()

func is_boss_round(round_number: int) -> bool:
	return round_number > 0 and round_number % 5 == 0


func _draw_from_bag(boss_round: bool) -> Texture2D:
	var bag: Array[Texture2D]
	var pool: Array[Texture2D]
	var previous: Texture2D

	if boss_round:
		bag = boss_bag
		pool = BOSS_MONSTERS
		previous = last_boss_monster
	else:
		bag = normal_bag
		pool = NORMAL_MONSTERS
		previous = last_normal_monster

	# Refill and shuffle only when every monster has appeared.
	if bag.is_empty():
		bag.assign(pool)
		bag.shuffle()

		# Avoid repeating the previous monster at a bag boundary.
		if bag.size() > 1 and bag.back() == previous:
			var swap_index: int = rng.randi_range(
				0,
				bag.size() - 2
			)

			var temporary: Texture2D = bag[swap_index]
			bag[swap_index] = bag[bag.size() - 1]
			bag[bag.size() - 1] = temporary

	var selected: Texture2D = bag.pop_back()

	if boss_round:
		boss_bag = bag
		last_boss_monster = selected
	else:
		normal_bag = bag
		last_normal_monster = selected

	return selected


func spawn_for_round(round_number: int) -> void:
	var boss_sprite := get_parent().get_node_or_null("Boss") as TextureRect
	if boss_sprite == null:
		push_error("EncounterDirector needs a sibling TextureRect named Boss.")
		return
	var choice: Texture2D = _draw_from_bag(
		is_boss_round(round_number)
	)
	boss_sprite.texture = choice
	var display_name: String = choice.resource_path.get_file().get_basename().replace("_", " ").capitalize()
	boss_sprite.set("current_boss_name", display_name)
	if boss_sprite.has_method("_position_current_boss"):
		boss_sprite.call("_position_current_boss")

	# Regular monsters sit lower to match the boss battlefield position.
	if not is_boss_round(round_number):
		boss_sprite.position.y += 45.0
	# The existing squish animation pivots at the monster's feet.
	boss_sprite.pivot_offset = Vector2(boss_sprite.size.x * 0.5, boss_sprite.size.y)


func generate_for_round(round_number: int) -> Dictionary:
	var boss_round: bool = is_boss_round(round_number)
	var stage: int = maxi(0, floori(float(round_number - 1) / 5.0))
	var boss_number: int = floori(float(round_number) / 5.0)

	var count: int = 1

	if boss_round:
		if boss_number <= 2:
			count = 2
		elif boss_number <= 4:
			count = 3
		else:
			count = 4
	else:
		if stage < 2:
			count = 1
		elif stage < 4:
			count = 2 if rng.randf() < 0.25 else 1
		elif stage < 8:
			count = 2
		else:
			count = 3 if rng.randf() < 0.25 else 2

	var combinations: Array[String] = [
		"+", "−", "×", "÷",
		"+−", "+×", "+÷",
		"−×", "−÷", "×÷",
		"+−×", "+−÷", "+×÷", "−×÷",
		"+−×÷"
	]

	var available: Array[String] = []

	for combo in combinations:
		if combo.length() == count:
			available.append(combo)

	var ops: String = available[
		rng.randi_range(0, available.size() - 1)
	]

	var solution: Dictionary = _build_solution(
		ops,
		round_number,
		boss_round
	)

	var required_digit := ""
	var forbidden_digit := ""

	var digit_challenge := false

	if boss_round and boss_number >= 3:
		digit_challenge = rng.randf() < 0.40
	elif not boss_round and stage >= 5:
		digit_challenge = rng.randf() < 0.12

	if digit_challenge:
		var expression: String = solution["expression"]
		var digits: Array[String] = []
		var other_digits: Array[String] = []

		for digit in "0123456789":
			if expression.contains(digit):
				digits.append(digit)
			else:
				other_digits.append(digit)

		if rng.randf() < 0.5 or other_digits.is_empty():
			required_digit = digits[
				rng.randi_range(0, digits.size() - 1)
			]
		else:
			forbidden_digit = other_digits[
				rng.randi_range(0, other_digits.size() - 1)
			]

	var instruction := "USE ONLY " + " ".join(ops.split(""))

	if required_digit != "":
		instruction += "; INCLUDE " + required_digit

	if forbidden_digit != "":
		instruction += "; AVOID " + forbidden_digit

	return {
		"target": solution["target"],
		"operators": ops,
		"required_digit": required_digit,
		"forbidden_digit": forbidden_digit,
		"instruction": instruction,
		"boss_round": boss_round
	}

func _build_solution(
	operators: String,
	round_number: int,
	boss_round: bool
) -> Dictionary:

	var stage: int = maxi(
		0,
		floori(float(round_number - 1) / 5.0)
	)

	var growth: int = mini(stage, 20)

	var base: int
	var factor: int
	var divisor: int
	var addend: int
	var subtrahend: int

	if boss_round:
		base = rng.randi_range(
			8 + growth * 2,
			15 + growth * 3
		)
	else:
		base = rng.randi_range(
			4 + growth,
			9 + growth * 2
		)

	var expression := ""
	var value: int = base

	# Multiplication and division, with exact whole-number division.
	if operators.contains("×") and operators.contains("÷"):
		if boss_round:
			factor = rng.randi_range(3, 7 + floori(float(growth) / 2.0))
			divisor = rng.randi_range(2, 7)
		else:
			factor = rng.randi_range(2, 5 + floori(float(growth) / 3.0))
			divisor = rng.randi_range(2, 5)

		expression = "%d×%d÷%d" % [
			base * divisor,
			factor,
			divisor
		]

		value = base * factor

	elif operators.contains("×"):
		if boss_round:
			factor = rng.randi_range(3, 7 + floori(float(growth) / 2.0))
		else:
			factor = rng.randi_range(2, 5 + floori(float(growth) / 3.0))

		expression = "%d×%d" % [base, factor]
		value = base * factor

	elif operators.contains("÷"):
		if boss_round:
			divisor = rng.randi_range(2, 8)
		else:
			divisor = rng.randi_range(2, 5)

		expression = "%d÷%d" % [
			base * divisor,
			divisor
		]

		value = base

	else:
		expression = str(base)

	# Addition.
	if operators.contains("+"):
		if boss_round:
			addend = rng.randi_range(
				5 + growth,
				12 + growth * 2
			)
		else:
			addend = rng.randi_range(
				2,
				7 + growth
			)

		expression += "+%d" % addend
		value += addend

	# Subtraction, keeping targets positive.
	if operators.contains("−"):
		var maximum_subtraction: int = maxi(
			1,
			value - 1
		)

		if boss_round:
			maximum_subtraction = mini(
				maximum_subtraction,
				12 + growth * 2
			)
		else:
			maximum_subtraction = mini(
				maximum_subtraction,
				7 + growth
			)

		subtrahend = rng.randi_range(
			1,
			maximum_subtraction
		)

		expression += "−%d" % subtrahend
		value -= subtrahend

	return {
		"expression": expression,
		"target": value
	}

func validate(raw_expression: String, result: float, challenge: Dictionary) -> bool:
	if absf(result - float(challenge["target"])) > 0.000001:
		return false
	var allowed: String = challenge["operators"]
	for op in ["+", "−", "×", "÷"]:
		var used: bool = raw_expression.contains(op)
		if used != allowed.contains(op):
			return false
	var required: String = challenge["required_digit"]
	var forbidden: String = challenge["forbidden_digit"]
	if required != "" and not raw_expression.contains(required):
		return false
	if forbidden != "" and raw_expression.contains(forbidden):
		return false
	return true
