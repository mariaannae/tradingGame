extends Node
class_name EconomyManager

@export var start_money: int = 1000
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
	
		# Connect End Turn button
	if end_turn_button:
		end_turn_button.pressed.connect(self.end_turn)
	
	print("All events:", event_manager.all_events)

func _add_money(amount: int) -> void:
	current_money += amount

func _spend_money(amount: int) -> bool:
	if current_money >= amount:
		current_money -= amount
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
		
	print("EconomySystem ready. Current money =", current_money)
	
	
func get_money() -> int:
	return current_money
	
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
	money_label_node.text=" Money: " + str(current_money)
	
func end_turn() -> void:
	if event_manager:
		event_manager.trigger_random_event()
	else:
		print("No event manager found!")

func _on_event_triggered(event_data: Dictionary) -> void:
	current_event = event_data
	
	# Add this event to the active list
	eventNames.append(event_data["key"])
	
	print("Active events:", eventNames)

	if event_popup:
		event_popup.show_event(event_data)
	else:
		print("No event popup to show event")

func _on_event_popup_closed() -> void:
	print("Event popup closed, next turn can start")
	
#endregion
