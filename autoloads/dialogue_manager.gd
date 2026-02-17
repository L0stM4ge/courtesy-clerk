extends Node
## DialogueManager - Controls the dialogue system

signal dialogue_started(dialogue_tree: DialogueTree)
signal dialogue_line_displayed(line: DialogueLine)
signal dialogue_choice_selected(choice_index: int)
signal dialogue_ended

var current_tree: DialogueTree = null
var current_line_index: int = 0
var is_active: bool = false

var dialogue_box: Control = null


func start_dialogue(tree: DialogueTree) -> void:
	if is_active:
		return

	current_tree = tree
	current_line_index = 0
	is_active = true

	GameManager.set_state(GameManager.GameState.DIALOGUE)
	dialogue_started.emit(tree)

	_display_current_line()


func advance_dialogue() -> void:
	if not is_active or current_tree == null:
		return

	var current_line := current_tree.lines[current_line_index]

	# Check if this line has choices
	if current_line.choices.size() > 0:
		return  # Wait for choice selection

	# Check for next line
	if current_line.next_line_id >= 0:
		current_line_index = current_line.next_line_id
		_display_current_line()
	else:
		end_dialogue()


func select_choice(choice_index: int) -> void:
	if not is_active or current_tree == null:
		return

	var current_line := current_tree.lines[current_line_index]
	if choice_index >= current_line.choices.size():
		return

	dialogue_choice_selected.emit(choice_index)

	var choice: Dictionary = current_line.choices[choice_index]
	var next_id: int = choice.get("next_line_id", -1)

	if next_id >= 0:
		current_line_index = next_id
		_display_current_line()
	else:
		end_dialogue()


func end_dialogue() -> void:
	is_active = false
	current_tree = null
	current_line_index = 0

	GameManager.set_state(GameManager.GameState.PLAYING)
	dialogue_ended.emit()


func _display_current_line() -> void:
	if current_tree == null or current_line_index >= current_tree.lines.size():
		end_dialogue()
		return

	var line := current_tree.lines[current_line_index]
	dialogue_line_displayed.emit(line)


func register_dialogue_box(box: Control) -> void:
	dialogue_box = box


func unregister_dialogue_box() -> void:
	dialogue_box = null
