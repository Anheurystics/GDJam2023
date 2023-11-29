@tool
extends StaticBody3D

@export var texture_face: Texture2D;
@export var texture_side: Texture2D;

func _ready():
	visibility_changed.connect(update_material);
	update_material();

func update_material():
	var face_a_material: StandardMaterial3D = $FaceA.material_override;
	face_a_material.uv1_scale.x = scale.x;
	face_a_material.albedo_texture = texture_face;
	var face_b_material: StandardMaterial3D = $FaceB.material_override;
	face_b_material.uv1_scale.x = scale.x;
	face_b_material.albedo_texture = texture_face;
	
	var side_a_material: StandardMaterial3D = $SideA.material_override;
	side_a_material.albedo_texture = texture_side;
	var side_b_material: StandardMaterial3D = $SideB.material_override;
	side_b_material.albedo_texture = texture_side;
	var side_c_material: StandardMaterial3D = $SideC.material_override;
	side_c_material.albedo_texture = texture_side;
