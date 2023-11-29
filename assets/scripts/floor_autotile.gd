@tool
extends StaticBody3D

@export var texture: Texture2D;

func _ready():
	visibility_changed.connect(update_material);
	update_material();

func update_material():
	var material: StandardMaterial3D = $Sprite3D.material_override;
	material.albedo_texture = texture;
	material.uv1_scale.x = scale.x;
	material.uv1_scale.y = scale.z;
