class_name Player extends CharacterBody3D

const SPEED = 4.0
const SPRINT_SPEED = 8.0
const ADS_SPEED = 4.0
const JUMP_VELOCITY = 4.5
const FLASHLIGHT_DRAIN_RATE = 5;
const FLASHLIGHT_REGEN_RATE = 1;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var health: float = 100; # HP
var battery: float = 100; # Flashlight
var memory: int = 5; # Camera

@onready var flashlight: SpotLight3D = $Flashlight;
@onready var interactor: Interactor = $Interactor;
@onready var snapshot: Snapshot = $Snapshot;

signal health_changed(old: float, new: float);
signal battery_changed(old: float, new: float);
signal memory_changed(old: int, new: int);

var owned_keys: PackedStringArray = [];

func _ready():
	# Call these to initialize HUD values
	modify_health(0);
	modify_battery(0);
	modify_memory(0);

func _process(delta):
	if health <= 0:
		return;

	var rotate_dir = Input.get_vector("look_left", "look_right", "look_left", "look_right")
	if rotate_dir.x != 0:
		var rotate_sign = sign(rotate_dir.x)
		rotate_y(-PI * 0.75 * rotate_sign * delta)
	
	if Input.is_action_just_pressed("interact"):
		interactor.interact();
		
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible;
	
	if battery == 0:
		flashlight.visible = false;
	
	if flashlight.visible:
		modify_battery(-FLASHLIGHT_DRAIN_RATE * delta);
		if battery <= 0:
			flashlight.visible = false;
	else:
		modify_battery(FLASHLIGHT_REGEN_RATE * delta);
	
	if Input.is_action_just_pressed("take_picture") and memory > 0:
		snapshot.take_picture();
		modify_memory(-1);

func _physics_process(delta):
	if health <= 0:
		return;
	
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
	if snapshot.camera_ads > 0:
		speed_to_use = ADS_SPEED;
	elif Input.is_action_pressed("sprint") and direction.dot(global_transform.basis.z) <= 0:
		speed_to_use = SPRINT_SPEED;

	if direction:
		velocity.x = direction.x * speed_to_use
		velocity.z = direction.z * speed_to_use
	else:
		velocity.x = move_toward(velocity.x, 0, speed_to_use)
		velocity.z = move_toward(velocity.z, 0, speed_to_use)

	move_and_slide()

func modify_health(amount: float):
	var old = health;
	health = clamp(health + amount, 0, 100);
	health_changed.emit(old, health);
	
	if health <= 0:
		var tween = get_tree().create_tween();
		tween.set_parallel(true);
		tween.tween_property($Camera3D, "position:y", 0, 0.8);
		tween.tween_property($Camera3D, "rotation:y", PI/2, 0.8);

func modify_battery(amount: float):
	var old = battery
	battery = clamp(battery + amount, 0, 100);
	battery_changed.emit(old, battery);

func modify_memory(amount: int):
	var old = memory;
	memory = clamp(memory + amount, 0, 100);
	memory_changed.emit(old, memory);

func serialize():
	return {
		"global_position": global_position,
		"global_rotation": global_rotation,
		"health": health,
		"battery": battery,
		"memory": memory,
		"flashlight_visible": flashlight.visible
	}
	
func deserialize(data):
	global_position = data.global_position;
	global_rotation = data.global_rotation;
	health = data.health;
	modify_health(0);
	battery = data.battery;
	modify_battery(0);
	memory = data.memory;
	modify_memory(0);
	flashlight.visible = data.flashlight_visible;
