extends TextureRect

# Automatically positions this parchment background relative to a target node
@export var target_node_path: NodePath
@export var margin_left: float = 15.0
@export var margin_top: float = 15.0
@export var margin_right: float = 10.0
@export var margin_bottom: float = 10.0

var target_node: Control = null

func _ready() -> void:
	if target_node_path:
		target_node = get_node(target_node_path)
	
	if target_node:
		# Wait for target to be ready and sized
		await get_tree().process_frame
		_update_position()
		
		# Update when target resizes
		target_node.resized.connect(_update_position)
	else:
		push_error("ParchmentPositioner: Target node not found at path: %s" % target_node_path)

func _update_position() -> void:
	if not target_node:
		return
	
	# For anchored nodes, we need to work with their offset values
	# The target is anchored to bottom-right, so its offset_left is negative
	var target_left = target_node.offset_left
	var target_top = target_node.offset_top
	var target_right = target_node.offset_right
	var target_bottom = target_node.offset_bottom
	
	# Position parchment to frame the target with margins
	# Extend further left and up, keeping right and bottom edges aligned
	offset_left = target_left - margin_left
	offset_top = target_top - margin_top
	offset_right = target_right + margin_right
	offset_bottom = target_bottom + margin_bottom
	
	print("Parchment positioning: target offsets=(%s,%s,%s,%s), result=(%s,%s,%s,%s)" % [
		target_left, target_top, target_right, target_bottom,
		offset_left, offset_top, offset_right, offset_bottom
	])
