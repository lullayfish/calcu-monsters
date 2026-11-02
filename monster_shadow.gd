
extends Control

const SHADOW_COLOR := Color(0.20, 0.27, 0.23, 0.28)

var cached_texture: Texture2D
var visible_bounds := Rect2i()
var texture_dimensions := Vector2.ONE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	z_index = 0
	set_process(true)


func _process(_delta: float) -> void:
	var monster := get_parent() as TextureRect
	if monster == null:
		return

	# Update the visible sprite bounds when monsters change.
	if monster.texture != cached_texture:
		cached_texture = monster.texture

		if cached_texture != null:
			var image := cached_texture.get_image()
			visible_bounds = image.get_used_rect()
			texture_dimensions = Vector2(image.get_size())

	position = Vector2.ZERO
	size = monster.size

	# Keep the shadow updated during monster animations.
	queue_redraw()


func _draw() -> void:
	var monster := get_parent() as TextureRect
	if monster == null or cached_texture == null:
		return

	if visible_bounds.size == Vector2i.ZERO:
		return

	# Convert visible pixel bounds to displayed sprite coordinates.
	var ratio := Vector2(
		size.x / texture_dimensions.x,
		size.y / texture_dimensions.y
	)

	var visible_left := float(visible_bounds.position.x) * ratio.x
	var visible_width := float(visible_bounds.size.x) * ratio.x
	var visible_bottom := float(
		visible_bounds.position.y + visible_bounds.size.y
	) * ratio.y

	# Centre the shadow beneath the actual visible sprite.
	var centre := Vector2(
		visible_left + visible_width * 0.5,
		visible_bottom - 3.0
	)

	var radii := Vector2(
		clampf(visible_width * 0.30, 18.0, 95.0),
		clampf(visible_width * 0.055, 7.0, 18.0)
	)

	var points := PackedVector2Array()

	for i in range(33):
		var angle := TAU * float(i) / 32.0
		points.append(
			centre + Vector2(
				cos(angle) * radii.x,
				sin(angle) * radii.y
			)
		)

	draw_colored_polygon(points, SHADOW_COLOR)
