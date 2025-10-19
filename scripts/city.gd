extends Area2D

@export var city_name: String = ""
@export var icon_sprite_frames: SpriteFrames   # now supports animated icons
@export_enum("cold", "steppe", "coastal", "warm") var biome: String = "cold"

signal city_clicked(id: String)

var effective := {}        # will hold computed stats later
var current_season := ""   # "winter"/"spring"/"summer"/"fall"
var available_resources: Array[String] = []

func _ready() -> void:
	input_pickable = true
	# assign animated sprite frames if available
	if icon_sprite_frames:
		$"Icon".sprite_frames = icon_sprite_frames
		$"Icon".play("default")  # plays the default animation
	
	if city_name != "":
		$"Name".text = city_name
	$"Name".position.y = 18  # nudge label below the icon
	$"Season".position.y = 35  # nudge season label below the name
	$"Season".text = ""  # start empty
	
	# Create export label if it doesn't exist
	if not has_node("ExportLabel"):
		var export_label = Label.new()
		export_label.name = "ExportLabel"
		export_label.position.y = 50
		export_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		export_label.add_theme_font_size_override("font_size", 10)
		add_child(export_label)
	
	$"ExportLabel".text = ""

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
	
	# Update the season label
	$"Season".text = season.capitalize()
	
	# Update export display
	update_export_display()

func update_export_display() -> void:
	if not has_node("ExportLabel"):
		return
	
	if available_resources.is_empty():
		$"ExportLabel".text = "Export Options:\nNone"
	else:
		var display_text = "Export Options:"
		for resource_name in available_resources:
			display_text += "\n• " + resource_name
		$"ExportLabel".text = display_text
