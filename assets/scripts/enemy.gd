class_name Enemy extends CharacterBody3D

const SPEED = 4.0
const CHASE_SPEED = 6.0;
const JUMP_VELOCITY = 4.5
const EIGHTH = 1.0 / 8.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

@onready var nav_agent: NavigationAgent3D = $NavAgent;
@onready var sprite: AnimatedSprite3D = $Sprite;
@onready var shadeSprite: AnimatedSprite3D = $ShadeSprite;

var nav_paused: bool = false;
var sprite_frames: SpriteFrames;

@export var sprite_name: String;
@export var sprite_mirrored: bool = true;

@export var walk_start_frame: String = "a";
@export var num_walk_frames: int = 4;

@export var hurt_start_frame: String;
@export var num_hurt_frames: int;

@export var attack_start_frame: String;
@export var num_attack_frames: int;

var health: int = 50;
var curr_anim_prefix: String = "";
var curr_anim_suffix: String = "";
var angle_to_player: float = 0;

var test_public: bool = false;
var is_attacking: bool = false;
var player_target: Player = null;

var has_last_known_target_position: bool = false;
var last_known_target_position: Vector3;

func _ready():
	var walk_frames = [];
	for i in range(num_walk_frames):
		walk_frames.push_back(char(walk_start_frame.to_ascii_buffer()[0] + i));
	load_sprite_frames("walk", sprite_name, walk_frames, true);
	
	var hurt_frames = [];
	for i in range(num_hurt_frames):
		hurt_frames.push_back(char(hurt_start_frame.to_ascii_buffer()[0] + i));
	load_sprite_frames("hurt", sprite_name, hurt_frames, false);
	
	var attack_frames = [];
	for i in range(num_attack_frames):
		attack_frames.push_back(char(attack_start_frame.to_ascii_buffer()[0] + i));
	load_sprite_frames("attack", sprite_name, attack_frames, false);
	
	sprite.sprite_frames = sprite_frames;
	sprite.frame_changed.connect(_on_sprite_frame_changed);
	shadeSprite.sprite_frames = sprite_frames;
	
	await NavigationServer3D.map_changed;
	nav_agent.link_reached.connect(_on_nav_agent_link_reached);
	nav_agent.navigation_finished.connect(_on_nav_agent_navigation_finished);
	
func _on_sprite_frame_changed():
	if sprite.material_override:
		sprite.material_override.set_shader_parameter("tex", sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame));

func falter_shade(duration: float):
	set_shaded(false);
	await get_tree().create_timer(duration).timeout;
	set_shaded(true);

func set_shaded(shaded: bool):
	if shaded:
		$Sprite.layers = 2;
		$ShadeSprite.visible = true;
		$ShadeSprite.layers = 1;
	else:
		$Sprite.layers = 1;
		$ShadeSprite.visible = false;

func _on_nav_agent_link_reached(details):
	var door: Door = details.owner.get_parent() as Door;
	if door and not door.open:
		await get_tree().create_timer(0.2).timeout;
		$Interactor.interact();
		nav_paused = true;
		await get_tree().create_timer(0.5).timeout;
		nav_paused = false;

func _on_nav_agent_navigation_finished():
	await get_tree().create_timer(1.0).timeout;
	walk_random();

func load_sprite_frames(anim_prefix: String, prefix: String, frames: Array, loop: bool):
	if frames.is_empty():
		return;

	var indices = [["1"], ["2", "8"], ["3", "7"], ["4", "6"], ["5"]] if sprite_mirrored else [["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"]];
	
	if not sprite_frames:
		sprite_frames = SpriteFrames.new();
	
	for i in indices:
		var arr: PackedStringArray = (i);
		var anim_name = anim_prefix + "_" + "_".join(arr);
		sprite_frames.add_animation(anim_name);
		sprite_frames.set_animation_loop(anim_name, loop);
		for f in frames:
			# eg. a1, b2b8, etc.
			var suffix = "";
			for j in i:
				suffix += f + j;
				
			var path = "res://assets/freedoom/sprites/%s%s.png" % [prefix, suffix];
			sprite_frames.add_frame(anim_name, load(path));

func walk_random():
	var random = Vector3(randf_range(-20.0, 20.0), 0, randf_range(-20.0, 20.0));
	var closest = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, random);
	navigate_to(closest);

func handle_flash(source_position: Vector3):
	var angle = get_face_angle_to_position(source_position);
	var ratio = abs(angle) / PI;
	# print(ratio);
	# if ratio > 0.75:
	#	set_shaded(false);
	#	deal_damage();
	#elif ratio > 0.5:
	# 	falter_shade(0.1);
	
func deal_damage():
	nav_paused = true;
	play_animation("hurt");

func choose_flipped_sprite_suffix(flip: bool, a: String, b: String):
	if sprite_mirrored:
		sprite.flip_h = flip;
		shadeSprite.flip_h = flip;
		return a + "_" + b;
	else:
		return b if flip else a

func get_face_angle_to_position(pos: Vector3):
	var forward = -global_transform.basis.z;
	var to_target = global_position - pos;
	to_target.y = 0;
	to_target = to_target.normalized();
	
	var angle = atan2(to_target.z, to_target.x) - atan2(forward.z, forward.x);
	# Make sure that angle is between -PI and PI
	if angle < -PI:
		angle += PI * 2;
	elif angle > PI:
		angle -= PI * 2;
	
	return angle;

func _process(_delta):
	angle_to_player = get_face_angle_to_position(get_viewport().get_camera_3d().global_position);
	var pi_ratio = abs(angle_to_player) / PI;
	var flip = angle_to_player < 0;

	if pi_ratio < EIGHTH:
		curr_anim_suffix = "5";
	elif pi_ratio < 3 * EIGHTH:
		curr_anim_suffix = choose_flipped_sprite_suffix(flip, "4", "6");
	elif pi_ratio < 5 * EIGHTH:
		curr_anim_suffix = choose_flipped_sprite_suffix(flip, "3", "7");
	elif pi_ratio < 7 * EIGHTH:
		curr_anim_suffix = choose_flipped_sprite_suffix(flip, "2", "8");
	else:
		curr_anim_suffix = "1";

	if not is_attacking:
		play_animation("walk");
	
	var curr_speed = velocity.length();
	var anim_speed = 1;
	if curr_anim_prefix == "walk":
		anim_speed = curr_speed / SPEED;
		if anim_speed == 0.0:
			sprite.set_frame_and_progress(1, 0);
			shadeSprite.set_frame_and_progress(1, 0);
	elif curr_anim_prefix == "attack":
		anim_speed = 2;
	sprite.speed_scale = anim_speed;
	shadeSprite.speed_scale = anim_speed;

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity = Vector3.ZERO;
	if not nav_agent.is_navigation_finished():
		var target = nav_agent.get_next_path_position();
		if global_position.distance_to(target) > 0.1 and not nav_paused and not is_attacking:
			var look_at_target = Vector3(target);
			look_at_target.y = global_position.y;
			look_at(look_at_target);
			var to_target =  target - global_position;
			to_target.y = 0;
			velocity = to_target.normalized() * (CHASE_SPEED if player_target else SPEED);
	
	check_player_target();
	
	if not player_target and has_last_known_target_position:
		has_last_known_target_position = false;
		navigate_to(last_known_target_position);
	
	move_and_slide()

func check_player_target():
	if abs(angle_to_player) > PI * 6 * EIGHTH:
		var space_state = get_parent().get_world_3d().direct_space_state;
		var player_ray_query = PhysicsRayQueryParameters3D.create(global_position, get_viewport().get_camera_3d().global_position);
		player_ray_query.collide_with_areas = false;
		player_ray_query.collide_with_bodies = true;
		player_ray_query.collision_mask = ~2;
		
		var player_result = space_state.intersect_ray(player_ray_query);
		var collider = player_result.collider;
		if collider and collider is Player:
			player_target = collider as Player;
		else:
			if player_target:
				has_last_known_target_position = true;
				last_known_target_position = player_target.global_position;
			else:
				has_last_known_target_position = false;
			player_target = null;

func navigate_to(target: Vector3):
	nav_agent.target_desired_distance = 2.0;
	nav_agent.target_position = target;

func play_animation(prefix: String):
	curr_anim_prefix = prefix;
	var full_anim_name = prefix + "_" + curr_anim_suffix;
	if sprite.sprite_frames.has_animation(full_anim_name):
		sprite.play(full_anim_name);
	if shadeSprite.sprite_frames.has_animation(full_anim_name):
		shadeSprite.play(full_anim_name);

func attack(player: Player):
	is_attacking = true;
	play_animation("attack");
	await get_tree().create_timer(0.5).timeout;
	player.modify_health(-10);
	is_attacking = false;
