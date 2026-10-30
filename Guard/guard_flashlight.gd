class_name GuardFlashlight
extends SkeletonModifier3D
## Fäster lampan i vänster hand och justerar armen ovanpå animationen.

## Armriktningar relativt bröstet. Modellens +Z är framåt och +X åt vänster.
const UPPER_ARM := Vector3(0.22, -1.0, 0.25)
const FOREARM := Vector3(-0.05, -0.08, 1.0)
const HAND := Vector3(0.0, -0.1, 1.0)
## Lampans läge under fingrarna.
const UNDER_HAND := 0.05
const LAMP_LENGTH := 0.22

var light: SpotLight3D
var _torch: Node3D
var _lens: MeshInstance3D
var _chest := -1
var _chest_rest := Basis()


## Lägg till lampan om modellen har ett skelett.
static func attach(guard: Node3D, spot: SpotLight3D) -> void:
	var model := guard.get_node_or_null("Model")
	if model == null:
		return
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var modifier := GuardFlashlight.new()
	modifier.name = "HeldFlashlight"
	modifier.light = spot
	skeletons[0].add_child(modifier)


func _ready() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	_chest = skeleton.find_bone("mixamorig_Spine2")
	if _chest != -1:
		_chest_rest = skeleton.get_bone_global_rest(_chest).basis.orthonormalized()
	_build_torch()


func _build_torch() -> void:
	_torch = Node3D.new()
	_torch.top_level = true
	add_child(_torch)
	var body := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.028
	tube.bottom_radius = 0.022
	tube.height = LAMP_LENGTH
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("2b2e33")
	metal.metallic = 0.6
	metal.roughness = 0.4
	tube.material = metal
	body.mesh = tube
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_torch.add_child(body)
	# Lampans lysande glas.
	_lens = MeshInstance3D.new()
	var glass := CylinderMesh.new()
	glass.top_radius = 0.034
	glass.bottom_radius = 0.03
	glass.height = 0.04
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1, 0.94, 0.8)
	glow.emission_enabled = true
	glow.emission = Color(1, 0.9, 0.7)
	glow.emission_energy_multiplier = 3.0
	glass.material = glow
	_lens.mesh = glass
	_lens.position = Vector3(0, LAMP_LENGTH / 2.0, 0)
	_lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_torch.add_child(_lens)


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or _torch == null:
		return
	# Överkroppens rotation från viloposen.
	var turn := Basis()
	if _chest != -1:
		turn = skeleton.get_bone_global_pose(_chest).basis.orthonormalized() * _chest_rest.inverse()
	_point(skeleton, "mixamorig_LeftArm", "mixamorig_LeftForeArm", turn * UPPER_ARM)
	_point(skeleton, "mixamorig_LeftForeArm", "mixamorig_LeftHand", turn * FOREARM)
	_point(skeleton, "mixamorig_LeftHand", "mixamorig_LeftHandMiddle1", turn * HAND)
	# Böj fingrarna runt lampan.
	for finger in ["Index", "Middle", "Ring", "Pinky"]:
		var bone: String = "mixamorig_LeftHand" + finger
		_point(skeleton, bone + "1", bone + "2", turn * Vector3(0, -0.6, 1))
		_point(skeleton, bone + "2", bone + "3", turn * Vector3(0, -1, -0.2))
		_point(skeleton, bone + "3", bone + "4", turn * Vector3(0, -0.4, -1))
	_point(skeleton, "mixamorig_LeftHandThumb1", "mixamorig_LeftHandThumb2", turn * Vector3(-0.3, -1, 0.3))
	_point(skeleton, "mixamorig_LeftHandThumb2", "mixamorig_LeftHandThumb3", turn * Vector3(-0.1, -1, 0.5))
	_point(skeleton, "mixamorig_LeftHandThumb3", "mixamorig_LeftHandThumb4", turn * Vector3(0.2, -0.6, 1))

	# Placera lampan under handen och följ handens riktning.
	var grip_bone := skeleton.find_bone("mixamorig_LeftHandMiddle1")
	if grip_bone == -1:
		return
	var grip := skeleton.get_bone_global_pose(grip_bone).origin
	var forward := (turn * HAND).normalized()
	var side := forward.cross(Vector3.UP).normalized()
	var up := side.cross(forward)
	var center := grip + forward * 0.05 + Vector3.DOWN * UNDER_HAND
	_torch.global_transform = skeleton.global_transform * Transform3D(Basis(side, forward, up), center)
	if light:
		light.global_position = skeleton.global_transform * (center + forward * (LAMP_LENGTH / 2.0 + 0.03))


## Vrid benet mot den angivna riktningen.
func _point(skeleton: Skeleton3D, bone_name: String, child_name: String, direction: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	var child := skeleton.find_bone(child_name)
	if bone == -1 or child == -1:
		return
	var pose := skeleton.get_bone_global_pose(bone)
	var now := (skeleton.get_bone_global_pose(child).origin - pose.origin).normalized()
	var wanted := direction.normalized()
	if now.is_zero_approx() or now.is_equal_approx(wanted):
		return
	var rotation := Quaternion(now, wanted)
	skeleton.set_bone_global_pose(bone, Transform3D(Basis(rotation) * pose.basis, pose.origin))
