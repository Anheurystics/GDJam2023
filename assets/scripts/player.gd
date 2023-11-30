class_name Player extends CharacterBody3D

const SPEED = 4.0
const SPRINT_SPEED = 6.0
const ADS_SPEED = 4.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var max_base_health = 100;
@export var max_over_health = 200;
@export var over_health_decay = 2;
@export var max_battery = 100;
@export var max_memory = 10;

@export var flashlight_drain_rate = 5;
@export var flashlight_regen_rate = 0.5;

@onready var health: float = max_base_health; # HP
@onready var battery: float = max_battery; # Flashlight
@onready var memory: int = max_memory / 2; # Camera

@onready var flashlight: SpotLight3D = $Flashlight;
@onready var interactor: Interactor = $Interactor;
@onready var snapshot: Snapshot = $Snapshot;

var grab_timer: Timer;
var grab_source: Enemy;

signal health_changed(old: float, new: float, show_flash: bool);
signal battery_changed(old: float, new: float, pulse: bool);
signal memory_changed(old: int, new: int);
signal message_logged(message: String);

var owned_keys: PackedStringArray = [];

var flashlight_sphere_query: PhysicsShapeQueryParameters3D;
var death_time: int;

func _ready():
	# Call these to initialize HUD values
	modify_health(0);
	modify_battery(0);
	modify_memory(0);
	
	flashlight_sphere_query = PhysicsShapeQueryParameters3D.new();
	flashlight_sphere_query.collide_with_areas = false;
	flashlight_sphere_query.collide_with_bodies = true;
	flashlight_sphere_query.collision_mask = 4;
	
	grab_timer = Timer.new();
	grab_timer.one_shot = true;
	grab_timer.stop();
	add_child(grab_timer);
	
	var sphere_shape = SphereShape3D.new();
	sphere_shape.radius = 12;
	flashlight_sphere_query.shape = sphere_shape;

func check_death_input():
	if Time.get_ticks_msec() - death_time > 2000:
		if Input.is_anything_pressed():
			get_tree().change_scene_to_file("res://assets/scenes/levels/menu.tscn");

func _process(delta):
	if health <= 0:
		check_death_input();
		return;

	var rotate_dir = Input.get_vector("look_left", "look_right", "look_left", "look_right")
	if rotate_dir.x != 0:
		var rotate_sign = sign(rotate_dir.x)
		rotate_y(-PI * 0.75 * rotate_sign * delta)
	
	if Input.is_action_just_pressed("interact"):
		interactor.interact();
		
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible;
		flashlight.find_child("SFX").play();
	
	if battery == 0:
		flashlight.visible = false;
	
	if flashlight.visible:
		modify_battery(-flashlight_drain_rate * delta);
		if battery <= 0:
			flashlight.visible = false;
	else:
		modify_battery(flashlight_regen_rate * delta);
	
	if Input.is_action_just_pressed("take_picture") and snapshot.camera_raised and memory > 0:
		snapshot.take_picture();
		modify_memory(-1);
	
	check_enemies(delta);

	if health > max_base_health:
		var decay = health - max(health - (over_health_decay * delta), max_base_health);
		if decay > 0:
			modify_health(-decay, false);

func check_enemies(delta):
	var space_state = get_parent().get_world_3d().direct_space_state;
	flashlight_sphere_query.transform.origin = global_position
	var sphere_results = space_state.intersect_shape(flashlight_sphere_query);
	if sphere_results:
		for result in sphere_results:
			var enemy: Enemy = result.collider as Enemy;
			
			# Check if this enemy is within line of sight using a raycast
			var enemy_ray_query = PhysicsRayQueryParameters3D.create(global_position, enemy.global_position);
			enemy_ray_query.collide_with_areas = false;
			enemy_ray_query.collide_with_bodies = true;
			enemy_ray_query.collision_mask = ~2;
			
			var enemy_result = space_state.intersect_ray(enemy_ray_query);
			if enemy_result && enemy == enemy_result.collider:
				if flashlight.visible:
					var to_enemy = enemy_ray_query.to - enemy_ray_query.from;
					var ratio = acos(to_enemy.normalized().dot(global_transform.basis.z)) / PI;
					if ratio > 0.8:
						var att = 1.0 - (to_enemy.length() / 12.0);
						enemy.deal_damage(5 * ((ratio - 0.8) / 0.2) * att * delta, self);
						if !grab_timer.is_stopped() && grab_source == enemy:
							grab_timer.stop();
							grab_source = null;
				
				enemy.set_is_in_camera(!enemy.captured && enemy.is_facing_flash(get_viewport().get_camera_3d().global_position, get_parent() as Player));
				if enemy.is_in_camera:
					if !snapshot.enemies_in_camera.has(enemy):
						snapshot.enemies_in_camera.push_back(enemy);
				else:
					var index = snapshot.enemies_in_camera.find(enemy);
					if index > -1:
						snapshot.enemies_in_camera.remove_at(index);

func _physics_process(delta):
	if health <= 0:
		return;

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed_to_use = SPEED;
	if snapshot.camera_ads > 0:
		speed_to_use = ADS_SPEED;
	elif Input.is_action_pressed("sprint") and direction.dot(global_transform.basis.z) <= 0:
		speed_to_use = SPRINT_SPEED;

	if !grab_timer.is_stopped():
		speed_to_use = 0.5;
	
	if direction:
		velocity.x = direction.x * speed_to_use
		velocity.z = direction.z * speed_to_use
	else:
		velocity.x = move_toward(velocity.x, 0, speed_to_use)
		velocity.z = move_toward(velocity.z, 0, speed_to_use)

	move_and_slide()

func can_pickup_health():
	return health < max_over_health;

func modify_health(amount: float, play_effects: bool = true):
	if health <= 0:
		return;

	var old = health;
	health = clamp(health + amount, 0, max_over_health);
	health_changed.emit(old, health, play_effects);
	
	if health <= 0:
		death_time = Time.get_ticks_msec();
		$SFX/Death.play();
		var tween = get_tree().create_tween();
		tween.set_parallel(true);
		tween.tween_property($Camera3D, "position:y", 0, 0.8);
		tween.tween_property($Camera3D, "rotation:y", PI/2, 0.8);
	elif amount < 0:
		if play_effects:
			$SFX/Pain.play();

func increment_grab(duration: float, enemy: Enemy):
	if !grab_timer.is_stopped() && grab_timer.time_left > duration:
		return;
	grab_timer.start(duration);
	grab_source = enemy;

func can_pickup_battery():
	return battery < 100;

func modify_battery(amount: float, pulse: bool = false):
	var old = battery
	battery = clamp(battery + amount, 0, 100);
	battery_changed.emit(old, battery, pulse);

func can_pickup_memory():
	return memory < 20;

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

func log_message(message: String):
	message_logged.emit(message);
