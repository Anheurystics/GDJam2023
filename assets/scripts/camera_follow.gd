extends Camera3D

var camera: Camera3D;
var snapshot: Snapshot;

func _ready():
	camera = $"../../Player/Camera3D";
	snapshot = $"../../Player/Snapshot";

func _process(_delta):
	if !camera || !snapshot:
		return;
	global_position = camera.global_position
	global_position.y -= 0.4;
	global_position.y += snapshot.camera_ads * 0.2;
	global_rotation = camera.global_rotation;
