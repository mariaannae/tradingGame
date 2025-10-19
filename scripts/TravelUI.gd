extends Control

signal travel_confirmed(city_name: String, cost: int)

# References
@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var city_list = $Panel/VBoxContainer/ScrollContainer/CityList
@onready var confirm_button = $Panel/VBoxContainer/ConfirmButton

# Data
var player_node: Node2D = null
var economy_manager: Node = null
var selected_city_name: String = ""
var selected_cost: int = 0
var city_buttons: Array = []

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	hide()

func show_travel_options(player: Node2D, economy: Node) -> void:
	"""Display the travel UI with all available cities"""
	player_node = player
	economy_manager = economy
	
	# Clear previous buttons
	for btn in city_buttons:
		btn.queue_free()
	city_buttons.clear()
	
	# Set title
	title_label.text = "Select Destination (Current: %s)" % player_node.current_city_name
	
	# Get all cities
	var all_cities = player_node.get_all_cities()
	
	# Add "Stay" option first
	_add_city_option(player_node.current_city_name, 0, true)
	
	# Add separator
	var separator = HSeparator.new()
	city_list.add_child(separator)
	city_buttons.append(separator)
	
	# Add other cities
	for city in all_cities:
		if city.city_name != player_node.current_city_name:
			var cost = player_node.calculate_travel_cost(city)
			_add_city_option(city.city_name, cost, false)
	
	# Select the "stay" option by default
	selected_city_name = player_node.current_city_name
	selected_cost = 0
	_update_confirm_button()
	
	# Show the popup
	show()

func _add_city_option(city_name: String, cost: int, is_stay: bool) -> void:
	"""Add a city option button to the list"""
	var button = Button.new()
	button.toggle_mode = true
	button.button_group = _get_or_create_button_group()
	
	# Format button text
	if is_stay:
		button.text = "Stay in %s (Cost: 0)" % city_name
	else:
		var available_money = economy_manager.get_money()
		var can_afford = available_money >= cost
		button.text = "%s (Cost: %d)" % [city_name, cost]
		
		# Disable if can't afford
		if not can_afford:
			button.disabled = true
			button.text += " - Cannot Afford"
	
	# Connect button
	button.pressed.connect(_on_city_selected.bind(city_name, cost))
	
	# Add to UI
	city_list.add_child(button)
	city_buttons.append(button)
	
	# Auto-select stay option
	if is_stay:
		button.button_pressed = true

var button_group: ButtonGroup = null
func _get_or_create_button_group() -> ButtonGroup:
	"""Get or create a button group for radio button behavior"""
	if button_group == null:
		button_group = ButtonGroup.new()
	return button_group

func _on_city_selected(city_name: String, cost: int) -> void:
	"""Handle city selection"""
	selected_city_name = city_name
	selected_cost = cost
	_update_confirm_button()
	print("Selected city: %s, Cost: %d" % [city_name, cost])

func _update_confirm_button() -> void:
	"""Update the confirm button text"""
	if selected_cost == 0:
		confirm_button.text = "Stay (No Cost)"
	else:
		confirm_button.text = "Travel to %s (-%d)" % [selected_city_name, selected_cost]

func _on_confirm_pressed() -> void:
	"""Handle confirm button press"""
	print("Travel confirmed: %s, Cost: %d" % [selected_city_name, selected_cost])
	travel_confirmed.emit(selected_city_name, selected_cost)
	hide()

func _on_close_requested() -> void:
	"""Handle window close (optional escape mechanism)"""
	# For now, force selection of "stay"
	selected_city_name = player_node.current_city_name
	selected_cost = 0
	travel_confirmed.emit(selected_city_name, selected_cost)
	hide()
