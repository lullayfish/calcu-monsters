
extends TextureRect

# CALCU-MONSTERS — RANDOM FLOOR
# Explicitly preloads every floor for reliable HTML5 exports.
# Excludes the multi_direction folder.

const FLOORS: Array[Texture2D] = [
	preload("res://assets/floor/checker_carpet_blue.png"),
	preload("res://assets/floor/checker_carpet_red.png"),
	preload("res://assets/floor/checker_dirt.png"),
	preload("res://assets/floor/checker_dirt_dark.png"),
	preload("res://assets/floor/checker_slabs_dirt.png"),
	preload("res://assets/floor/checker_slabs_rock.png"),
	preload("res://assets/floor/dirt_sand.png"),
	preload("res://assets/floor/dirt_slabs.png"),
	preload("res://assets/floor/dungeon.png"),
	preload("res://assets/floor/grass.png"),
	preload("res://assets/floor/grass_dark.png"),
	preload("res://assets/floor/grass_dark_dirt.png"),
	preload("res://assets/floor/grass_dark_pond.png"),
	preload("res://assets/floor/grass_dark_sand.png"),
	preload("res://assets/floor/grass_dark_slabs_rock.png"),
	preload("res://assets/floor/grass_dirt.png"),
	preload("res://assets/floor/grass_orange.png"),
	preload("res://assets/floor/grass_orange_pond.png"),
	preload("res://assets/floor/grass_orange_rock.png"),
	preload("res://assets/floor/grass_orange_sand.png"),
	preload("res://assets/floor/grass_orange_slabs_rock.png"),
	preload("res://assets/floor/grass_pink.png"),
	preload("res://assets/floor/grass_pink_pond.png"),
	preload("res://assets/floor/grass_pink_rock.png"),
	preload("res://assets/floor/grass_pink_sand.png"),
	preload("res://assets/floor/grass_pink_sand_white.png"),
	preload("res://assets/floor/grass_pink_slabs_dirt.png"),
	preload("res://assets/floor/grass_pond.png"),
	preload("res://assets/floor/grass_rock.png"),
	preload("res://assets/floor/grass_sand.png"),
	preload("res://assets/floor/grass_sand_green.png"),
	preload("res://assets/floor/grass_sand_white.png"),
	preload("res://assets/floor/grass_slabs_dirt.png"),
	preload("res://assets/floor/grass_slabs_rock.png"),
	preload("res://assets/floor/grass_snow.png"),
	preload("res://assets/floor/grass_snow_pond.png"),
	preload("res://assets/floor/grass_snow_sand.png"),
	preload("res://assets/floor/grass_snow_slabs_dirt.png"),
	preload("res://assets/floor/pink_grass_pond.png")
]

# Fixed position on the left side of the 1280x720 game.
const FLOOR_POSITION := Vector2(0, 518)
const FLOOR_SIZE := Vector2(900, 202)

var rng := RandomNumberGenerator.new()
var floor_bag: Array[int] = []
var last_floor_index := -1

func _ready() -> void:
	rng.randomize()

	z_index = 1

	position = FLOOR_POSITION
	size = FLOOR_SIZE

	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	randomize_floor()

func randomize_floor() -> void:
	if FLOORS.is_empty():
		return

	# Refill and reshuffle only after every floor has appeared.
	if floor_bag.is_empty():
		for i in range(FLOORS.size()):
			floor_bag.append(i)

		floor_bag.shuffle()

		# Don't repeat the previous floor across bag boundaries.
		if FLOORS.size() > 1 and floor_bag.back() == last_floor_index:
			var swap_index := rng.randi_range(0, floor_bag.size() - 2)
			var temp := floor_bag[swap_index]
			floor_bag[swap_index] = floor_bag[floor_bag.size() - 1]
			floor_bag[floor_bag.size() - 1] = temp

	# Draw the next floor from the shuffled bag.
	var index: int = floor_bag.pop_back()
	last_floor_index = index
	texture = FLOORS[index]
