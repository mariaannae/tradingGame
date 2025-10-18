extends Control

signal popup_closed

@export var title_label: Label
@export var desc_label: Label
@export var close_button: Button

func show_event(event_data: Dictionary):
	print("show_event called with:", event_data)  # Debug line
	title_label.text = event_data.get("name", "Unknown Event")
	desc_label.text = event_data.get("description", "No description available.")
	visible = true
	z_index = 100  # Make sure it renders above other UI

func _on_CloseButton_pressed() -> void:
	visible = false
	emit_signal("popup_closed")

func _on_close_button_pressed() -> void:
	pass # Replace with function body.
