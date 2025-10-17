extends Node2D

signal city_season_changed(id: String, season: String, effective: Dictionary)
signal turn_advanced(turn_index: int)

const TURNS_PER_SEASON_STEP : int = 3  # seasons change every 3 turns for now


# biome seasonal sequences loaded from JSON
var biome_sequences := {}
# all game resources loaded from JSON
var all_resources := {}

var cities := []                 # list of dictionaries (metadata + node)
var city_schedule := {}          # id -> Array[String]
var city_season := {}            # id -> String
var city_effective := {}         # id -> Dictionary

var turn_idx := 0

func _ready() -> void:
	_load_resources()
	_load_biome_sequences()
	_register_cities()
	_build_schedules_for_all()
	_apply_current_seasons(true)
	# Hook up the End Turn button
	$"UI/Control/UIStack/EndTurnButton".pressed.connect(_on_end_turn_pressed)
	_update_turn_label()


func _register_cities() -> void:
	cities.clear()
	var cities_node = $"Cities"
	if cities_node == null:
		push_warning("Cities node not found")
		return
	
	for city_node in cities_node.get_children():
		if city_node.has_method("set_season_visual"):
			var city_data := {
				"id": city_node.city_name,
				"biome": city_node.biome,
				"phase": 0,  # all cities start at phase 0
				"node": city_node,
				"base": {
					"food": 5,
					"wood": 5,
					"stone": 5,
					"metal": 5
				}
			}
			cities.append(city_data)
			print("Registered city: %s (biome: %s)" % [city_data["id"], city_data["biome"]])
	
	print("Total cities registered: %d" % cities.size())

func _on_end_turn_pressed() -> void:
	turn_idx += 1
	_apply_current_seasons(false)
	turn_advanced.emit(turn_idx)
	_update_turn_label()

func _update_turn_label() -> void:
	var seasonalTurn: int = turn_idx%TURNS_PER_SEASON_STEP + 1
	$"UI/Control/UIStack/TurnLabel".text = "Turn: %d/%s" % [seasonalTurn, TURNS_PER_SEASON_STEP]



func _load_resources() -> void:
	all_resources = ResourceData.load_resources_from_json("res://data/resources.json")
	print("Loaded %d resources from resources.json" % all_resources.size())

func _load_biome_sequences() -> void:
	var file_path := "res://data/biome_seasons.json"
	if not FileAccess.file_exists(file_path):
		push_error("Biome sequences file not found: %s" % file_path)
		return
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open biome sequences file: %s" % file_path)
		return
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("Failed to parse biome sequences JSON: %s" % json.get_error_message())
		return
	
	biome_sequences = json.get_data()
	print("Loaded biome sequences for %d biomes" % biome_sequences.size())
	for biome_name in biome_sequences.keys():
		var biome_data = biome_sequences[biome_name]
		print("  Biome '%s': sequence = %s" % [biome_name, biome_data.get("sequence", [])])

func _build_schedules_for_all() -> void:
	city_schedule.clear()
	for c in cities:
		var biome := String(c["biome"])
		var sched := _build_schedule_for_biome(biome)
		city_schedule[c["id"]] = sched
		print("City %s (biome: %s) schedule: %s" % [c["id"], biome, sched])

func _apply_current_seasons(force_emit:=false) -> void:
	for c in cities:
		var sched: Array = city_schedule[c["id"]]
		# only advance the schedule every 3 turns
		var schedule_step := int(floor(float(turn_idx) / float(TURNS_PER_SEASON_STEP)))
		var idx := (schedule_step + int(c["phase"])) % sched.size()
		
		var s: String = sched[idx]
		var eff := _effective_for_city(c, s)
		var changed: bool = force_emit or s != city_season[c["id"]]
		city_season[c["id"]] = s
		city_effective[c["id"]] = eff
		
		# Debug output
		#print("City %s: turn=%d, step=%d, idx=%d/%d, season=%s, changed=%s" % [c["id"], turn_idx, schedule_step, idx, sched.size(), s, changed])
		
		if changed:
			city_season_changed.emit(c["id"], s, eff)
			if c["node"].has_method("set_season_visual"):
				var resources: Array[String] = eff.get("resources", [])
				c["node"].set_season_visual(s, resources)

# --------- schedules (loaded from biome JSON data)

func _build_schedule_for_biome(biome: String) -> Array[String]:
	var biome_data = biome_sequences.get(biome, {})
	var sequence = biome_data.get("sequence", [])
	
	if sequence.is_empty():
		push_warning("No sequence found for biome '%s', using default" % biome)
		return ["spring", "summer", "fall", "winter"]
	
	# Convert the sequence to Array[String]
	var result: Array[String] = []
	for season in sequence:
		result.append(String(season))
	
	return result

# --------- resource filtering

func _effective_for_city(city: Dictionary, season: String) -> Dictionary:
	var biome := String(city.get("biome", ""))
	var available_resources := _get_city_resources(biome, season)
	return {
		"resources": available_resources
	}

func _get_city_resources(biome: String, season: String) -> Array[String]:
	var result: Array[String] = []
	
	for resource_name in all_resources.keys():
		var resource: ResourceData = all_resources[resource_name]
		
		# Check if resource is local to this biome
		if resource.is_local_to(biome):
			# Check if it's in season (or if we want to show all local resources)
			if season in resource.favored_season:
				result.append(resource_name)
	
	return result
