extends CanvasLayer

# CALCU-MONSTERS BESTIARY
# Saves across runs in user:// (including the itch.io browser build).
# Uses the EncounterDirector's existing preloaded monster lists.

signal completion_dismissed

const FONT = preload("res://assets/Silkscreen-Regular.ttf")
const DIRECTOR = preload("res://encounter_director.gd")
const DESCRIPTIONS = preload("res://bestiary_descriptions.gd")
const CLICK_SOUND = preload("res://assets/universfield-computer-mouse-click-352734.ogg")
const SAVE_PATH := "user://calcu_monsters_bestiary.json"
const INK := Color("#F8EAF5")
const SKY := Color("#BFE8FF")
const GOLD := Color("#FFE7A8")

var discovered: Dictionary = {}
var completion_seen := false
var active_tab := 0
var timer_to_resume: Timer
var paused_timer := false
var game_root: Node
var prior_input_enabled := false
var prior_unhandled_enabled := false
var overlay: Control
var book_panel: Panel
var completion_panel: Panel
var heading: Label
var progress_label: Label
var tabs: Array[Button] = []
var grid: GridContainer
var detail_panel: Panel
var detail_portrait: TextureRect
var detail_heading: Label
var detail_description: Label
var restarting_from_victory := false


func _ready() -> void:
	layer = 40
	visible = false
	_load_progress()
	_build_ui()
	var click_player := AudioStreamPlayer.new()
	click_player.name = "BestiaryClickSound"
	click_player.stream = CLICK_SOUND
	click_player.volume_db = -2.0
	add_child(click_player)


func _play_click() -> void:
	$BestiaryClickSound.play()


func _all_monsters() -> Array:
	var result: Array = []
	for image in DIRECTOR.NORMAL_MONSTERS:
		result.append(image)
	for image in DIRECTOR.BOSS_MONSTERS:
		result.append(image)
	return result


func register_defeat(texture: Texture2D) -> bool:
	var key := texture.resource_path
	if key.is_empty() or discovered.has(key):
		return false
	discovered[key] = true
	_save_progress()
	return true


func is_complete() -> bool:
	for image in _all_monsters():
		if not discovered.has(image.resource_path):
			return false
	return true


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var saved = JSON.parse_string(file.get_as_text())
	if not saved is Dictionary:
		return
	var entries = saved.get("discovered", [])
	if entries is Array:
		for item in entries:
			if item is String:
				discovered[item] = true
	completion_seen = saved.get("completion_seen", false) == true


func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save Calcu-Monsters bestiary progress.")
		return
	file.store_string(JSON.stringify({
		"discovered": discovered.keys(),
		"completion_seen": completion_seen
	}))
	file.close()


func _make_label(parent: Node, value: String, location: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = location
	label.size = dimensions
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _style(fill: Color, edge: Color, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style


func _make_button(parent: Node, label: String, location: Vector2, dimensions: Vector2, font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = label
	button.position = location
	button.size = dimensions
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", SKY)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_stylebox_override("normal", _style(Color("#4A3A63"), Color("#B9A7D1")))
	button.add_theme_stylebox_override("hover", _style(Color("#66527F"), Color("#D9C7EB")))
	button.add_theme_stylebox_override("pressed", _style(Color("#66527F"), Color("#D9C7EB")))
	parent.add_child(button)
	return button


func _build_ui() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color("#151020", 0.83)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	book_panel = Panel.new()
	book_panel.position = Vector2(155, 48)
	book_panel.size = Vector2(970, 625)
	book_panel.add_theme_stylebox_override("panel", _style(Color("#342947"), Color("#C4B4D8"), 14))
	overlay.add_child(book_panel)

	heading = _make_label(book_panel, "BESTIARY", Vector2(40, 20), Vector2(890, 45), 31, GOLD)
	progress_label = _make_label(book_panel, "", Vector2(275, 69), Vector2(420, 24), 15, SKY)

	var close_button := _make_button(book_panel, "CLOSE", Vector2(800, 20), Vector2(138, 42), 16)
	close_button.pressed.connect(_close_book)

	var regular_tab := _make_button(book_panel, "REGULAR MONSTERS", Vector2(46, 111), Vector2(423, 48), 17)
	var boss_tab := _make_button(book_panel, "BOSS MONSTERS", Vector2(500, 111), Vector2(423, 48), 17)
	regular_tab.pressed.connect(func() -> void: _choose_tab(0))
	boss_tab.pressed.connect(func() -> void: _choose_tab(1))
	tabs = [regular_tab, boss_tab]

	var scroller := ScrollContainer.new()
	scroller.position = Vector2(37, 173)
	scroller.size = Vector2(895, 417)
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	book_panel.add_child(scroller)

	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroller.add_child(grid)

	# The entry page takes the tab space while the tabs are temporarily hidden.
	detail_panel = Panel.new()
	detail_panel.position = Vector2(37, 185)
	detail_panel.size = Vector2(895, 350)
	detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_panel.add_theme_stylebox_override("panel", _style(Color("#463957"), Color("#B9A7D1"), 8))
	book_panel.add_child(detail_panel)

	var back_button := _make_button(detail_panel, "BACK", Vector2(714, 19), Vector2(148, 43), 16)
	back_button.pressed.connect(_hide_entry)

	detail_portrait = TextureRect.new()
	detail_portrait.position = Vector2(36, 72)
	detail_portrait.size = Vector2(280, 270)
	detail_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_panel.add_child(detail_portrait)

	detail_heading = _make_label(detail_panel, "", Vector2(336, 92), Vector2(510, 75), 24, GOLD)
	detail_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_description = _make_label(detail_panel, "", Vector2(336, 132), Vector2(510, 125), 17, INK)
	detail_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.hide()

	# A compact, centred finale with a clear title -> reward -> action hierarchy.
	completion_panel = Panel.new()
	completion_panel.position = Vector2(278, 150)
	completion_panel.size = Vector2(724, 422)
	completion_panel.add_theme_stylebox_override("panel", _style(Color("#342947"), Color("#E8CB86"), 14))
	overlay.add_child(completion_panel)
	_make_label(completion_panel, "BESTIARY COMPLETE!", Vector2(32, 35), Vector2(660, 55), 29, GOLD)
	_make_label(completion_panel, "YOU DEFEATED EVERY MONSTER!", Vector2(32, 96), Vector2(660, 29), 15, INK)

	var separator := ColorRect.new()
	separator.position = Vector2(170, 140)
	separator.size = Vector2(384, 2)
	separator.color = Color("#8D789D")
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	completion_panel.add_child(separator)

	var total := _all_monsters().size()
	_make_label(completion_panel, "%d / %d" % [total, total], Vector2(32, 156), Vector2(660, 62), 37, GOLD)
	_make_label(completion_panel, "MONSTERS DISCOVERED", Vector2(32, 216), Vector2(660, 30), 17, SKY)
	_make_label(completion_panel, "YOUR COLLECTION IS COMPLETE!", Vector2(32, 262), Vector2(660, 25), 14, INK)

	var play_again_button := _make_button(completion_panel, "PLAY AGAIN", Vector2(160, 317), Vector2(404, 60), 20)
	play_again_button.pressed.connect(_play_again)
	completion_panel.hide()


func _choose_tab(tab: int) -> void:
	_play_click()
	detail_panel.hide()
	active_tab = tab
	_render_entries()


func _render_entries() -> void:
	var all: Array = _all_monsters()
	var count := 0
	for image in all:
		if discovered.has(image.resource_path):
			count += 1
	progress_label.text = "%d / %d DISCOVERED" % [count, all.size()]

	for i in range(tabs.size()):
		var button: Button = tabs[i]
		button.add_theme_color_override("font_color", GOLD if i == active_tab else SKY)
		button.add_theme_stylebox_override("normal", _style(Color("#6C548A") if i == active_tab else Color("#4A3A63"), Color("#E8CB86") if i == active_tab else Color("#B9A7D1")))

	for entry in grid.get_children():
		grid.remove_child(entry)
		entry.queue_free()

	var collection: Array = DIRECTOR.NORMAL_MONSTERS if active_tab == 0 else DIRECTOR.BOSS_MONSTERS
	for i in range(collection.size()):
		var texture: Texture2D = collection[i]
		var unlocked := discovered.has(texture.resource_path)
		var tile := Panel.new()
		tile.custom_minimum_size = Vector2(139, 143)
		var row := floori(float(i) / 6.0)
		var fill := Color("#534368") if (row + i % 6) % 2 == 0 else Color("#463957")
		tile.add_theme_stylebox_override("panel", _style(fill, Color("#AC9BC2") if unlocked else Color("#746487"), 6))
		grid.add_child(tile)

		if unlocked:
			var portrait := TextureRect.new()
			portrait.texture = texture
			portrait.position = Vector2(7, 7)
			portrait.size = Vector2(125, 102)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.add_child(portrait)
		else:
			_make_label(tile, "?", Vector2(10, 16), Vector2(119, 86), 39, Color("#8D7AA6"))

		var monster_name := texture.resource_path.get_file().get_basename().replace("_", " ").to_upper() if unlocked else "???"
		var text_size := 10 if monster_name.length() > 16 else 12
		_make_label(tile, monster_name, Vector2(4, 110), Vector2(131, 27), text_size, INK if unlocked else Color("#A999BF"))

		if unlocked:
			# Invisible hit area: the artwork, checkerboard and name stay unchanged.
			var entry_button := Button.new()
			entry_button.position = Vector2.ZERO
			entry_button.size = Vector2(139, 143)
			entry_button.flat = true
			entry_button.focus_mode = Control.FOCUS_NONE
			entry_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			entry_button.pressed.connect(_show_entry.bind(texture))
			tile.add_child(entry_button)


func _show_entry(texture: Texture2D) -> void:
	_play_click()
	grid.get_parent().hide()
	var key: String = texture.resource_path.get_file().get_basename()
	var descriptions: Dictionary = DESCRIPTIONS.REGULAR if active_tab == 0 else DESCRIPTIONS.BOSS
	detail_portrait.texture = texture
	detail_heading.text = key.replace("_", " ").to_upper()
	detail_description.text = str(descriptions.get(key, "A mysterious creature with an untold story."))
	for tab_button in tabs:
		tab_button.hide()
	detail_panel.show()


func _hide_entry() -> void:
	_play_click()
	grid.get_parent().show()
	detail_panel.hide()
	for tab_button in tabs:
		tab_button.show()


func _disable_gameplay_input() -> void:
	if game_root == null:
		return
	prior_input_enabled = game_root.is_processing_input()
	prior_unhandled_enabled = game_root.is_processing_unhandled_key_input()
	game_root.set_process_input(false)
	game_root.set_process_unhandled_key_input(false)


func _restore_gameplay_input() -> void:
	if game_root == null:
		return
	game_root.set_process_input(prior_input_enabled)
	game_root.set_process_unhandled_key_input(prior_unhandled_enabled)


func open_book(timer: Timer, gameplay: Node) -> void:
	if visible:
		return
	_play_click()
	detail_panel.hide()
	grid.get_parent().show()
	for tab_button in tabs:
		tab_button.show()
	timer_to_resume = timer
	paused_timer = not timer.is_stopped() and not timer.paused
	if paused_timer:
		timer.paused = true
	game_root = gameplay
	_disable_gameplay_input()
	book_panel.show()
	completion_panel.hide()
	active_tab = 0
	_render_entries()
	visible = true


func _close_book() -> void:
	_play_click()
	detail_panel.hide()
	visible = false
	if paused_timer and is_instance_valid(timer_to_resume):
		timer_to_resume.paused = false
	paused_timer = false
	_restore_gameplay_input()


func show_completion() -> void:
	completion_seen = true
	_save_progress()
	visible = true
	book_panel.hide()
	completion_panel.show()


func _play_again() -> void:
	if restarting_from_victory:
		return
	restarting_from_victory = true
	_play_click()
	# Reuse the exact title-screen opening curtains and sound.
	# The old victory screen stays visible as the curtain halves slide away.
	var music := get_tree().root.get_node_or_null("CalcuMonstersMusic") as AudioStreamPlayer
	var curtain := preload("res://curtain_transition.gd").new()
	get_tree().root.add_child(curtain)
	curtain.begin("res://main.tscn", music)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE and book_panel.visible:
			_close_book()
		get_viewport().set_input_as_handled()
