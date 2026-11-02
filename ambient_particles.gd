
extends Control

# CALCU-MONSTERS — AMBIENT PARTICLES
# Gentle floating pixel dust and magical sparkles.
# No external textures required.

const PARTICLE_COUNT := 32
const AREA_WIDTH := 860.0
const AREA_HEIGHT := 570.0

const COLORS := [
	Color("#FFE4AE"),
	Color("#EAC9FF"),
	Color("#C8ECFF"),
	Color("#FFF8E9")
]

var rng := RandomNumberGenerator.new()
var particles: Array[Dictionary] = []


func _ready() -> void:
	rng.randomize()

	position = Vector2.ZERO
	size = Vector2(AREA_WIDTH, AREA_HEIGHT)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 0

	for i in range(PARTICLE_COUNT):
		particles.append(_make_particle(true))

	set_process(true)


func _process(delta: float) -> void:
	for i in range(particles.size()):
		var p: Dictionary = particles[i]

		p["y"] -= p["speed"] * delta
		p["x"] += sin(
			p["y"] * 0.015 + p["phase"]
		) * p["sway"] * delta

		p["life"] += delta

		if p["y"] < -15.0 or p["life"] > p["max_life"]:
			p = _make_particle(false)

		particles[i] = p

	queue_redraw()

func _make_particle(initial: bool) -> Dictionary:
	return {
		"x": rng.randf_range(10.0, AREA_WIDTH - 10.0),
		"y": rng.randf_range(100.0, AREA_HEIGHT) if initial else AREA_HEIGHT,
		"speed": rng.randf_range(10.0, 26.0),
		"size": rng.randi_range(2, 4),
		"phase": rng.randf_range(0.0, TAU),
		"sway": rng.randf_range(2.0, 9.0),
		"life": 0.0,
		"max_life": rng.randf_range(14.0, 30.0),
		"color": COLORS[rng.randi_range(0, COLORS.size() - 1)]
	}

func _draw() -> void:
	for p in particles:
		var fade_in: float = clampf(p["life"] / 1.5, 0.0, 1.0)
		var fade_out: float = clampf(
			(p["max_life"] - p["life"]) / 2.5,
			0.0,
			1.0
		)

		var alpha: float = minf(fade_in, fade_out) * 0.75
		var color: Color = p["color"]
		color.a = alpha

		var pixel_size: float = p["size"]
		var pos := Vector2(roundf(p["x"]), roundf(p["y"]))

		draw_rect(
			Rect2(pos, Vector2(pixel_size, pixel_size)),
			color
		)

		# Occasional four-point star sparkles.
		if pixel_size >= 4.0:
			var sparkle := color
			sparkle.a *= 0.45

			draw_rect(
				Rect2(pos + Vector2(-3, 1), Vector2(10, 2)),
				sparkle
			)
			draw_rect(
				Rect2(pos + Vector2(1, -3), Vector2(2, 10)),
				sparkle
			)
