extends CharacterBody2D
class_name NPCBase
## NPCBase - Base class for all NPCs

signal dialogue_requested(dialogue_tree: DialogueTree)

@export var npc_name: String = "NPC"
@export var dialogue_resource: DialogueTree = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")


func interact(_player: Node2D) -> void:
	if dialogue_resource != null:
		DialogueManager.start_dialogue(dialogue_resource)
		dialogue_requested.emit(dialogue_resource)
	else:
		# Default dialogue if none set
		var default_tree := _create_default_dialogue()
		DialogueManager.start_dialogue(default_tree)


func _create_default_dialogue() -> DialogueTree:
	var tree := DialogueTree.create("default_%s" % npc_name)

	var line := DialogueLine.create(npc_name, "...")
	tree.add_line(line)

	return tree


func set_dialogue(tree: DialogueTree) -> void:
	dialogue_resource = tree
