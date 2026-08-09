extends Node3D

@export var collision_mask := 1

# ==============================
# PARANOIA SYSTEM
# ==============================

@export var enable_paranoia := true

@export var paranoia_increase_per_switch := 0.02
@export var paranoia_decay_speed := 0.01

@export var paranoia_max := 1.0

var paranoia_level := 0.0


# ==============================
# STATE CONFIG
# ==============================

@export var enable_anomalies := true

@export var chance_shift := 0.18
@export var chance_wrong_position := 0.10
@export var chance_disappear := 0.08
@export var chance_reset := 0.04

# ==============================
# AWARENESS SETTINGS
# ==============================

@export var enable_awareness := true
@export var awareness_turn_speed := 1.5
@export var awareness_trigger_time := 4.0
@export var awareness_rotation_strength := 3.0


# ==============================
# SHIFT SETTINGS
# ==============================

@export var shift_distance := 0.15
@export var shift_vertical := false
@export var max_radius_from_root := 1.0

# ==============================
# WRONG POSITION SETTINGS
# ==============================

@export var wrong_pos_radius := 0.6
@export var wrong_rot_range := 35.0

# ==============================
# DISAPPEAR SETTINGS
# ==============================

@export var disappear_duration := 1.5

# ==============================
# COLLISION SETTINGS
# ==============================

@export var collision_radius := 0.25
@export var position_attempts := 6

# ==============================
# INTERNAL
# ==============================

var watch_timer := 0.0
var watching_camera : Camera3D = null

var root_position : Vector3
var root_rotation : Vector3

var current_state := "normal"
var hidden := false


func _ready():

	randomize()

	root_position = global_position
	root_rotation = rotation


# ==============================
# CAMERA SWITCH TRIGGER
# ==============================

func on_camera_switch():
	if enable_paranoia:
		paranoia_level += paranoia_increase_per_switch
		paranoia_level = clamp(paranoia_level, 0.0, paranoia_max)

	if not enable_anomalies:
		return


	var roll = randf() * (1.0 - paranoia_level * 0.6)


	if roll < chance_shift:
		_shift()

	elif roll < chance_shift + chance_wrong_position:
		_wrong_position()

	elif roll < chance_shift + chance_wrong_position + chance_disappear:
		_disappear()

	elif roll < chance_shift + chance_wrong_position + chance_disappear + chance_reset:
		_reset()



# ==============================
# EVENTS
# ==============================

func _shift():

	current_state = "shift"

	for i in range(position_attempts):

		var offset = Vector3(
			randf_range(-shift_distance, shift_distance),
			0,
			randf_range(-shift_distance, shift_distance)
		)

		if shift_vertical:
			offset.y = randf_range(-shift_distance, shift_distance)

		var candidate = global_position + offset

		if candidate.distance_to(root_position) > max_radius_from_root:
			continue

		if position_is_valid(candidate):

			global_position = candidate
			return



func _wrong_position():

	current_state = "wrong"

	for i in range(position_attempts):

		var offset = Vector3(
			randf_range(-wrong_pos_radius, wrong_pos_radius),
			0,
			randf_range(-wrong_pos_radius, wrong_pos_radius)
		)

		var candidate = root_position + offset

		if position_is_valid(candidate):

			global_position = candidate

			var rot = deg_to_rad(randf_range(-wrong_rot_range, wrong_rot_range))
			rotation.y += rot

			return

func update_awareness(delta):

	if not enable_awareness:
		return

	var viewport = get_viewport()

	var cam = viewport.get_camera_3d()

	if cam == null:
		return

	var visible = cam.is_position_in_frustum(global_position)

	if visible:

		watch_timer += delta
		watching_camera = cam

		if watch_timer > awareness_trigger_time:

			_rotate_toward_camera(cam)
			watch_timer = 0



func _disappear():

	if hidden:
		return

	current_state = "vanish"
	hidden = true

	visible = false

	await get_tree().create_timer(disappear_duration).timeout

	visible = true
	hidden = false



func _reset():

	current_state = "reset"

	global_position = root_position
	rotation = root_rotation



# ==============================
# COLLISION VALIDATION
# ==============================

func position_is_valid(test_pos: Vector3) -> bool:

	var space = get_world_3d().direct_space_state

	var shape = SphereShape3D.new()
	shape.radius = collision_radius

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), test_pos)
	query.collision_mask = collision_mask
	query.exclude = [self]

	var result = space.intersect_shape(query)

	if result.size() > 0:
		return false

	# also verify there is floor under the chair
	var ray = PhysicsRayQueryParameters3D.create(
		test_pos + Vector3.UP * 0.3,
		test_pos + Vector3.DOWN * 0.8
	)

	ray.collision_mask = collision_mask
	ray.exclude = [self]

	var floor = space.intersect_ray(ray)

	if floor.is_empty():
		return false

	return true

func _rotate_toward_camera(cam):

	var dir = cam.global_position - global_position
	dir.y = 0

	if dir.length() == 0:
		return

	dir = dir.normalized()

	var target_angle = atan2(dir.x, dir.z)

	var rot = lerp_angle(rotation.y, target_angle, deg_to_rad(awareness_rotation_strength))

	rotation.y = rot

func _process(delta):
	if enable_paranoia:
		paranoia_level -= paranoia_decay_speed * delta
		paranoia_level = clamp(paranoia_level, 0.0, paranoia_max)
		
	update_awareness(delta)
