extends StaticBody3D
class_name Harmonizer

@onready var glass: MeshInstance3D = $Body/Glass
@export var display_text: String

func _ready() -> void:
	update_text("Wake up, Neo. The Matrix has you...")

func set_scrolling_text(text: String):
	var mat = glass.get_active_material(0) as ShaderMaterial
	
	text = text.to_upper()
	
	# Just add separator with some breathing room
	var padded_text = text + "     - HELIOS -      "
	
	print("Text length: ", padded_text.length())
	
	# Convert string to ASCII codes (max 250 characters to match shader)
	var char_codes = []
	for i in range(250):
		if i < padded_text.length():
			char_codes.append(padded_text.unicode_at(i))
		else:
			char_codes.append(32)
	
	mat.set_shader_parameter("text_chars", char_codes)
	mat.set_shader_parameter("text_length", padded_text.length())

func update_text(new_text: String):
	display_text = new_text
	set_scrolling_text(new_text)
