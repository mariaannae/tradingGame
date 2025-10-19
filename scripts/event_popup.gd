extends Control
signal popup_closed

@onready var modal_overlay: ColorRect = $ModalOverlay
@onready var close_button: Button = $UIStack/CloseButton
@onready var title_label: Label = $UIStack/Title
@onready var desc_label: Label = $UIStack/Description

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	hide()  # start hidden

func show_event(event_data: Dictionary) -> void:
	title_label.text = event_data.get("name", "")
	desc_label.text = event_data.get("description", "")
	show()
	# Ensure the overlay blocks all input
	modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_close_button_pressed() -> void:
	hide()
	emit_signal("popup_closed")
