# Run headless from the project root after changing bank/exterior collision geometry.
extends SceneTree
func _initialize(): call_deferred("run")
func run():
 for scene in ["res://Levels/Level_1/Level_1.tscn","res://Level2.tscn"]:
  var level=load(scene).instantiate()
  root.add_child(level)
  for g in get_nodes_in_group("guards"): g.set_physics_process(false)
  level.get_node("Player").set_physics_process(false)
  for i in range(5): await physics_frame
  var region=level.get_node("NavigationRegion3D" if "Level_1" in scene else "GuardNavigation")
  var mesh=region.navigation_mesh.duplicate()
  mesh.cell_size=0.1
  mesh.cell_height=0.1
  # Leave clearance around the 0.28 m actor capsule, including narrow desk aisles.
  mesh.agent_radius=0.3
  # Ramp joins need the original bake tolerance; actual steps remain collision-tested.
  mesh.agent_max_climb=0.5
  if "Level_1" in scene: mesh.filter_baking_aabb=AABB(Vector3(-20,-2,-15),Vector3(40,10,45))
  var data=NavigationMeshSourceGeometryData3D.new()
  NavigationServer3D.parse_source_geometry_data(mesh,data,level)
  NavigationServer3D.bake_from_source_geometry_data(mesh,data)
  var path="res://Levels/Level_1/GuardNavigation.tres" if "Level_1" in scene else "res://Levels/Level_2/GuardNavigation.tres"
  print("BAKE ",path," polys ",mesh.get_polygon_count()," SAVE ",ResourceSaver.save(mesh,path))
  if "Level_1" in scene:
   level.get_node("NavigationRegion3D/BANK/Vault_Door_Hinge").rotation.y = deg_to_rad(level.get_node("AccessCard").open_angle)
  else:
   level.get_node("BasementVault/VaultDoor").rotation.y = deg_to_rad(level.get_node("BasementVault/AccessCard").open_angle)
  for i in range(5): await physics_frame
  var open_data=NavigationMeshSourceGeometryData3D.new()
  var open_mesh=mesh.duplicate()
  NavigationServer3D.parse_source_geometry_data(open_mesh,open_data,level)
  NavigationServer3D.bake_from_source_geometry_data(open_mesh,open_data)
  print("Open vault save: ", ResourceSaver.save(open_mesh,path.replace("GuardNavigation.tres", "GuardNavigationOpenVault.tres")))
  level.queue_free()
  for i in range(5): await physics_frame
 quit()


