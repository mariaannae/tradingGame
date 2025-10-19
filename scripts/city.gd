extends Area2D

@export var city_name: String = ""
@export var icon_sprite_frames: SpriteFrames   # now supports animated icons
@export_enum("cold", "steppe", "coastal", "warm") var biome: String = "cold"

signal city_clicked(id: String)

var effective := {}        # will hold computed stats later
var current_season := ""   # "winter"/"spring"/"summer"/"fall"
var available_resources: Array[String] = []

# UI elements
var name_background: Panel
var resource_grid: GridContainer
var tooltip_panel: Panel
var tooltip_label: Label

# Resource data cache
var resource_data: Dictionary = {}

func _ready() -> void:
	input_pickable = true
	
	# Load resource data
	load_resource_data()
	
	# assign animated sprite frames if available
	if icon_sprite_frames:
		$"Icon".sprite_frames = icon_sprite_frames
		$"Icon".play("default")  # plays the default animation
	
	# Setup city name with background and biome color
	setup_name_display()
	
	# Setup season label - we'll configure it later when season is set
	$"Season".text = ""  # start empty
	$"Season".visible = false  # hide until we have season data
	
	# Remove old export label if it exists
	if has_node("ExportLabel"):
		$"ExportLabel".queue_free()
	
	# Create resource grid
	create_resource_grid()
	
	# Create tooltip
	create_tooltip()

func load_resource_data() -> void:
	var file = FileAccess.open("res://data/resources.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			resource_data = json.data
		else:
			push_error("Failed to parse resources.json")

func setup_name_display() -> void:
	# Get reference to name label
	var name_label = $"Name"
	
	# Configure name label first
	if city_name != "":
		name_label.text = city_name
	
	# Use dark text on light biome-colored background for good contrast
	name_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))  # Dark text
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Calculate size based on text
	await get_tree().process_frame  # Wait for label to calculate size
	var text_size = name_label.size
	var padding_h = 10
	var padding_v = 6
	
	# Create background panel
	name_background = Panel.new()
	name_background.name = "NameBackground"
	
	# Style the background with biome color
	var style = StyleBoxFlat.new()
	var biome_color = get_biome_color()
	style.bg_color = biome_color  # Light biome color for background
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0, 0, 0, 0.5)  # Subtle border
	name_background.add_theme_stylebox_override("panel", style)
	
	# Position background centered below the icon
	name_background.position = Vector2(-text_size.x / 2 - padding_h / 2, 20)
	name_background.size = Vector2(text_size.x + padding_h, text_size.y + padding_v)
	
	add_child(name_background)
	
	# Reparent name label to be inside the background
	remove_child(name_label)
	name_background.add_child(name_label)
	
	# Position name label inside background panel
	name_label.position = Vector2(padding_h / 2, padding_v / 2)

func get_biome_color() -> Color:
	match biome:
		"cold": return Color(0.53, 0.81, 0.92)  # Light blue #87CEEB
		"steppe": return Color(0.82, 0.71, 0.55)  # Tan #D2B48C
		"coastal": return Color(0.13, 0.70, 0.67)  # Teal #20B2AA
		"warm": return Color(1.0, 0.5, 0.31)  # Coral #FF7F50
		_: return Color.WHITE

func create_resource_grid() -> void:
	resource_grid = GridContainer.new()
	resource_grid.name = "ResourceGrid"
	resource_grid.columns = 3
	resource_grid.add_theme_constant_override("h_separation", 6)
	resource_grid.add_theme_constant_override("v_separation", 6)
	add_child(resource_grid)

func create_tooltip() -> void:
	tooltip_panel = Panel.new()
	tooltip_panel.name = "TooltipPanel"
	tooltip_panel.visible = false
	tooltip_panel.z_index = 100
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	tooltip_label = Label.new()
	tooltip_label.add_theme_font_size_override("font_size", 11)
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_panel.add_child(tooltip_label)
	
	add_child(tooltip_panel)

func show_tooltip(resource_name: String, icon_position: Vector2) -> void:
	tooltip_label.text = resource_name.capitalize()
	await get_tree().process_frame
	
	# Position tooltip above the icon
	var tooltip_pos = icon_position + Vector2(-tooltip_panel.size.x / 2, -tooltip_panel.size.y - 5)
	tooltip_panel.position = tooltip_pos
	tooltip_panel.visible = true

func hide_tooltip() -> void:
	tooltip_panel.visible = false

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("city_clicked", city_name)
		print("city_clicked", city_name)

func set_season_visual(season: String, resources: Array[String] = []) -> void:
	current_season = season
	available_resources = resources
	
	var t := $"Icon"
	match season:
		"winter": t.modulate = Color(0.80, 0.90, 1.00)
		"spring": t.modulate = Color(0.90, 1.00, 0.90)
		"summer": t.modulate = Color(1.00, 1.00, 0.90)
		"fall": t.modulate = Color(1.00, 0.93, 0.85)
		_       : t.modulate = Color.WHITE
	
	# Update the season label with background
	setup_season_label(season)
	
	# Update export display
	update_export_display()

func setup_season_label(season: String) -> void:
	var season_label = $"Season"
	season_label.text = season.capitalize()
	season_label.visible = true
	season_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	season_label.add_theme_font_size_override("font_size", 10)
	season_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))  # White text
	
	# Add semi-transparent dark background to season label
	var season_style = StyleBoxFlat.new()
	season_style.bg_color = Color(0, 0, 0, 0.7)
	season_style.corner_radius_top_left = 3
	season_style.corner_radius_top_right = 3
	season_style.corner_radius_bottom_left = 3
	season_style.corner_radius_bottom_right = 3
	season_style.content_margin_left = 4
	season_style.content_margin_right = 4
	season_style.content_margin_top = 2
	season_style.content_margin_bottom = 2
	season_label.add_theme_stylebox_override("normal", season_style)
	
	# Wait for size to be calculated with new style
	await get_tree().process_frame
	
	# Position season label below name background with proper spacing
	var season_y = 42  # Default position with more space
	if name_background != null:
		season_y = name_background.position.y + name_background.size.y + 5  # 5px gap for better spacing
	season_label.position = Vector2(-season_label.size.x / 2, season_y)

func update_export_display() -> void:
	# Clear existing icons
	for child in resource_grid.get_children():
		child.queue_free()
	
	if available_resources.is_empty():
		resource_grid.visible = false
		return
	
	resource_grid.visible = true
	
	# Add resource icons
	for resource_name in available_resources:
		if resource_data.has(resource_name):
			var texture_path = resource_data[resource_name].get("texture", "")
			if texture_path != "":
				# Create a panel to hold the icon with background
				var icon_panel = Panel.new()
				var panel_style = StyleBoxFlat.new()
				panel_style.bg_color = Color(1, 1, 1, 0.9)  # White background
				panel_style.corner_radius_top_left = 3
				panel_style.corner_radius_top_right = 3
				panel_style.corner_radius_bottom_left = 3
				panel_style.corner_radius_bottom_right = 3
				panel_style.border_width_left = 1
				panel_style.border_width_right = 1
				panel_style.border_width_top = 1
				panel_style.border_width_bottom = 1
				panel_style.border_color = Color(0, 0, 0, 0.3)
				icon_panel.add_theme_stylebox_override("panel", panel_style)
				icon_panel.custom_minimum_size = Vector2(32, 32)
				
				# Create the icon
				var icon = TextureRect.new()
				icon.texture = load(texture_path)
				icon.custom_minimum_size = Vector2(28, 28)
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				icon.position = Vector2(2, 2)  # Small padding inside panel
				
				# Add icon to panel
				icon_panel.add_child(icon)
				
				# Add mouse detection for tooltip on the panel
				icon_panel.mouse_filter = Control.MOUSE_FILTER_PASS
				icon_panel.mouse_entered.connect(_on_resource_icon_mouse_entered.bind(resource_name, icon_panel))
				icon_panel.mouse_exited.connect(_on_resource_icon_mouse_exited)
				
				resource_grid.add_child(icon_panel)
	
	# Position grid and check bounds
	await get_tree().process_frame
	position_resource_grid()

func position_resource_grid() -> void:
	# Position below season label with proper spacing
	var season_label = $"Season"
	var grid_y = 62
	
	# If season label is visible, position below it
	if season_label.visible:
		grid_y = season_label.position.y + season_label.size.y + 4  # 4px gap
	
	# Always center the grid horizontally
	resource_grid.position = Vector2(-resource_grid.size.x / 2, grid_y)

func _on_resource_icon_mouse_entered(resource_name: String, icon_node: Control) -> void:
	show_tooltip(resource_name, icon_node.global_position - global_position)

func _on_resource_icon_mouse_exited() -> void:
	hide_tooltip()
