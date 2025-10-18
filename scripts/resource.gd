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
		var temp_seasons: Array[String] = []
		for item in data["favored_season"]:
			temp_seasons.append(String(item))
		favored_season = temp_seasons
	if "local_biomes" in data:
		var temp_biomes: Array[String] = []
		for item in data["local_biomes"]:
			temp_biomes.append(String(item))
		local_biomes = temp_biomes
	if "event_modifiers" in data:
		event_modifiers = data["event_modifiers"]
	current_price = base_price

func get_price(season: String = "", active_events: Array[String] = []) -> float:
	var price = base_price
	
	# Apply seasonal surcharge
	if season in favored_season:
		price *= 0.9
	elif season != "":
		price *= 1.1
	
	# Apply event modifiers
	for ev in active_events:
		if event_modifiers.has(ev):
			price *= event_modifiers[ev]
	
	return round(price)

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
