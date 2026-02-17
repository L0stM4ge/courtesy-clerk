extends Resource
class_name DialogueLine
## DialogueLine - A single line of dialogue

@export var speaker: String = ""
@export var text: String = ""
@export var portrait: Texture2D = null
@export var choices: Array[Dictionary] = []  # [{text: String, next_line_id: int}]
@export var next_line_id: int = -1  # -1 means end dialogue
@export var animation: String = ""  # Optional animation to play


static func create(speaker_name: String, dialogue_text: String, next_id: int = -1) -> DialogueLine:
	var line := DialogueLine.new()
	line.speaker = speaker_name
	line.text = dialogue_text
	line.next_line_id = next_id
	return line


func add_choice(choice_text: String, next_id: int) -> void:
	choices.append({"text": choice_text, "next_line_id": next_id})
