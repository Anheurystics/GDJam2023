class_name Snapshot extends Node

const DEFAULT_ZOOM = 60;
const MIN_ZOOM = 20;
const MAX_ZOOM = 100;

var camera_raised: bool = false;

var subviewport: SubViewport;
var hud: HUD;
var camera: Camera3D;
var flash: SpotLight3D;

var camera_ads: float = 0.0;
var camera_res: float = 1.0;

var enemies_in_camera = [];

func _ready():
	var root: Node = get_tree().get_current_scene();
	subviewport = root.find_child("SubViewport");
	camera = root.find_child("Camera3D2");
	hud = root.find_child("HUD");
	hud.viewfinder.texture = subviewport.get_texture();
	flash = camera.find_child("Flash");
	set_camera_res(1.0);
	set_camera_zoom(DEFAULT_ZOOM);

func set_camera_zoom(zoom: float):
	camera.fov = clamp(zoom, MIN_ZOOM, MAX_ZOOM);

func increment_camera_zoom(zoom: float):
	set_camera_zoom(camera.fov + zoom);

func set_camera_res(res: float):
	camera_res = res;
	subviewport.size.x = floori(264 * res);
	subviewport.size.y = floori(180 * res);
	hud.viewfinder.apply_scale(Vector2.ONE / res);

func take_picture():
	$SFX.play();
	set_flash_enabled(true);
	# var screen: Sprite3D = get_node("../../Screen");
	# screen.texture = ImageTexture.create_from_image(viewfinder.texture.get_image());
	# screen.scale = Vector3.ONE / camera_res;
	await get_tree().create_timer(0.10).timeout;
	set_flash_enabled(false);

	for enemy in enemies_in_camera:
		if enemy && is_instance_valid(enemy) && !enemy.captured:
			enemy.handle_flash(get_viewport().get_camera_3d().global_position, get_parent() as Player);

func set_flash_enabled(enabled: bool):
	flash.visible = enabled;

func _process(delta):
	var curr_raised = Input.is_action_pressed("camera");
	if camera_raised != curr_raised:
		camera_raised = curr_raised;
		var tween = get_tree().create_tween();
		hud.update_camera(camera_raised);
		if camera_raised:
			camera_ads = 0.0;
			camera_res = 0.25;
			tween.tween_property(self, "camera_ads", 1.0, 0.25);
			tween.parallel().tween_property(self, "camera_res", 1.0, 0.25);
		else:
			camera_ads = 1.0;
			camera_res = 1.0;
			tween.tween_property(self, "camera_ads", 0.0, 0.25);
			tween.parallel().tween_property(self, "camera_res", 0.25, 0.25);
	
	# if camera_raised:
	# 	if Input.is_action_pressed("zoom_in"):
	#		increment_camera_zoom(-90 * delta);
	#		
	#	if Input.is_action_pressed("zoom_out"):
	#		increment_camera_zoom(90 * delta);
