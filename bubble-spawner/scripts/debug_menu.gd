class_name DebugMenu
extends MenuButton

signal toggle_changed(toggle_name: String, value: bool)

# Map popup item ID → stable string key
const TOGGLES := {
	0: "all_colors",
	1: "pop_intro",
	2: "pop_intro_delay",
	3: "count_pop",
	4: "player_stretch",
	5: "ball_stretch",
	6: "proj_wobble",
	7: "proj_trail",
	8: "hit_particles",
	9: "ui_count",
	10: "sfx_on",
	11: "bgm_on",
	12: "camera_shake_on",
	13: "voice_over"
}

var toggles_value := {
	
}

func _ready() -> void:
	text = "Debug"

	var popup := get_popup()
	popup.clear()

	# Add each toggle as a checkable item
	for id in TOGGLES.keys():
		var label := _key_to_label(TOGGLES[id])
		popup.add_check_item(label, id)
		toggles_value[TOGGLES[id]] = false

	# Emit when the user clicks an item
	popup.id_pressed.connect(_on_item_pressed)

func _key_to_label(key: String) -> String:
	# "player_color" → "Player Color"
	return key.capitalize().replace("_", " ")

func _on_item_pressed(id: int) -> void:
	if not TOGGLES.has(id):
		return
	var popup := get_popup()
	# Flip the checkmark
	var idx := popup.get_item_index(id)
	var new_state := not popup.is_item_checked(idx)
	popup.set_item_checked(idx, new_state)
	# Broadcast the change
	toggles_value[TOGGLES[id]] = new_state
	toggle_changed.emit(TOGGLES[id], new_state)
