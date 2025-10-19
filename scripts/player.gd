extends Node2D

signal player_moved(city_name: String)
signal game_started(city_name: String)

# Configuration
@export var travel_cost_per_unit: float = 0.2

# Current state
var current_city_name: String = ""
var current_city_node: Node2D = null

# References
var cities_node: Node2D = null

func _ready() -> void:
	# Wait for parent scene to be fully loaded
	await get_tree().process_frame
	_initialize_location()

func _initialize_location() -> void:
	# Get reference to Cities node from parent scene
	cities_node = get_node("../Cities")
	if cities_node == null:
		push_error("Cities node not found!")
		return
	
	# Get all city nodes
	var city_children = cities_node.get_children()
	if city_children.size() == 0:
		push_error("No cities found!")
		return
	
	# Choose a random starting city
	var random_index = randi() % city_children.size()
	var starting_city = city_children[random_index]
	
	# Set initial location
	set_current_city(starting_city)
	print("Player starting in: %s" % current_city_name)
	
	# Emit game started signal for initial popup
	game_started.emit(current_city_name)

func set_current_city(city_node: Node2D) -> void:
	"""Set the player's current city and move sprite to that location"""
	if city_node == null:
		push_error("Invalid city node!")
		return
	
	# Clear highlight from previous city
	if current_city_node != null and current_city_node.has_method("set_as_current_city"):
		current_city_node.set_as_current_city(false)
	
	current_city_node = city_node
	current_city_name = city_node.city_name
	
	# Move player sprite to city position
	global_position = city_node.global_position
	
	# Highlight the new current city
	if current_city_node.has_method("set_as_current_city"):
		current_city_node.set_as_current_city(true)
	
	# Emit signal
	player_moved.emit(current_city_name)
	print("Player moved to: %s at position %v" % [current_city_name, global_position])

func calculate_distance_to_city(target_city_node: Node2D) -> float:
	"""Calculate the distance from current city to target city"""
	if current_city_node == null or target_city_node == null:
		return 0.0
	
	var distance = current_city_node.global_position.distance_to(target_city_node.global_position)
	return distance

func calculate_travel_cost(target_city_node: Node2D) -> int:
	"""Calculate the cost to travel to a target city"""
	var distance = calculate_distance_to_city(target_city_node)
	var cost = int(distance * travel_cost_per_unit)
	return cost

func get_all_cities() -> Array:
	"""Get list of all city nodes"""
	if cities_node == null:
		return []
	return cities_node.get_children()

func get_city_by_name(city_name: String) -> Node2D:
	"""Find a city node by name"""
	if cities_node == null:
		return null
	
	for city in cities_node.get_children():
		if city.city_name == city_name:
			return city
	
	return null

func can_travel_to(city_name: String, available_money: int) -> bool:
	"""Check if player can afford to travel to a city"""
	var target_city = get_city_by_name(city_name)
	if target_city == null:
		return false
	
	var cost = calculate_travel_cost(target_city)
	return available_money >= cost

func travel_to_city(city_name: String) -> bool:
	"""Move player to a new city"""
	var target_city = get_city_by_name(city_name)
	if target_city == null:
		push_error("City not found: %s" % city_name)
		return false
	
	set_current_city(target_city)
	return true
