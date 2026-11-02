
extends Control

# CALCU-MONSTERS — NIGHT SKY
# Pixel-art crescent moon and drifting lavender clouds.
# No textures or external assets required.

const SKY_WIDTH := 860.0
const SKY_HEIGHT := 570.0
const PIXEL_SIZE := 6.0

const MOON_CENTER := Vector2(695, 250)
const MOON_RADIUS := 43.0

const MOON_COLOR := Color("#FFE6B4")
const MOON_HIGHLIGHT := Color("#FFF4D6")

const CLOUD_LIGHT := Color("#DCCCE5")
const CLOUD_MID := Color("#BAA7CC")
const CLOUD_SHADOW := Color("#87749E")

var elapsed := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(SKY_WIDTH, SKY_HEIGHT)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 0

	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	_draw_moon()

	# Each cloud moves gently back and forth.
	_draw_cloud(
		Vector2(
			65 + sin(elapsed * 0.22) * 24,
			265 + sin(elapsed * 0.35) * 5
		),
		1.0,
		0.72
	)

	_draw_cloud(
		Vector2(
			530 + sin(elapsed * 0.17 + 2.0) * 30,
			335 + sin(elapsed * 0.28) * 6
		),
		0.85,
		0.60
	)

	_draw_cloud(
		Vector2(
			300 + sin(elapsed * 0.14 + 4.0) * 18,
			205
		),
		0.65,
		0.42
	)


func _draw_moon() -> void:
	# Soft glow behind the moon.
	for i in range(4):
		var glow_color := MOON_COLOR
		glow_color.a = 0.025

		draw_circle(
			MOON_CENTER,
			MOON_RADIUS + 12.0 + float(i) * 7.0,
			glow_color
		)

	# Draw a crescent using square pixels.
	# The inner circle is cut out transparently,
	# allowing the existing gradient to show through.
	var radius := int(MOON_RADIUS / PIXEL_SIZE) + 2

	for py in range(-radius, radius + 1):
		for px in range(-radius, radius + 1):
			var local := Vector2(
				float(px) * PIXEL_SIZE,
				float(py) * PIXEL_SIZE
			)

			var outer_distance := local.length()
			var inner_distance := (
				local - Vector2(17, -12)
			).length()

			if outer_distance > MOON_RADIUS:
				continue

			if inner_distance < MOON_RADIUS - 3.0:
				continue

			var moon_pixel := MOON_COLOR

			if px < -2 and py < 2:
				moon_pixel = MOON_HIGHLIGHT

			draw_rect(
				Rect2(
					MOON_CENTER + local,
					Vector2.ONE * PIXEL_SIZE
				),
				moon_pixel
			)


func _draw_cloud(
	cloud_position: Vector2,
	cloud_scale: float,
	opacity: float
) -> void:
	var pixel := 7.0 * cloud_scale

	# Pixel-art cloud built from overlapping ellipses.
	for y in range(11):
		for x in range(29):
			var point := Vector2(float(x), float(y))

			var left := _inside_ellipse(
				point, Vector2(7, 6),
				Vector2(7, 3)
			)

			var middle := _inside_ellipse(
				point, Vector2(14, 4.5),
				Vector2(6, 4.5)
			)

			var right := _inside_ellipse(
				point, Vector2(21, 6),
				Vector2(7, 3)
			)

			if not (left or middle or right):
				continue

			var pixel_color := CLOUD_MID

			if y <= 4:
				pixel_color = CLOUD_LIGHT
			elif y >= 8:
				pixel_color = CLOUD_SHADOW

			pixel_color.a = opacity

			draw_rect(
				Rect2(
					cloud_position + point * pixel,
					Vector2.ONE * pixel
				),
				pixel_color
			)


func _inside_ellipse(
	point: Vector2,
	center: Vector2,
	radii: Vector2
) -> bool:
	var dx := (point.x - center.x) / radii.x
	var dy := (point.y - center.y) / radii.y

	return dx * dx + dy * dy <= 1.0
