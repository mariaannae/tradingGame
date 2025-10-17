extends Resource
class_name ResourceData

@export var texture: Texture2D
@export var category: String
@export var base_price: float
@export var favored_season: Array[String]
@export var local_biomes: Array[String]
@export var event_modifiers: Dictionary

var current_price: float

func _init(data: Dictionary = {}):
	if data.size() > 0:
		load_from_dict(data)

func load_from_dict(data: Dictionary) -> void:
	if "texture" in data:
		texture = load(data["texture"])
	if "category" in data:
		category = data["category"]
	if "base_price" in data:
		base_price = data["base_price"]
	if "favored_season" in data:
		favored_season = data["favored_season"]
	if "local_biomes" in data:
		local_biomes = data["local_biomes"]
	if "event_modifiers" in data:
		event_modifiers = data["event_modifiers"]
	current_price = base_price

func get_price(season: String = "", events: Array[String] = []) -> float:
	var price = base_price

	# Seasonal modifier
	if season != "" and season in favored_season:
		price *= 1.1  # 10% bonus if in favored season

	# Apply event modifiers
	for event_name in events:
		if event_name in event_modifiers:
			price *= event_modifiers[event_name]

	# Round to 2 decimal places (manual way)
	price = round(price * 100.0) / 100.0
	return price

func is_local_to(biome: String) -> bool:
	return biome in local_biomes

static func load_resources_from_json(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Could not open resource file: %s" % json_path)
		return {}

	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON format in %s" % json_path)
		return {}

	var resources: Dictionary = {}
	for name in data.keys():
		var res_data = data[name]
		var resource = ResourceData.new(res_data)
		resources[name] = resource

	return resources
