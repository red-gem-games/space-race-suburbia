extends Control
class_name HUD

@onready var reticle: Control = $CanvasLayer/Reticle
@onready var control_color: ColorRect = $CanvasLayer/Control_Color
@onready var control_shader_mat: ShaderMaterial

@onready var message: Control = $CanvasLayer/Message

func _ready() -> void:
	control_color.visible = false
	control_shader_mat = control_color.material as ShaderMaterial
	message_status('Extract', 'OFF')
	
func set_highlight_color(col: Color, alpha: float = 1.0) -> void:
	if control_shader_mat:
		# overwrite the color’s alpha
		col.a = alpha
		control_shader_mat.set_shader_parameter("highlight_color", col)
	else:
		push_error("No ShaderMaterial on Control_Color!")

func message_status(type, status):
	if type == 'Extract':
		for child in message.get_children():
			if status == 'ON':
				child.visible = true
			if status == 'OFF':
				child.visible = false
