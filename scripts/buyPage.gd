extends Node

@export var grid : GridContainer
@export var resourceButton : PackedScene
@export var economyManager : EconomyManager
@export var turns : Node
@export var cityNodes : Node
@export var eventManager: Node
@export var welcomePopup: Control
var currentCity 
var player_node: Node2D = null
var has_shown_welcome: bool = false

func _ready() -> void:
	await get_tree().process_frame
	
	# Get player reference
	player_node = get_node("../../Player")
	
	# Connect to player's game_started signal
	if player_node:
		player_node.game_started.connect(_on_game_started)
	
	# Connect welcome popup
	if welcomePopup:
		welcomePopup.ok_pressed.connect(_on_welcome_ok_pressed)
	
	for city in cityNodes.get_children():
		city.city_clicked.connect(_on_city_clicked)
	set_ui_active(find_child("bg"),false)
	find_child("AddButton").pressed.connect(on_add_clicked)
	find_child("SubtractButton").pressed.connect(on_sub_clicked)
	find_child("CloseButton").pressed.connect(set_ui_active.bind(find_child("bg"),false))
	
	buyButton.pressed.connect(on_buy_clicked)
	sellButton.pressed.connect(on_sell_clicked)

func _on_game_started(city_name: String) -> void:
	"""Handle the initial game start - show welcome popup"""
	if welcomePopup and not has_shown_welcome:
		welcomePopup.show_welcome(city_name)
		has_shown_welcome = true

func _on_welcome_ok_pressed() -> void:
	"""When welcome popup OK is clicked, open the buyPage for current city"""
	if player_node:
		_open_buypage_for_city(player_node.current_city_name)

func _on_city_clicked(city_name: String) -> void:
	# Check if player is in this city
	if player_node and player_node.current_city_name != city_name:
		print("Cannot trade in %s - you are currently in %s" % [city_name, player_node.current_city_name])
		_show_wrong_city_message(city_name)
		return
	
	_open_buypage_for_city(city_name)

func _open_buypage_for_city(city_name: String) -> void:
	"""Open the buy page for the specified city"""
	currentCity = cityNodes.find_child(city_name)
	set_ui_active(find_child("bg"),true)
	initialize()
	print("Opened buypage for city:", city_name)

func _show_wrong_city_message(city_name: String) -> void:
	"""Show a message that player needs to travel to this city first"""
	# For now, just print to console
	# TODO: Could add a popup message here if desired
	print("Travel to %s first to trade there!" % city_name)


func initialize() -> void:
	for child in grid.get_children():
		child.queue_free()
	await get_tree().process_frame
	var hasFirst : bool = false
	for resource_name in currentCity.available_resources:
		var btn := resourceButton.instantiate()
		if btn == null:
			continue
		
		btn.name = resource_name

		grid.add_child(btn)
		
		var data : ResourceData = economyManager.resources_dict.get(resource_name)
		if !hasFirst:
			currentRes = data
		btn.find_child("Button").icon = data.texture
		btn.find_child("Button").pressed.connect(on_res_clicked.bind(btn.name))
		btn.find_child("Price").text = str(_getPrice(data))
	totalPrice = 0
	currentCount = 0
	_updateUI()
	
var currentRes : ResourceData
var currentCount = 0
var totalPrice : int
		
func on_sub_clicked()-> void:
	currentCount -= 1
	if currentCount < 0:
		currentCount =0
	totalPrice = _getPrice(currentRes)*currentCount
	_updateUI()
	return

func on_add_clicked()-> void:
	currentCount += 1
	totalPrice = _getPrice(currentRes)*currentCount
	_updateUI()
	return

func on_buy_clicked()-> bool:
	var name:String
	for key in economyManager.resources_dict.keys():
		if  economyManager.resources_dict.get(key,0) == currentRes:
			name=key
			break
	if economyManager.try_to_buy(name, currentCount, currentCity.current_season):
		totalPrice = 0
		currentCount = 0
		_updateUI()
		return true
	return false

func on_sell_clicked() -> bool:
	if currentCount <= 0:
		return false
	
	var name: String
	for key in economyManager.resources_dict.keys():
		if economyManager.resources_dict[key] == currentRes:
			name = key
			break
	
	if economyManager.try_to_sell(name, currentCount, currentCity.current_season):
		# Reset count and total
		currentCount = 0
		totalPrice = 0
		_updateUI()
		return true
	return false

func on_res_clicked(name:String)-> void:

	currentRes = economyManager.resources_dict[name]
	_updateUI()
	return
	
func _getPrice (data:ResourceData )->int:
	return economyManager.get_price(data,currentCity.current_season)
	 
	
#region --------------UI------------------
@export var buyPriceLabel : Label
@export var currentResTex: TextureRect
@export var buyCount : Label
@export var buyButton : Button
@export var sellButton: Button

func _updateUI() -> void:
	currentResTex.texture = currentRes.texture
	buyCount.text = str(currentCount)
	buyPriceLabel.text = str(totalPrice)
	return

var uiState :bool = true
func set_ui_active(control: Control, active: bool) -> void:
	
	if !active && uiState:
		control.position -= Vector2(1000,0)
		uiState = false
	elif active && !uiState :
		control.position += Vector2(1000,0)
		uiState = true
#endregion
