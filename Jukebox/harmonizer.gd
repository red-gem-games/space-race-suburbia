extends StaticBody3D

@onready var glass: MeshInstance3D = $Glass
@export var display_text: String = "HARMONIZER"

func _ready() -> void:
	update_text("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

func set_scrolling_text(text: String):
	var mat = glass.get_active_material(0) as ShaderMaterial
	
	# Convert string to ASCII codes (max 30 characters)
	var char_codes = []
	for i in range(30):
		if i < text.length():
			char_codes.append(text.unicode_at(i))
		else:
			char_codes.append(32)  # Pad with spaces
	
	mat.set_shader_parameter("text_chars", char_codes)
	mat.set_shader_parameter("text_length", min(text.length(), 30))

# Change text anytime!
func update_text(new_text: String):
	display_text = new_text
	set_scrolling_text(new_text)
