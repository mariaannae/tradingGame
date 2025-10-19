extends Control

var resource_name: String = ""
var tooltip_label: Label = null

func _ready() -> void:
	# Create tooltip label
	tooltip_label = Label.new()
	tooltip_label.visible = false
	tooltip_label.z_index = 100
	tooltip_label.add_theme_color_override("font_color", Color.BLACK)
	tooltip_label.add_theme_color_override("font_shadow_color", Color.WHITE)
	tooltip_label.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(tooltip_label)
	
	# Set up mouse detection for the Icon
	var icon_node = find_child("Icon")
	if icon_node:
		icon_node.mouse_filter = Control.MOUSE_FILTER_STOP
		icon_node.mouse_entered.connect(_on_mouse_entered)
		icon_node.mouse_exited.connect(_on_mouse_exited)

func set_resource_name(name: String) -> void:
	resource_name = name
	if tooltip_label:
		tooltip_label.text = resource_name

func _on_mouse_entered() -> void:
	if tooltip_label and resource_name != "":
		tooltip_label.visible = true
		tooltip_label.position = Vector2(0, -25)

func _on_mouse_exited() -> void:
	if tooltip_label:
		tooltip_label.visible = false
