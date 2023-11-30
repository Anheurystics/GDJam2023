class_name Enemy extends CharacterBody3D

const EIGHTH = 1.0 / 8.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

@onready var nav_agent: NavigationAgent3D = $NavAgent;
@onready var sprite: AnimatedSprite3D = $Sprite;
@onready var dissolve: Dissolve = $Dissolve;
@onready var invisibleSprite: AnimatedSprite3D = $InvisibleSprite;

var nav_paused: bool = false;
var sprite_frames: SpriteFrames;

@export var sprite_name: String;
@export var sprite_mirrored_dict = {"walk": true, "hurt": true, "attack": true};

@export var walk_start_frame: String = "a";
@export var num_walk_frames: int = 4;

@export var hurt_start_frame: String;
@export var num_hurt_frames: int;

@export var attack_start_frame: String;
@export var num_attack_frames: int;

@export var can_open_doors: bool = true;
@export var wander_on_start: bool = true;

@export var max_health: float = 50;
@onready var health: float = max_health;
var captured: bool = false
var curr_anim_prefix: String = "";
var curr_anim_suffix: String = "";
var angle_to_player: float = 0;

@export var attack_damage: int = 10;
@export var attack_rate: float = 1.0;
var attack_timer: Timer;

var is_attacking: bool = false;
var player_target: Player = null;
var is_following_player: bool = false;

var has_last_known_target_position: bool = false;
var last_known_target_position: Vector3;

var idle_grunt_timer: Timer;
var is_in_camera: bool = false;

var death_particles: GPUParticles3D;

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
	sprite.material_override = sprite.material_override.duplicate();
	invisibleSprite.sprite_frames = sprite_frames;
	invisibleSprite.material_override = invisibleSprite.material_override.duplicate();
	
	dissolve.initialize(sprite.material_override);
	dissolve.set_dissolve_amount(0.0);

	death_particles = preload("res://assets/scenes/prefabs/flash_particles.tscn").instantiate();
	death_particles.emitting = false;
	add_child(death_particles);
	
	idle_grunt_timer = Timer.new();
	idle_grunt_timer.one_shot = true;
	idle_grunt_timer.timeout.connect(play_grunt_sfx);
	add_child(idle_grunt_timer);
	idle_grunt_timer.start(randi_range(3, 5));
	
	attack_timer = Timer.new();
	attack_timer.one_shot = false;
	attack_timer.timeout.connect(attack_target);
	add_child(attack_timer);
	
	set_shaded(false);
	$Sprite.cast_shadow = false;
	
	await NavigationServer3D.map_changed;
	nav_agent.link_reached.connect(_on_nav_agent_link_reached);
	nav_agent.navigation_finished.connect(_on_nav_agent_navigation_finished);
	
	if wander_on_start:
		walk_random(0.0);

func _on_sprite_frame_changed():
	if sprite.material_override:
		sprite.material_override.set_shader_parameter("tex", sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame));
	
func falter_shade(duration: float):
	set_shaded(false);
	await get_tree().create_timer(duration).timeout;
	set_shaded(true);

func set_shaded(shaded: bool):
	var sprite_layer: int;
	var sprite_shadow: GeometryInstance3D.ShadowCastingSetting;
	if shaded:
		sprite_layer = 2;
		sprite_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;
	else:
		sprite_layer = 1;
		sprite_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON;
	$Sprite.layers = sprite_layer;
	$Sprite.cast_shadow = sprite_shadow;
	$InvisibleSprite.visible = shaded;

func _on_nav_agent_link_reached(details):
	var door: Door = details.owner.get_parent() as Door;
	if door and not door.open:
		if door.can_enemy_open and can_open_doors:
			await get_tree().create_timer(0.2).timeout;
			$Interactor.interact();
			nav_paused = true;
			await get_tree().create_timer(0.5).timeout;
			nav_paused = false;
		else:
			walk_random(1.0);

func _on_nav_agent_navigation_finished():
	if is_following_player:
		navigate_to(player_target.global_position);
	else:
		walk_random(1.0);

func deal_damage(value: float, player: Player):
	var old = health;
	health = max(0, health - value);
	dissolve.set_dissolve_amount(1.0 - (float(health) / max_health));
	if !player_target && player:
		player_target = player;

func load_sprite_frames(anim_prefix: String, prefix: String, frames: Array, loop: bool):
	if frames.is_empty():
		return;

	var is_mirrored = true;
	if sprite_mirrored_dict.has(anim_prefix):
		is_mirrored = sprite_mirrored_dict[anim_prefix];
	var indices = [["1"], ["2", "8"], ["3", "7"], ["4", "6"], ["5"]] if is_mirrored else [["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"]];
	
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

func walk_random(delay: float):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout;
	
	var random = global_position + Vector3(randf_range(-10.0, 10.0), 0, randf_range(-10.0, 10.0));
	navigate_to(random);

func is_facing_flash(source_position: Vector3, player: Player):
	var angle = get_face_angle_to_position(source_position);
	var ratio = abs(angle) / PI;
	return ratio > 0.80;

func handle_flash(source_position: Vector3, player: Player):
	if is_facing_flash(source_position, player) and health < 5:
		captured = true;
		on_death();
		player.modify_battery(10, true);
	else:
		deal_damage(10, player);
		
func set_is_in_camera(in_camera: bool):
	is_in_camera = in_camera;
	$Outline.visible = in_camera;

func play_grunt_sfx():
	if captured:
		return;
	if player_target:
		$SFX/IdleGrunt.play();
	idle_grunt_timer.start(randi_range(3, 5));

func on_death():
	idle_grunt_timer.stop();
	$SFX/Death.play();
	attack_timer.stop();
	set_sprite_flash(0.0);
	var tween = get_tree().create_tween();
	tween.tween_method(set_sprite_flash, 0.0, 1.0, 0.4);
	await tween.finished;
	sprite.visible = false;
	death_particles.emitting = true;
	await get_tree().create_timer(death_particles.lifetime).timeout;
	queue_free();

func set_sprite_flash(value: float):
	(sprite.material_override as ShaderMaterial).set_shader_parameter("flash", value);

func choose_flipped_sprite_suffix(anim_prefix: String, flip: bool, a: String, b: String):
	if sprite_mirrored_dict[anim_prefix]:
		sprite.flip_h = flip;
		invisibleSprite.flip_h = flip;
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
	if captured:
		return;

	angle_to_player = get_face_angle_to_position(get_viewport().get_camera_3d().global_position);
	var pi_ratio = abs(angle_to_player) / PI;
	var flip = angle_to_player < 0;

	if not is_attacking:
		play_animation("walk");

	if pi_ratio < EIGHTH:
		curr_anim_suffix = "5";
	elif pi_ratio < 3 * EIGHTH:
		curr_anim_suffix = choose_flipped_sprite_suffix(curr_anim_prefix, flip, "4", "6");
	elif pi_ratio < 5 * EIGHTH:
		curr_anim_suffix = choose_flipped_sprite_suffix(curr_anim_prefix, flip, "3", "7");
	elif pi_ratio < 7 * EIGHTH:
		curr_anim_suffix = choose_flipped_sprite_suffix(curr_anim_prefix, flip, "2", "8");
	else:
		curr_anim_suffix = "1";

	var curr_speed = velocity.length();
	var anim_speed = 1;
	if curr_anim_prefix == "walk":
		anim_speed = curr_speed / get_speed();
		if anim_speed == 0.0:
			sprite.set_frame_and_progress(1, 0);
			invisibleSprite.set_frame_and_progress(1, 0);
	elif curr_anim_prefix == "attack":
		anim_speed = 2;
	sprite.speed_scale = anim_speed;
	invisibleSprite.speed_scale = anim_speed;
	
	if player_target and not is_following_player:
		is_following_player = true;
		await get_tree().create_timer(0.5).timeout;
		if player_target:
			navigate_to(player_target.global_position);
	
	if is_following_player:
		if not player_target:
			attack_timer.stop();
			is_following_player = false;
		else:
			if attack_timer and attack_timer.is_stopped():
				attack_timer.start(attack_rate);

	if attack_timer and not attack_timer.is_stopped():
		var diff = player_target.global_position - global_position;
		diff.y = 0; 
		attack_timer.paused = diff.length() > 2.0

func _physics_process(delta):
	if captured:
		return;

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
			velocity = to_target.normalized() * get_speed();
			if dissolve.is_emitting():
				velocity *= 0.5;
	
	check_player_target();
	
	if not player_target and has_last_known_target_position:
		has_last_known_target_position = false;
		navigate_to(last_known_target_position);
	
	move_and_slide();

func check_player_target():
	if abs(angle_to_player) <= PI * 5 * EIGHTH:
		return;
		
	var space_state = get_parent().get_world_3d().direct_space_state;
	var player_ray_query = PhysicsRayQueryParameters3D.create(global_position, get_viewport().get_camera_3d().global_position);
	player_ray_query.collide_with_areas = false;
	player_ray_query.collide_with_bodies = true;
	player_ray_query.collision_mask = ~2;

	var player_result = space_state.intersect_ray(player_ray_query);
	if !player_result:
		return;
		
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
	var closest = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, target);
	nav_agent.target_desired_distance = 2.0;
	nav_agent.target_position = closest;

func play_animation(prefix: String):
	curr_anim_prefix = prefix;
	var full_anim_name = prefix + "_" + curr_anim_suffix;
	if sprite.sprite_frames.has_animation(full_anim_name):
		sprite.play(full_anim_name);
	if invisibleSprite.sprite_frames.has_animation(full_anim_name):
		invisibleSprite.play(full_anim_name);

func get_speed():
	if player_target:
		return 6;
	else:
		return 4;

func attack(player: Player):
	if captured:
		return;
		
	is_attacking = true;
	play_animation("attack");
	$SFX/Attack.play();
	await get_tree().create_timer(0.5).timeout;
	is_attacking = false;
	
	if health > 0:
		player.modify_health(-attack_damage);
		player.increment_grab(0.5, self);

func attack_target():
	if player_target:
		attack(player_target);

func serialize():
	return {
		"global_position": global_position,
		"nav_paused": nav_paused,
		"nav_target_position": nav_agent.target_position,
		"health": health,
		"is_attacking": is_attacking,
		"player_target": null if player_target == null else player_target.get_path(),
		"has_last_known_target_position": has_last_known_target_position,
		"last_known_target_position": last_known_target_position,
		"dissolve_prev_amount": dissolve.prev_amount,
		"dissolve_curr_amount": dissolve.curr_amount,
		"is_following_player": is_following_player
	}

func deserialize(data):
	global_position = data.global_position;
	nav_paused = data.nav_paused;
	nav_agent.target_position = data.nav_target_position;
	health = data.health;
	is_attacking = data.is_attacking;
	player_target = null if !data.player_target else get_node(data.player_target);
	has_last_known_target_position = data.has_last_known_target_position;
	last_known_target_position = data.last_known_target_position;
	dissolve.prev_amount = data.dissolve_prev_amount;
	dissolve.curr_amount = data.dissolve_curr_amount;
	is_following_player = data.is_following_player;
