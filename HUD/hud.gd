extends Control
class_name _HUD_

@onready var reticle: Control = $CanvasLayer/Reticle

@onready var message: Control = $CanvasLayer/Message

func _ready() -> void:
	message_status('Extract', 'OFF')
	
func message_status(type, status):
	if type == 'Extract':
		for child in message.get_children():
			if status == 'ON':
				child.visible = true
			if status == 'OFF':
				child.visible = false
