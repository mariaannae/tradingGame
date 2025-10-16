
extends Area2D

@export var city_name: String = ""
@export var icon_texture: Texture2D
@export_enum("cold", "steppe", "coastal", "warm") var biome: String = "cold"

signal city_clicked(id: String)

var effective := {}        # will hold computed stats later
var current_season := ""   # "winter"/"spring"/"summer"/"fall"

func _ready() -> void:
	input_pickable = true
	if icon_texture:
		$"Icon".texture = icon_texture
	if city_name != "":
		$"Name".text = city_name
	$"Name".position.y = 18  # nudge label below the icon
	$"Season".position.y = 35  # nudge season label below the name
	$"Season".text = ""  # start empty

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("city_clicked", city_name)

func set_season_visual(season: String) -> void:
	current_season = season
	var t := $"Icon"
	match season:
		"winter": t.modulate = Color(0.80, 0.90, 1.00)
		"spring": t.modulate = Color(0.90, 1.00, 0.90)
		"summer": t.modulate = Color(1.00, 1.00, 0.90)
		"fall": t.modulate = Color(1.00, 0.93, 0.85)
		_       : t.modulate = Color.WHITE
	
	# Update the season label
	$"Season".text = season.capitalize()
