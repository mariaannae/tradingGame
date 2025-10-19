extends Control

signal ok_pressed

@onready var message_label: Label = $Panel/VBoxContainer/MessageLabel
@onready var ok_button: Button = $Panel/VBoxContainer/OKButton

func _ready() -> void:
	ok_button.pressed.connect(_on_ok_pressed)
	visible = false

func show_welcome(city_name: String) -> void:
	message_label.text = "You are in %s and ready to do business. Make your trades, and end the turn when you're ready to move on." % city_name
	visible = true

func _on_ok_pressed() -> void:
	visible = false
	emit_signal("ok_pressed")
