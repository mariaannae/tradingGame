extends Node
class_name EconomyManager

signal event_handling_complete
signal game_over

@export var start_money: int = 1000
@export var event_probability: float = 0.5  # 0.0 to 1.0, where 1.0 = 100% chance
@export var MapScenePath: NodePath
var current_money: int = 0
var stock: Dictionary = {}
#var res_Dic: Dictionary = {}
var resources_dict := {}
var eventNames : Array[String]

@onready var event_manager = $RandomEventManager
@onready var event_popup = $"../UI/EventPopup"
var current_event = {}

func _ready() -> void:
	initialize()
	eventNames = []  # initialize to an empty list
	
	print("All events:", event_manager.all_events)

func _add_money(amount: int) -> void:
	current_money += amount
	_updateUI()

func _spend_money(amount: int) -> bool:
	if current_money >= amount:
		current_money -= amount
		_updateUI()
		return true
	else:
		print("Not enough money!")
		return false
		
func initialize()-> void:
	current_money = start_money
	#res_Dic = ResourceData.load_resources_from_json("res://data/resource.json")
	await get_tree().process_frame
	_initUI()
	
	# Initialize event manager with loaded resources
	if event_manager:
		event_manager.initialize(resources_dict)
		event_manager.connect("event_triggered", _on_event_triggered)
	else:
		push_warning("RandomEventManager not found")
		

	if event_popup:
		event_popup.connect("popup_closed", _on_event_popup_closed)
	else:
		push_warning("EventPopup not found")
		
	print("EconomySystem ready. Current Money =", current_money)
	
	
func get_money() -> int:
	return current_money

func get_minimum_resource_price(season: String) -> int:
	"""Calculate the minimum price of any available resource in the current city"""
	var map_scene = get_node(MapScenePath)
	if not map_scene:
		return 0
	
	var player = map_scene.get_node_or_null("Player")
	if not player:
		return 0
	
	var current_city_name = player.current_city_name
	
	# Get the available resources in the current city
	var city_effective = map_scene.city_effective.get(current_city_name, {})
	var available_resources: Array = city_effective.get("resources", [])
	
	# Find minimum price among available resources
	var min_price = INF
	for resource_name in available_resources:
		if resource_name in resources_dict:
			var resource: ResourceData = resources_dict[resource_name]
			var price = resource.get_price(season, eventNames)
			if price < min_price:
				min_price = price
	
	return int(min_price) if min_price != INF else 0

func has_sellable_inventory(season: String) -> bool:
	"""Check if player has any items that can be sold in the current city"""
	var map_scene = get_node(MapScenePath)
	if not map_scene:
		return false
	
	var player = map_scene.get_node_or_null("Player")
	if not player:
		return false
	
	var current_city_name = player.current_city_name
	
	# Get the available resources in the current city
	var city_effective = map_scene.city_effective.get(current_city_name, {})
	var available_resources: Array = city_effective.get("resources", [])
	
	# Check if player has any of the available resources
	for item_name in stock.keys():
		if stock[item_name] > 0 and item_name in available_resources:
			return true
	
	return false

func get_minimum_travel_cost() -> int:
	"""Get the minimum cost to travel to any city from current location"""
	var map_scene = get_node(MapScenePath)
	if not map_scene:
		return 0
	
	var player = map_scene.get_node_or_null("Player")
	if not player:
		return 0
	
	var all_cities = player.get_all_cities()
	var min_cost = INF
	
	for city in all_cities:
		if city.city_name != player.current_city_name:
			var cost = player.calculate_travel_cost(city)
			if cost < min_cost:
				min_cost = cost
	
	return int(min_cost) if min_cost != INF else 0

func check_loss_condition(season: String) -> bool:
	"""Check if player has lost (no sellable inventory AND can't afford to buy OR travel)"""
	# Player only loses if they have no inventory that can be sold in the current city
	var has_sellable = has_sellable_inventory(season)
	if has_sellable:
		print("Loss check: Player has sellable inventory, continuing game")
		return false
	
	# Get minimum resource price in current city
	var min_resource_price = get_minimum_resource_price(season)
	
	# Get minimum travel cost to any other city
	var min_travel_cost = get_minimum_travel_cost()
	
	# Player loses if they can't afford to buy anything AND can't afford to travel
	var cant_buy = current_money < min_resource_price
	var cant_travel = current_money < min_travel_cost
	
	print("Loss check: money=%d, min_buy=%d, min_travel=%d, cant_buy=%s, cant_travel=%s" % [current_money, min_resource_price, min_travel_cost, cant_buy, cant_travel])
	
	var should_lose = cant_buy and cant_travel
	if should_lose:
		print("GAME OVER: Player has no sellable inventory, can't buy (need %d), and can't travel (need %d)" % [min_resource_price, min_travel_cost])
	
	return should_lose

func check_and_trigger_loss(season: String) -> void:
	"""Check loss condition and emit game_over signal if player has lost"""
	if check_loss_condition(season):
		game_over.emit()
	
func try_to_buy(itemName: String, quantity: int, season: String = "") -> bool:
	if quantity <= 0:
		return false
	
	var item : ResourceData=resources_dict[itemName]
	var price_per_item = item.get_price(season, eventNames)
	var total_cost = price_per_item * quantity

	if _spend_money(total_cost):
		var current_count = stock.get(itemName, 0)
		stock[itemName] = current_count + quantity
		print("Bought %d x %s for %.2f, now have %d" % [quantity, item.category, total_cost, stock[itemName]])
		_updateUI()
		
		# Check for loss condition after purchase
		check_and_trigger_loss(season)
		return true
	else:
		print("Cannot afford %d x %s (need %.2f)" % [quantity, item.category, total_cost])
		return false
		
	
func try_to_sell(itemName: String, quantity: int, season: String = "") -> bool:
	if quantity <= 0:
		return false
		
	var item=resources_dict[itemName]
	var current_count = stock.get(itemName, 0)
	if current_count < quantity:
		print("Not enough %s to sell! Have %d, need %d" % [item.category, current_count, quantity])
		return false

	var price_per_item = item.get_price(season, eventNames)
	var total_gain = price_per_item * quantity

	stock[itemName] = current_count - quantity
	_add_money(total_gain)

	print("Sold %d x %s for %.2f, remaining %d" % [quantity, item.category, total_gain, stock[itemName]])
	_updateUI()
	return true

func get_price(res:ResourceData,season:String) -> int:
		return res.get_price(season,eventNames)

#region --------------- UI ---------------------------
@export var stockUI: PackedScene
@export var UIGrid: GridContainer
@export var end_turn_button: Button

var resourceUIs := {}
func _initUI() -> void:
	var map_scene = get_node(MapScenePath)
	
	if not map_scene:
		push_error("MapScene not found at path: %s" % MapScenePath)
		return

	resources_dict = map_scene.all_resources
	if typeof(resources_dict) != TYPE_DICTIONARY:
		push_error("MapScene.all_resources is not a Dictionary")
		return

	for child in UIGrid.get_children():
		child.queue_free()

	
	for name in resources_dict.keys():
		var resource = resources_dict[name]
		if stockUI:
			var ui_instance = stockUI.instantiate()
			var icon_node = ui_instance.find_child("Icon")
			if icon_node and icon_node is TextureRect:
				icon_node.texture = resource.texture
			else:
				push_warning("Icon node not found or not TextureRect")
			UIGrid.add_child(ui_instance)
			# Set the resource name for tooltip (using the dictionary key)
			ui_instance.set_resource_name(name)
			resourceUIs[name] = ui_instance
		else:
			push_error("stockUI PackedScene not assigned!")

@export var money_contorl:Control
func _updateUI() -> void:
	for name in resources_dict.keys():
		var label_node = resourceUIs[name].find_child("Label")
		if label_node and label_node is Label:
				label_node.text = str(stock.get(name,0))
	var money_label_node = money_contorl.find_child("Label")
	money_label_node.text="Current Money: $" + str(current_money)
	
func end_turn() -> void:
	# Check if event should occur based on probability
	var roll = randf()  # Returns value between 0.0 and 1.0
	
	if roll < event_probability and event_manager and not event_manager.all_events.is_empty():
		# Trigger event - the popup will show and signal will emit when closed
		event_manager.trigger_random_event()
	else:
		# No event occurs, emit signal immediately to proceed
		print("No event triggered this turn")
		event_handling_complete.emit()

func _on_event_triggered(event_data: Dictionary) -> void:
	current_event = event_data
	
	# Add this event to the active list
	eventNames.append(event_data["key"])
	
	print("Active events:", eventNames)

	if event_popup:
		event_popup.show_event(event_data)
	else:
		print("No event popup to show event")
		# If popup fails to show, still emit signal to continue
		event_handling_complete.emit()

func _on_event_popup_closed() -> void:
	print("Event popup closed, next turn can start")
	event_handling_complete.emit()
	
#endregion
