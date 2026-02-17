extends Control
class_name DialogueBox
## DialogueBox - UI for displaying dialogue

@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var continue_indicator: Label = $Panel/MarginContainer/VBoxContainer/ContinueIndicator

var choice_buttons: Array[Button] = []


func _ready() -> void:
	DialogueManager.register_dialogue_box(self)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_line_displayed.connect(_on_dialogue_line_displayed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	hide()


func _exit_tree() -> void:
	DialogueManager.unregister_dialogue_box()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if choices_container.get_child_count() == 0:
			DialogueManager.advance_dialogue()
			get_viewport().set_input_as_handled()


func _on_dialogue_started(_tree: DialogueTree) -> void:
	show()


func _on_dialogue_line_displayed(line: DialogueLine) -> void:
	speaker_label.text = line.speaker
	text_label.text = line.text

	_clear_choices()

	if line.choices.size() > 0:
		continue_indicator.hide()
		_create_choice_buttons(line.choices)
	else:
		continue_indicator.show()


func _on_dialogue_ended() -> void:
	hide()
	_clear_choices()


func _clear_choices() -> void:
	for button in choice_buttons:
		button.queue_free()
	choice_buttons.clear()


func _create_choice_buttons(choices: Array[Dictionary]) -> void:
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = choice.get("text", "...")
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)
		choice_buttons.append(button)

	# Focus first choice
	if choice_buttons.size() > 0:
		choice_buttons[0].grab_focus()


func _on_choice_selected(choice_index: int) -> void:
	DialogueManager.select_choice(choice_index)
