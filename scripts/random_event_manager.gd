extends Node
signal event_triggered(event_data: Dictionary)

var all_events: Array = []
var current_event: Dictionary = {}
var resources_dict: Dictionary = {}

func initialize(resource_dict: Dictionary):
	resources_dict = resource_dict
	_collect_unique_events()

func _collect_unique_events() -> void:
	all_events.clear()
	var seen = {}
	for name in resources_dict.keys():
		var item = resources_dict[name]
		if typeof(item.event_modifiers) == TYPE_DICTIONARY:
			for ev_name in item.event_modifiers.keys():
				if not seen.has(ev_name):
					seen[ev_name] = true
					all_events.append(ev_name)
	print("Collected events:", all_events)

func trigger_random_event() -> void:
	if all_events.is_empty():
		push_warning("No events found in resources!")
		return

	var chosen_event = all_events.pick_random()
	current_event = {
		"name": chosen_event.capitalize().replace("_", " "),
		"key": chosen_event,
		"description": _generate_description(chosen_event),
	}
	print("Event Triggered:", current_event)
	emit_signal("event_triggered", current_event)

func _generate_description(event_name: String) -> String:
	match event_name:
		"food_shortage":
			return "A famine spreads across the realm — food prices soar!"
		"harvest_festival":
			return "The harvest season brings abundance — food is cheaper!"
		"mine_collapse":
			return "A tragic mine collapse disrupts production — ore and precious metals become scarce!"
		"royal_festival":
			return "The royal court celebrates with lavish spending — luxury goods are in high demand!"
		"bee_disease":
			return "A mysterious blight affects bee colonies — honey supplies dwindle!"
		"bandit_raid":
			return "Bandits plague the trade routes — crafted goods and jewelry become riskier to transport!"
		"disease_outbreak":
			return "Livestock fall ill to a strange malady — herds thin and prices climb!"
		"blight":
			return "A fungal blight ruins crops — mushrooms and seeds become rare!"
		"smiths_fair":
			return "Blacksmiths gather for a grand competition — demand for ore increases!"
		"scholars_fair":
			return "Scribes and scholars convene — parchment prices rise with academic demand!"
		"war_outbreak":
			return "War drums sound — weapons command premium prices!"
		"wine_shortage":
			return "A poor grape harvest creates a wine shortage — prices ferment to new heights!"
		"winter_festival":
			return "Winter celebrations begin — seasonal foods are in high demand!"
		"bumper_harvest":
			return "An exceptionally bountiful harvest floods the markets — food prices plummet!"
		"trade_surplus":
			return "Trade caravans arrive overflowing with goods — common items become cheap and plentiful!"
		"mineral_discovery":
			return "A massive new vein discovered — precious stones and metals flood the market!"
		"peace_treaty":
			return "A historic peace treaty is signed — demand for weapons collapses!"
		"economic_downturn":
			return "Economic troubles grip the realm — luxury spending drops dramatically!"
		"foreign_competition":
			return "Cheap imports from distant lands undercut local artisans — prices fall!"
		
		_:
			return "A strange occurrence shifts the local economy..."
