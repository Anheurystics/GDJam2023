class_name Player extends CharacterBody3D

const SPEED = 7.0
const SPRINT_SPEED = 12.0
const ADS_SPEED = 4.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var health: int = 100; # HP
var memory: int = 100; # Camera
var battery: int = 100; # Flashlight

signal health_changed(value);
signal memory_changed(value);
signal battery_changed(value);

func _process(delta):
	var rotate_dir = Input.get_vector("look_left", "look_right", "look_left", "look_right")
	if rotate_dir.x != 0:
		var rotate_sign = sign(rotate_dir.x)
		rotate_y(-PI * 0.75 * rotate_sign * delta)
	
	if Input.is_action_just_pressed("interact"):
		$Interactor.interact();

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	# if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed_to_use = SPEED;
	if $Snapshot.camera_ads > 0:
		speed_to_use = ADS_SPEED;
	elif Input.is_action_pressed("sprint"):
		speed_to_use = SPRINT_SPEED;

	if direction:
		velocity.x = direction.x * speed_to_use
		velocity.z = direction.z * speed_to_use
	else:
		velocity.x = move_toward(velocity.x, 0, speed_to_use)
		velocity.z = move_toward(velocity.z, 0, speed_to_use)

	move_and_slide()

func modify_health(amount: int):
	health += amount;
	health_changed.emit(health);

func modify_memory(amount: int):
	memory += amount;
	memory_changed.emit(memory);

func modify_battery(amount: int):
	battery += amount;
	battery_changed.emit(battery);
