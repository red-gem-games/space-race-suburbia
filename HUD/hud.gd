extends Control
class_name _HUD_

@onready var reticle: Control = $CanvasLayer/Reticle

var extraction_started: bool = false
var extraction_complete: bool = false
var component_color: Color
var catalog_extraction_phase: String = "idle"
var extract_time_remaining: float
var extraction_total_time: float = 0.0

@onready var Cat_1: Control = $"Catalog/1"
@onready var Cat_2: Control = $"Catalog/2"
@onready var Cat_3: Control = $"Catalog/3"
@onready var Cat_4: Control = $"Catalog/4"
@onready var Cat_5: Control = $"Catalog/5"
@onready var Cat_6: Control = $"Catalog/6"
@onready var Cat_7: Control = $"Catalog/7"
@onready var Cat_8: Control = $"Catalog/8"
@onready var Cat_9: Control = $"Catalog/9"
@onready var Cat_10: Control = $"Catalog/10"

var catalog_slots_filled: Array[bool] = [false, false, false, false, false, false, false, false, false, false]
var current_extraction_slot: int = -1

var catalog_tweens: Array[Tween] = []

func _ready() -> void:
	catalog_tweens.resize(10)
	for i in range(10):
		catalog_tweens[i] = null
	reset_all_catalog_slots()
	
	await get_tree().create_timer(1.0).timeout
	print("--------")
	print("Upon completing a component extraction, the following can/will occur:")
	await get_tree().create_timer(0.05).timeout
	print("1. Player may scroll or press designated # keys to pull up extracted component within the PREM-7's hologram functionality")
	await get_tree().create_timer(0.05).timeout
	print("2. Player may RESEARCH component by pressing 'R' key, pulling up a blue version of the EXTRACT dashboard on the PREM-7")
	await get_tree().create_timer(0.05).timeout
	print("3. RESEARCH screen is minimized when player presses ANY button (keys, mouse scroll, mouse clicks)")
	await get_tree().create_timer(0.05).timeout
	print("4. If player has an extracted component pulled up in the hologram and clicks any object (grabbable, system, staircase, etc.), the hologram is minimized")
	await get_tree().create_timer(0.05).timeout
	print("5. If player selects a system, they then have two options: EXTRACT or FUSE -- There will also be a screen showing the overall Rating, Mass, Mayhem, and Force")
	await get_tree().create_timer(0.05).timeout
	print("6. If player decides to EXTRACT a broken part, they will press 'E' to enter EXTRACT mode")
	await get_tree().create_timer(0.05).timeout
	print("6a. System EXTRACT mode is very similar in that the available components for extraction (if they exist at that time and are filled) can be scrolled through and extracted the same way a component is within a grabbed object")
	await get_tree().create_timer(0.05).timeout
	print("7. If player decides to FUSE in that System, they will press 'F' to enter FUSE mode")
	await get_tree().create_timer(0.05).timeout
	print("7a. At this time, they can then choose an empty Subsystem to fuse a component to, and press 'Q'")
	await get_tree().create_timer(0.05).timeout
	print("7b. The first catalog item will appear in hologram form above the PREM-7 and in the subsystem position")
	await get_tree().create_timer(0.05).timeout
	print("7c. If the component fits, it will appear in green and the player can then press and hold 'Q' to fuse that component to the subsystem position")
	await get_tree().create_timer(0.05).timeout
	print("7c. If the component does not fit, it will appear in red and when the player presses 'Q', the hologram will shake left and right and an error tone will play")

func _process(delta: float) -> void:
	if catalog_extraction_phase == "extracting" and extraction_total_time > 0:
		var progress = 1.0 - (extract_time_remaining / extraction_total_time)
		progress = clamp(progress, 0.0, 1.0)
		
		var tween_speed_multiplier = 2.0 / extraction_total_time
		var dynamic_duration = delta * 7.25 / tween_speed_multiplier
		
		shift_catalog_color_by_index(
			current_extraction_slot, 
			component_color.r, 
			component_color.g, 
			component_color.b, 
			2.0, 
			dynamic_duration
		)
	
	elif catalog_extraction_phase == "completing":
		shift_catalog_color_by_index(
			current_extraction_slot, 
			component_color.r, 
			component_color.g, 
			component_color.b, 
			0.625, 
			delta * 2.5
		)

func start_extraction(total_time: float):
	current_extraction_slot = get_next_empty_slot()
	
	if current_extraction_slot == -1:
		print("ERROR: All catalog slots are filled!")
		return
	
	extraction_started = true
	extraction_complete = false
	catalog_extraction_phase = "extracting"
	extraction_total_time = total_time
	extract_time_remaining = total_time
	
	var cat_node = get_catalog_node(current_extraction_slot)
	cat_node.modulate = Color(2.5, 2.5, 2.5, 0.3)

func complete_extraction():
	if catalog_extraction_phase == "completing":
		return
	
	extraction_complete = true
	extraction_started = false
	catalog_extraction_phase = "completing"
	
	print("CATALOG SLOT ", current_extraction_slot + 1, " FILLED")
	catalog_slots_filled[current_extraction_slot] = true
	
	await get_tree().create_timer(0.25).timeout
	
	extraction_complete = false
	catalog_extraction_phase = "filled"
	current_extraction_slot = -1

func cancel_extraction():
	if current_extraction_slot != -1:
		extraction_started = false
		extraction_complete = false
		catalog_extraction_phase = "idle"
		
		shift_catalog_color_by_index(current_extraction_slot, 1.0, 1.0, 1.0, 0.3, 0.4)
		current_extraction_slot = -1

func shift_catalog_color_by_index(catalog_index: int, r: float, g: float, b: float, a: float, duration: float):
	var catalog_node = get_catalog_node(catalog_index)
	shift_catalog_color(catalog_node, r, g, b, a, duration, catalog_index)

func shift_catalog_color(catalog_node: Control, r: float, g: float, b: float, a: float, duration: float, catalog_index: int):
	if catalog_tweens[catalog_index] != null:
		catalog_tweens[catalog_index].kill()
	
	catalog_tweens[catalog_index] = create_tween()
	catalog_tweens[catalog_index].set_ease(Tween.EASE_IN_OUT)
	catalog_tweens[catalog_index].set_trans(Tween.TRANS_CUBIC)
	catalog_tweens[catalog_index].set_parallel(true)
	
	catalog_tweens[catalog_index].tween_property(catalog_node, "modulate:r", r, duration)
	catalog_tweens[catalog_index].tween_property(catalog_node, "modulate:g", g, duration)
	catalog_tweens[catalog_index].tween_property(catalog_node, "modulate:b", b, duration)
	catalog_tweens[catalog_index].tween_property(catalog_node, "modulate:a", a, duration)
	
	catalog_tweens[catalog_index].finished.connect(func():
		catalog_node.modulate.r = r
		catalog_node.modulate.g = g
		catalog_node.modulate.b = b
		catalog_node.modulate.a = a
	)

func shift_cat_1_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_1, r, g, b, a, duration, 0)

func shift_cat_2_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_2, r, g, b, a, duration, 1)

func shift_cat_3_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_3, r, g, b, a, duration, 2)

func shift_cat_4_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_4, r, g, b, a, duration, 3)

func shift_cat_5_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_5, r, g, b, a, duration, 4)

func shift_cat_6_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_6, r, g, b, a, duration, 5)

func shift_cat_7_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_7, r, g, b, a, duration, 6)

func shift_cat_8_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_8, r, g, b, a, duration, 7)

func shift_cat_9_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_9, r, g, b, a, duration, 8)

func shift_cat_10_color(r: float, g: float, b: float, a: float, duration: float):
	shift_catalog_color(Cat_10, r, g, b, a, duration, 9)

func reset_all_catalog_slots():
	for i in range(10):
		var cat_node = get_catalog_node(i)
		cat_node.modulate = Color(1.0, 1.0, 1.0, 0.3)

func get_catalog_node(index: int) -> Control:
	match index:
		0: return Cat_1
		1: return Cat_2
		2: return Cat_3
		3: return Cat_4
		4: return Cat_5
		5: return Cat_6
		6: return Cat_7
		7: return Cat_8
		8: return Cat_9
		9: return Cat_10
		_: return Cat_1  # Fallback

func get_next_empty_slot() -> int:
	for i in range(10):
		if not catalog_slots_filled[i]:
			return i
	return -1  # All slots filled
