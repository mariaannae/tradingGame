extends TextureRect

# References the UIStack to track its size
@onready var ui_stack: VBoxContainer = get_parent().get_node("UIStack")

# Padding around the UIStack (in pixels)
@export var padding: float = 20.0

# Additional horizontal padding (adds to the sides)
@export var horizontal_padding: float = 40.0

# Scale factor for the parchment size (1.0 = same size as content + padding)
@export var scale_factor: float = 1.3

# Additional offset to shift the parchment position (negative moves left/up)
@export var position_offset: Vector2 = Vector2(-25, -25)

func _ready() -> void:
	# Initial update
	_update_size_and_position()
	
	# Connect to the ui_stack's size changes if possible
	if ui_stack:
		ui_stack.resized.connect(_update_size_and_position)

func _process(_delta: float) -> void:
	# Continuously update to handle dynamic content changes
	_update_size_and_position()

func _update_size_and_position() -> void:
	if not ui_stack:
		return
	
	# Get the UIStack's size
	var stack_size = ui_stack.size
	
	# Calculate base parchment size (UIStack size + padding on all sides)
	# Add extra horizontal padding
	var base_size = stack_size + Vector2((padding + horizontal_padding) * 2, padding * 2)
	
	# Apply scale factor to make it larger
	size = base_size * scale_factor
	
	# Calculate the extra size due to scaling
	var size_diff = size - base_size
	
	# Position the parchment:
	# Start at UIStack position, subtract padding (including horizontal) to center it,
	# then subtract half the size difference to keep it centered when scaled,
	# then apply the position offset
	position = ui_stack.position - Vector2(padding + horizontal_padding, padding) - (size_diff * 0.5) + position_offset
