extends CanvasLayer

signal dialogue_finished(dialogue_id: String)

@onready var panel: Control = $Panel
@onready var name_label: Label = $Panel/VBoxContainer/NameLabel
@onready var dialogue_label: Label = $Panel/VBoxContainer/DialogueLabel

var dialogues: Dictionary = {}
var current_id: String = ""
var current_lines: Array = []
var line_index: int = 0


func _ready() -> void:
	panel.hide()
	load_dialogues()


func load_dialogues() -> void:
	var path := "res://dialogos/dialogos.json"

	if not FileAccess.file_exists(path):
		push_error("No se encontró el archivo: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("No se pudo abrir dialogos.json")
		return

	var data = JSON.parse_string(file.get_as_text())

	if data is Dictionary:
		dialogues = data
	else:
		push_error("El contenido de dialogos.json no es válido.")


func start_dialogue(dialogue_id: String) -> void:
	if not dialogues.has(dialogue_id):
		push_warning("Diálogo no encontrado: " + dialogue_id)
		return

	if not dialogues[dialogue_id] is Array:
		push_error("El diálogo no contiene una lista válida: " + dialogue_id)
		return

	current_id = dialogue_id
	current_lines = dialogues[dialogue_id]
	line_index = 0

	if current_lines.is_empty():
		push_warning("El diálogo está vacío: " + dialogue_id)
		return

	panel.show()
	show_line()


func show_line() -> void:
	if line_index < 0 or line_index >= current_lines.size():
		return

	var line = current_lines[line_index]

	if not line is Dictionary:
		push_error("Una línea del diálogo no tiene el formato correcto.")
		return

	name_label.text = str(line.get("personaje", ""))
	dialogue_label.text = str(line.get("texto", ""))


func advance_dialogue() -> void:
	if not panel.visible:
		return

	line_index += 1

	if line_index >= current_lines.size():
		panel.hide()

		var finished_id := current_id
		current_id = ""
		current_lines.clear()
		line_index = 0

		dialogue_finished.emit(finished_id)
	else:
		show_line()


func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance_dialogue()


func close_dialogue() -> void:
	if not panel.visible:
		return

	var finished_id := current_id

	panel.hide()
	current_id = ""
	current_lines.clear()
	line_index = 0

	dialogue_finished.emit(finished_id)
