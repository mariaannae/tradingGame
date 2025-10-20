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

# References to other nodes
var player_node: Node2D = null
var travel_ui: Control = null
var buy_page: Node = null
var economy_manager: Node = null
var game_over_popup: Control = null

func _ready() -> void:
	_load_resources()
	_load_biome_sequences()
	_register_cities()
	_build_schedules_for_all()
	_apply_current_seasons(true)
	
	# Get references to other nodes
	player_node = $"Player"
	travel_ui = $"UI/TravelUI"
	buy_page = $"UI/BuyPage"
	economy_manager = $"EconomyManager"
	game_over_popup = $"UI/GameOverPopup"
	
	# Hook up the End Turn button
	$"UI/Control/UIStack/EndTurnButton".pressed.connect(_on_end_turn_pressed)
	
	# Hook up travel UI signals
	if travel_ui:
		travel_ui.travel_confirmed.connect(_on_travel_confirmed)
		travel_ui.ui_fully_hidden.connect(_on_travel_ui_hidden)
	
	# Hook up economy manager event completion signal
	if economy_manager:
		economy_manager.event_handling_complete.connect(_on_event_handling_complete)
		economy_manager.game_over.connect(_on_game_over)
	
	# Hook up game over popup
	if game_over_popup:
		game_over_popup.restart_requested.connect(_on_restart_requested)
	
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
	# Close buy page if it's open
	if buy_page and buy_page.has_method("set_ui_active"):
		buy_page.set_ui_active(buy_page.find_child("bg"), false)
	
	# Show travel UI first (event popup will come after travel confirmation)
	if travel_ui and player_node and economy_manager:
		travel_ui.show_travel_options(player_node, economy_manager)
	else:
		push_error("Missing references for travel UI")
		# Fallback: advance turn without travel
		_advance_turn()

func _on_event_handling_complete() -> void:
	"""Called after event popup closes (or immediately if no event occurred)"""
	# Now advance the turn and open buy page
	_advance_turn()
	
	# Open buy page for the current city automatically
	if buy_page and buy_page.has_method("_on_city_clicked"):
		# Wait one frame to ensure everything is updated
		await get_tree().process_frame
		buy_page._on_city_clicked(player_node.current_city_name)

func _on_travel_confirmed(city_name: String, cost: int) -> void:
	"""Handle travel confirmation from UI"""
	print("Travel confirmed: %s, Cost: %d" % [city_name, cost])
	
	# Deduct travel cost
	if cost > 0:
		if economy_manager.get_money() >= cost:
			economy_manager._spend_money(cost)
			print("Paid %d for travel" % cost)
		else:
			push_error("Not enough money for travel! This shouldn't happen.")
			return
	
	# Move player to selected city
	if city_name != player_node.current_city_name:
		player_node.travel_to_city(city_name)
	
	# Note: We don't trigger events here - wait for ui_fully_hidden signal

func _on_travel_ui_hidden() -> void:
	"""Called when TravelUI is fully hidden - now safe to show event popup"""
	print("Travel UI fully hidden, checking for events...")
	
	# Now check for events (event popup will show if event occurs)
	# The event popup will show, then advance turn after it closes
	if economy_manager:
		economy_manager.end_turn()
	else:
		push_error("Missing economy manager reference")
		# Fallback: advance turn without event check
		_advance_turn()
		
		# Open buy page for the current city automatically
		if buy_page and buy_page.has_method("_on_city_clicked"):
			await get_tree().process_frame
			buy_page._on_city_clicked(player_node.current_city_name)

func _advance_turn() -> void:
	"""Advance to the next turn"""
	turn_idx += 1
	_apply_current_seasons(false)
	turn_advanced.emit(turn_idx)
	_update_turn_label()
	
	# Check for loss condition after advancing turn
	if economy_manager and player_node:
		var current_season = city_season.get(player_node.current_city_name, "spring")
		if economy_manager.check_loss_condition(current_season):
			_trigger_game_over()

func _trigger_game_over() -> void:
	"""Trigger the game over state"""
	if game_over_popup and economy_manager:
		economy_manager.game_over.emit()
		game_over_popup.show_game_over(economy_manager.get_money(), turn_idx)

func _on_game_over() -> void:
	"""Handle game over signal from economy manager"""
	print("Game Over!")
	if game_over_popup and economy_manager:
		game_over_popup.show_game_over(economy_manager.get_money(), turn_idx)

func _on_restart_requested() -> void:
	"""Restart the game"""
	# Reset turn counter
	turn_idx = 0
	
	# Reset city phases
	for c in cities:
		c["phase"] = 0
	
	# Rebuild schedules and apply initial seasons
	_build_schedules_for_all()
	_apply_current_seasons(true)
	
	# Reset economy manager (money and stock)
	if economy_manager:
		economy_manager.current_money = economy_manager.start_money
		economy_manager.stock.clear()
		economy_manager.eventNames.clear()
		economy_manager._updateUI()
	
	# Respawn player at random city
	if player_node:
		player_node._initialize_location()
	
	# Update UI
	_update_turn_label()
	
	print("Game restarted!")

func _update_turn_label() -> void:
	var seasonalTurn: int = turn_idx % TURNS_PER_SEASON_STEP + 1
	print("DEBUG: turn_idx=%d, seasonalTurn=%d (calculation: %d %% %d + 1)" % [turn_idx, seasonalTurn, turn_idx, TURNS_PER_SEASON_STEP])
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
		#if resource.is_local_to(biome):
			# Check if it's in season (or if we want to show all local resources)
			#if season in resource.favored_season:
		result.append(resource_name)
	
	return result
