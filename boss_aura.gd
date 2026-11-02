extends Control

# Calcu-Monsters: anime-style flame aura sized to each boss's VISIBLE sprite.
# Attach to Boss/BossAura. BattleController continues to call set_active().

@export var width_multiplier: float = 1.24
@export var height_multiplier: float = 1.42
@export var feet_offset: Vector2 = Vector2.ZERO
@export var flame_speed: float = 4.4
@export var outer_color: Color = Color(1.0, 0.42, 0.12, 0.32)
@export var middle_color: Color = Color(1.0, 0.68, 0.24, 0.40)
@export var inner_color: Color = Color(1.0, 0.92, 0.55, 0.47)

var active: bool = false
var elapsed: float = 0.0
# Tiny, script-drawn embers. No CPUParticles2D or extra nodes required.
@export var ember_count: int = 28
@export var ember_color: Color = Color(1.0, 0.88, 0.53, 0.8)
var _embers: Array[Dictionary] = []
var _ember_rng := RandomNumberGenerator.new()
var _cached_texture: Texture2D
var _source_visible_rect: Rect2 = Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	visible = false
	set_process(false)
	position = Vector2.ZERO
	_sync_to_boss()
	_ember_rng.randomize()

func set_active(value: bool) -> void:
	active = value
	visible = value
	set_process(value)
	if not value:
		elapsed = 0.0
		_embers.clear()
	elif _embers.is_empty():
		for i in range(ember_count):
			_embers.append(_new_ember(true))
	_sync_to_boss()
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	_sync_to_boss()
	var feet := _aura_feet()
	var aura_height: float = maxf(130.0, _visible_bounds().size.y * height_multiplier)
	for i in range(_embers.size()):
		var ember: Dictionary = _embers[i]
		ember["position"] = Vector2(ember["position"]) + Vector2(float(ember["drift"]), -float(ember["speed"])) * delta
		ember["life"] = float(ember["life"]) - delta
		if float(ember["life"]) <= 0.0 or Vector2(ember["position"]).y < feet.y - aura_height * 1.15:
			ember = _new_ember(false)
		_embers[i] = ember
	queue_redraw()

func _sync_to_boss() -> void:
	var boss := get_parent() as Control
	if boss == null:
		return
	size = boss.size
	if boss is TextureRect:
		var sprite := boss as TextureRect
		if sprite.texture != _cached_texture:
			_cached_texture = sprite.texture
			_source_visible_rect = Rect2()
			if _cached_texture != null:
				var image := _cached_texture.get_image()
				if image != null and not image.is_empty():
					_source_visible_rect = Rect2(image.get_used_rect())

func _visible_bounds() -> Rect2:
	var boss := get_parent() as Control
	if boss == null:
		return Rect2(Vector2.ZERO, size)
	if not boss is TextureRect:
		return Rect2(Vector2.ZERO, size)
	var sprite := boss as TextureRect
	if sprite.texture == null or _source_visible_rect.size == Vector2.ZERO:
		return Rect2(Vector2.ZERO, size)

	var image_size := Vector2(sprite.texture.get_size())
	if image_size.x <= 0.0 or image_size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)

	var drawn_size := size
	var drawn_origin := Vector2.ZERO
	match sprite.stretch_mode:
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
			var factor: float = minf(size.x / image_size.x, size.y / image_size.y)
			drawn_size = image_size * factor
			drawn_origin = (size - drawn_size) * 0.5
		TextureRect.STRETCH_KEEP_ASPECT:
			var factor: float = minf(size.x / image_size.x, size.y / image_size.y)
			drawn_size = image_size * factor
		TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			var factor: float = maxf(size.x / image_size.x, size.y / image_size.y)
			drawn_size = image_size * factor
			drawn_origin = (size - drawn_size) * 0.5
		TextureRect.STRETCH_KEEP_CENTERED:
			drawn_size = image_size
			drawn_origin = (size - drawn_size) * 0.5
		TextureRect.STRETCH_KEEP:
			drawn_size = image_size
		_:
			pass

	var ratio := drawn_size / image_size
	return Rect2(drawn_origin + _source_visible_rect.position * ratio, _source_visible_rect.size * ratio)

func _draw() -> void:
	if not active:
		return

	var visible_rect := _visible_bounds()
	var feet := Vector2(visible_rect.get_center().x, visible_rect.end.y) + feet_offset
	var width: float = maxf(110.0, visible_rect.size.x * width_multiplier)
	var height: float = maxf(130.0, visible_rect.size.y * height_multiplier)

	# Animated, overlapping tapered flame tongues, all rooted at the boss's feet.
	_draw_flame_row(feet, width, height, 21, outer_color, 1.0, 0.0)
	_draw_flame_row(feet, width * 0.85, height * 0.87, 18, middle_color, 1.3, 1.4)
	_draw_flame_row(feet, width * 0.66, height * 0.71, 15, inner_color, 1.7, 2.7)
	_draw_embers()

func _aura_feet() -> Vector2:
	var bounds := _visible_bounds()
	return Vector2(bounds.get_center().x, bounds.end.y) + feet_offset

func _new_ember(random_height: bool) -> Dictionary:
	var bounds := _visible_bounds()
	var feet := _aura_feet()
	var width: float = maxf(110.0, bounds.size.x * width_multiplier)
	var height: float = maxf(130.0, bounds.size.y * height_multiplier)
	var y_offset: float = _ember_rng.randf_range(0.0, height) if random_height else 0.0
	return {
		"position": feet + Vector2(_ember_rng.randf_range(-width * 0.43, width * 0.43), -y_offset),
		"speed": _ember_rng.randf_range(48.0, 100.0) * (height / 220.0),
		"drift": _ember_rng.randf_range(-18.0, 18.0),
		"size": _ember_rng.randf_range(1.3, 3.3),
		"life": _ember_rng.randf_range(0.6, 1.5),
	}

func _draw_embers() -> void:
	for ember in _embers:
		var tint := ember_color
		tint.a *= clampf(float(ember["life"]) / 0.45, 0.0, 1.0)
		draw_circle(Vector2(ember["position"]), float(ember["size"]), tint)

func _draw_flame_row(feet: Vector2, width: float, height: float, count: int, tint: Color, speed: float, phase: float) -> void:
	for i in range(count):
		var fraction: float = float(i) / float(count - 1)
		var edge: float = absf(fraction * 2.0 - 1.0)
		var wave: float = sin(elapsed * flame_speed * speed + float(i) * 1.83 + phase)
		var base := feet + Vector2((fraction - 0.5) * width, 0.0)
		var tongue_height: float = height * (0.66 + 0.34 * (1.0 - edge)) * (0.83 + 0.17 * wave)
		var tip := base + Vector2(wave * width * 0.025, -tongue_height)
		var half_width: float = width / float(count) * 1.05
		_draw_tongue(base, tip, half_width, tint, float(i) * 0.7)

func _draw_tongue(root: Vector2, tip: Vector2, half_width: float, tint: Color, phase: float) -> void:
	# Curved, twisting flame tongues: the lower half swells, the upper half
	# tapers and curls. The root remains fixed at the boss's feet.
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var flame_height: float = root.y - tip.y
	for step in range(13):
		var t: float = float(step) / 12.0
		var width_profile: float = pow(1.0 - t, 0.75) * (0.76 + 0.52 * sin(t * PI))
		var local_half: float = half_width * width_profile
		var sway: float = sin(elapsed * flame_speed * 0.95 + phase + t * 4.4) * half_width * 1.25 * sin(t * PI * 0.82)
		var curl: float = sin(elapsed * flame_speed * 1.4 + phase * 1.8) * half_width * pow(t, 2.0) * 1.3
		var ripple: float = sin(elapsed * flame_speed * 1.7 + phase + t * 9.0) * half_width * 0.2 * sin(t * PI)
		var centre := Vector2(lerpf(root.x, tip.x, t) + sway + curl, root.y - flame_height * t)
		left.append(centre + Vector2(-local_half - ripple, 0.0))
		right.append(centre + Vector2(local_half + ripple, 0.0))
	var points := PackedVector2Array()
	points.append_array(left)
	for i in range(right.size() - 1, -1, -1):
		points.append(right[i])
	draw_colored_polygon(points, tint)
