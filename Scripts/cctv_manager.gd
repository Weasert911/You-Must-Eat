extends Node3D

@export var cameras: Array[Camera3D]
@export var glitch_material: ShaderMaterial

# anomaly objects (chair, plates, etc)
@export var anomaly_objects: Array[Node3D]

@export var enable_drift := true
@export var enable_wrong_frame := true
@export var enable_random_noise := true

var current_cam := 0
var switching := false

var mouse_sensitivity := 0.002
var max_rotation := 0.25

var rot_x := 0.0
var rot_y := 0.0

var base_rotations: Array[Vector3] = []

var last_mouse_time := 0.0
var drift_target := Vector2.ZERO


func _ready():

	for cam in cameras:
		base_rotations.append(cam.rotation)

	_activate_camera(0)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	last_mouse_time = Time.get_ticks_msec() / 1000.0

	randomize()
	_start_random_events()



func _input(event):

	if event is InputEventMouseMotion:

		last_mouse_time = Time.get_ticks_msec() / 1000.0

		rot_y -= event.relative.x * mouse_sensitivity
		rot_x -= event.relative.y * mouse_sensitivity

		rot_x = clamp(rot_x, -max_rotation, max_rotation)
		rot_y = clamp(rot_y, -max_rotation, max_rotation)

		var cam := cameras[current_cam]
		var base := base_rotations[current_cam]

		cam.rotation = cam.rotation.lerp(base + Vector3(rot_x, rot_y, 0), 0.15)


	if event.is_action_pressed("Next_Cam"):
		next_camera()

	if event.is_action_pressed("Prev_Cam"):
		prev_camera()



func _process(delta):

	# idle paranoia drift
	if enable_drift:

		var now = Time.get_ticks_msec() / 1000.0

		if now - last_mouse_time > 4.0:

			drift_target.x += randf_range(-0.0002,0.0002)
			drift_target.y += randf_range(-0.0002,0.0002)

			rot_x += drift_target.x
			rot_y += drift_target.y

			rot_x = clamp(rot_x, -max_rotation, max_rotation)
			rot_y = clamp(rot_y, -max_rotation, max_rotation)

			var cam := cameras[current_cam]
			var base := base_rotations[current_cam]

			cam.rotation = cam.rotation.lerp(base + Vector3(rot_x, rot_y, 0), 0.05)



func next_camera():

	if switching:
		return

	current_cam += 1

	if current_cam >= cameras.size():
		current_cam = 0

	await _switch_camera(current_cam)



func prev_camera():

	if switching:
		return

	current_cam -= 1

	if current_cam < 0:
		current_cam = cameras.size() - 1

	await _switch_camera(current_cam)



func _activate_camera(index):

	for cam in cameras:
		cam.current = false

	cameras[index].current = true

	rot_x = 0
	rot_y = 0



func play_glitch_transition():

	if glitch_material == null:
		return

	var tween = create_tween()

	glitch_material.set_shader_parameter("sequence_progress", 0.5)

	tween.tween_property(
		glitch_material,
		"shader_parameter/sequence_progress",
		10.0,
		0.6
	)

	tween.finished.connect(func():
		glitch_material.set_shader_parameter("sequence_progress", 0.0)
	)



func _start_random_events():

	while true:

		await get_tree().create_timer(randf_range(20,60)).timeout

		if enable_random_noise:
			_random_camera_noise()



func _switch_camera(index):

	switching = true

	play_glitch_transition()


	# wrong frame glitch
	if enable_wrong_frame and randf() < 0.35:

		var fake = randi() % cameras.size()

		for cam in cameras:
			cam.current = false

		cameras[fake].current = true

		await get_tree().create_timer(0.04).timeout


	await get_tree().create_timer(0.15).timeout


	_activate_camera(index)


	# trigger anomalies
	for obj in anomaly_objects:
		if obj and obj.has_method("on_camera_switch"):
			obj.on_camera_switch()


	switching = false



func _random_camera_noise():

	var cam := cameras[current_cam]
	var base := base_rotations[current_cam]

	var twitch = Vector3(
		randf_range(-0.01,0.01),
		randf_range(-0.01,0.01),
		0
	)

	cam.rotation = base + twitch
