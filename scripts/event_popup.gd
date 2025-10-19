extends Control
signal popup_closed

@onready var modal_overlay: ColorRect = $ModalOverlay
@onready var close_button: Button = $UIStack/CloseButton
@onready var title_label: Label = $UIStack/Title
@onready var desc_label: Label = $UIStack/Description

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	hide()  # start hidden
	# Disable input when hidden
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_event(event_data: Dictionary) -> void:
	title_label.text = event_data.get("name", "")
	desc_label.text = event_data.get("description", "")
	# Enable modal behavior - block all input except this popup
	mouse_filter = Control.MOUSE_FILTER_STOP
	modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	show()

func _on_close_button_pressed() -> void:
	# Disable input blocking when hiding
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	emit_signal("popup_closed")
