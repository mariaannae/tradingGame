extends Node

@export var start_money: int = 1000
@export var MapScenePath: NodePath
var current_money: int = 0
var stock: Dictionary = {}
var res_Dic: Dictionary = {}

func _ready() -> void:
	initialize()
	
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
	print("EconomySystem ready. Current money =", current_money)
	
func get_money() -> int:
	return current_money
	
func try_to_buy(item: ResourceData, quantity: int, season: String = "", events: Array[String] = []) -> bool:
	if quantity <= 0:
		return false

	var price_per_item = item.get_price(season, events)
	var total_cost = price_per_item * quantity

	if _spend_money(total_cost):
		var current_count = stock.get(item, 0)
		stock[item] = current_count + quantity
		print("Bought %d x %s for %.2f, now have %d" % [quantity, item.category, total_cost, stock[item]])
		return true
	else:
		print("Cannot afford %d x %s (need %.2f)" % [quantity, item.category, total_cost])
		return false

func try_to_sell(item: ResourceData, quantity: int, season: String = "", events: Array[String] = []) -> bool:
	if quantity <= 0:
		return false

	var current_count = stock.get(item, 0)
	if current_count < quantity:
		print("Not enough %s to sell! Have %d, need %d" % [item.category, current_count, quantity])
		return false

	var price_per_item = item.get_price(season, events)
	var total_gain = price_per_item * quantity

	stock[item] = current_count - quantity
	_add_money(total_gain)

	print("Sold %d x %s for %.2f, remaining %d" % [quantity, item.category, total_gain, stock[item]])
	return true
#region --------------- UI ---------------------------
@export var stockUI: PackedScene
@export var UIGrid: GridContainer
var resourceUIs := {}
func _initUI() -> void:
	var map_scene = get_node(MapScenePath)
	
	if not map_scene:
		push_error("MapScene not found at path: %s" % MapScenePath)
		return

	var resources_dict = map_scene.all_resources
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

	
#endregion
