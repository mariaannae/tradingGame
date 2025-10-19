extends Control
signal popup_closed

@onready var close_button: Button = $UIStack/CloseButton
@onready var title_label: Label = $UIStack/Title
@onready var desc_label: Label = $UIStack/Description

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	visible = false  # start hidden

func show_event(event_data: Dictionary) -> void:
	title_label.text = event_data.get("name", "")
	desc_label.text = event_data.get("description", "")
	visible = true

func _on_close_button_pressed() -> void:
	visible = false
	emit_signal("popup_closed")
