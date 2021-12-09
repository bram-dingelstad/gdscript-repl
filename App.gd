extends Control

var _script = GDScript.new()
var history = []
var history_index = 0
var assignment_check = RegEx.new()


onready var input = $LineEdit
onready var output = $RichTextLabel

var random_expressions = [
	'Vector2.ONE + Vector2.RIGHT',
	'OS.shell_open(\'https://twitter.com/bram_dingelstad\')',
	'\"You\'re dead" if randi() % 6 == 0 else "*click*"',
	'(color=#%s)Random color(/color)" % Color.from_hsv(randf(), 1, 1).to_html() (but use brackets for the bbcode part)',
	'TAU / PI == 2',
	'1.0 + 2.0',
	'Node.new()',
	'get_node(\'../RichTextLabel\').bbcode_text = \'HACKED\\n\'',
	'get_tree().reload_current_scene()',
	'get_parent().add_node(Button.new())',
	'reset',
	'clear',
	'get_node(\'../LineEdit\').text = \'one step ahead of ya (press key up)\'',
]

const SHARE_URL = 'https://twitter.com/intent/tweet?text=Check%20out%20this%20cool%20%23GDscript%20terminal%20by%20%40bram_dingelstad%0Ahttps%3A%2F%2Fgdscript.bram.dingelstad.works%0A%23GodotEngine%20%23gamedev'

func _ready():
	input.grab_focus()
	$Evaluate.connect('pressed', self, '_on_eval')

	randomize()
	$RichTextLabel.bbcode_text = $RichTextLabel.bbcode_text % [SHARE_URL, random_expressions[randi() % random_expressions.size()]]
	$RichTextLabel.connect('meta_clicked', self, '_on_url_clicked')
	assignment_check.compile('\\s=\\s|\\s=\\S|\\S=\\s')

func _on_url_clicked(url):
	OS.shell_open(url)

# TODO: Implement a variable storage and function declaration
func evaluate(expression):
	_script.set_source_code('')
	_script.reload(true)
	
	var statement = ''
	if assignment_check.search(expression):
		statement = expression
		expression = 'true'

	if expression.strip_edges() in ['clear', 'clear()']:
		$RichTextLabel.bbcode_text = 'Cleared\n'
		return

	if expression.strip_edges() in ['reset', 'reset()']:
		get_tree().reload_current_scene()
		return

	_script.set_source_code('extends Node\n\nfunc eval():\n\trandomize()\n\t%s\n\treturn %s' % [statement, expression])
	var error = _script.reload(true)

	if error == OK:
		$Node.set_script(_script)

		return $Node.eval()
	else:
		return 'Error'

func _on_eval():
	output.bbcode_text += '> %s\n' % input.text

	var result = evaluate(input.text)
	if not result:
		output.bbcode_text += 'null\n'
	else:
		output.bbcode_text +=  "%s\n" % str(result)

	history.append(input.text)
	history_index = 0
	input.text = ''

	input.grab_focus()

func _on_input_text_entered(_new_text):
	_on_eval()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.scancode:
			KEY_ENTER:
				_on_eval()
			KEY_UP:
				history_index += 1
				if history.size() >= history_index and history[-history_index]:
					input.text = history[-history_index]
				else:
					history_index -= 1

				input.grab_focus()
				input.caret_position = input.text.length()
				get_tree().set_input_as_handled()

			KEY_DOWN:
				history_index -= 1
				if history_index > 0 and history[-history_index]:
					input.text = history[-history_index]
				elif history_index == 0:
					input.text = ''
				else:
					history_index += 1

				get_tree().set_input_as_handled()
