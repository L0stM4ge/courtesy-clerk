extends Resource
class_name DialogueTree
## DialogueTree - A complete dialogue conversation

@export var dialogue_id: String = ""
@export var lines: Array[DialogueLine] = []
@export var metadata: Dictionary = {}  # Custom data (quest triggers, flags, etc.)


static func create(id: String) -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = id
	return tree


func add_line(line: DialogueLine) -> int:
	lines.append(line)
	return lines.size() - 1


func get_line(index: int) -> DialogueLine:
	if index >= 0 and index < lines.size():
		return lines[index]
	return null
