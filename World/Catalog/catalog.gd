extends Node3D
class_name Catalog

# Storage slots for actual components
var component_slots: Array[RigidBody3D] = []
var slot_positions: Array[Vector3] = []
var is_viewable: bool = false
var current_slot: int = -1

func _ready() -> void:
	# Initialize 10 empty slots
	component_slots.resize(10)
	slot_positions.resize(10)
	
	# Set up positions for each slot (adjust spacing as needed)
	for i in range(10):
		slot_positions[i] = Vector3(i * 0.5, 0, 0)  # Spread them out horizontally
		component_slots[i] = null

func add_component_to_slot(component: RigidBody3D, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= 10:
		push_error("Invalid slot index: ", slot_index)
		return false
	
	if component_slots[slot_index] != null:
		push_error("Slot ", slot_index, " is already occupied!")
		return false
	
	# Store the component
	component_slots[slot_index] = component
	
	# Disable physics while stored
	component.freeze = true
	component.visible = false
	
	update_viewable_status()
	
	return true

func get_component_from_slot(slot_index: int) -> RigidBody3D:
	if slot_index < 0 or slot_index >= 10:
		return null
	return component_slots[slot_index]

func remove_component_from_slot(slot_index: int) -> RigidBody3D:
	if slot_index < 0 or slot_index >= 10:
		return null
	
	var component = component_slots[slot_index]
	if component:
		component_slots[slot_index] = null
		component.freeze = false
		component.visible = true
		print("Component removed from catalog slot ", slot_index + 1)
	
	return component

func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= 10:
		return false
	return component_slots[slot_index] == null

func get_next_empty_slot() -> int:
	for i in range(10):
		if component_slots[i] == null:
			return i
	return -1  # All slots full

func has_components() -> bool:
	for i in range(10):
		if component_slots[i] != null:
			return true
	return false

func get_component_count() -> int:
	var count = 0
	for i in range(10):
		if component_slots[i] != null:
			count += 1
	return count

func update_viewable_status():
	is_viewable = has_components()
