extends TextureRect

# CALCU-MONSTERS — RANDOM BOSS
# Explicitly preloads all base boss monsters (no colour variants).

const BOSSES: Array[Texture2D] = [
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

# Bottom-center anchor for the boss.
# This is the point where the boss "touches" the ground.
const BOSS_FEET_X := 450.0
const BOSS_FEET_Y := 640.0

# Max display size so large bosses still fit nicely.
const MAX_BOSS_WIDTH := 300.0
const MAX_BOSS_HEIGHT := 240.0

var rng := RandomNumberGenerator.new()
var current_boss_name := "Monster"

func _ready() -> void:
	rng.randomize()

	z_index = 2
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	randomize_boss()
	start_idle_animation()

func randomize_boss() -> void:
	if BOSSES.is_empty():
		return

	var index := rng.randi_range(0, BOSSES.size() - 1)
	texture = BOSSES[index]
	current_boss_name = _format_boss_name(texture.resource_path)
	_position_current_boss()

func _position_current_boss() -> void:
	if texture == null:
		return

	var tex_size := texture.get_size()
	var scale_factor := minf(MAX_BOSS_WIDTH / tex_size.x, MAX_BOSS_HEIGHT / tex_size.y)

	size = tex_size * scale_factor
	position = Vector2(
		BOSS_FEET_X - size.x * 0.5,
		BOSS_FEET_Y - size.y
	)

func start_idle_animation() -> void:
	# Anchor transformations at the monster's feet.
	# This prevents squishing from making the monster float.
	pivot_offset = Vector2(size.x / 2.0, size.y)

	var idle_tween := create_tween()
	idle_tween.set_loops()

	# Squish down — wider and shorter.
	idle_tween.tween_property(
		self, "scale", Vector2(1.07, 0.93), 0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Stretch upward — narrower and taller.
	idle_tween.tween_property(
		self, "scale", Vector2(0.95, 1.06), 0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Return to normal.
	idle_tween.tween_property(
		self, "scale", Vector2.ONE, 0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _format_boss_name(path: String) -> String:
	if path == "":
		return "Monster"

	var raw_name := path.get_file().get_basename()
	var words := raw_name.split("_")

	for i in range(words.size()):
		words[i] = words[i].capitalize()

	return " ".join(words)
