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
		_:
			return "A strange occurrence shifts the local economy..."
