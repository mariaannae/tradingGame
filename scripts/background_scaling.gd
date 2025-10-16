@tool
extends Sprite2D
@export var mode_cover := true  # true = fill (cover), false = fit (contain)

#makes sure any background map we drop in the art folder with the right name will be scaled appropriately for the game


func _ready() -> void:
	_rescale_and_center()
	if not Engine.is_editor_hint():
		get_viewport().connect("size_changed", Callable(self, "_rescale_and_center"))

func _rescale_and_center() -> void:
	if texture == null: return
	var tex = texture.get_size()
	if tex.x == 0 or tex.y == 0: return

	# In editor, use a default viewport size (Godot's default is 1152x648)
	var vp_size = Vector2(1152, 648) if Engine.is_editor_hint() else get_viewport_rect().size
	
	var sx = vp_size.x / tex.x
	var sy = vp_size.y / tex.y
	var s = max(sx, sy) if mode_cover else min(sx, sy)
	scale = Vector2(s, s)

	# center on the active camera (if any), else viewport center
	# In editor, always center at origin (0, 0)
	if Engine.is_editor_hint():
		global_position = Vector2.ZERO
	else:
		var cam := get_viewport().get_camera_2d()
		var center = cam.global_position if cam else (vp_size * 0.5)
		global_position = center
