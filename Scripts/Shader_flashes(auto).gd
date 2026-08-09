extends ColorRect

var glitch_min_time := 5.0
var glitch_max_time := 15.0

func _ready():
	randomize()

	# Fill screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Let mouse pass through
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_start_glitch_timer()


func _start_glitch_timer():
	var delay := randf_range(glitch_min_time, glitch_max_time)
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_fire_flashbang)


func _fire_flashbang():

	var mat := material as ShaderMaterial
	if mat == null:
		push_warning("ColorRect missing ShaderMaterial")
		return

	var tween := create_tween()

	# instant flash
	mat.set_shader_parameter("sequence_progress", 0.5)

	# run full glitch sequence
	tween.tween_property(
		mat,
		"shader_parameter/sequence_progress",
		10.0,
		3.5
	)

	tween.finished.connect(func():
		mat.set_shader_parameter("sequence_progress", 0.0)
		_start_glitch_timer()
	)
