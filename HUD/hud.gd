extends Control
class_name HUD

@onready var hud_reticle: Control = $CanvasLayer/Reticle
@onready var control_object: Control = $CanvasLayer/Control_Object

func _ready() -> void:
	control_object.visible = false
