extends MeshInstance

onready var quadtree = $QuadTreeNode
onready var terrain_tool = $"../TerrainTool"
onready var mesh_data_tool: MeshDataTool = create_datatool_from_mesh()

var mesh_changed = false

func _ready() -> void:
	terrain_tool.hide()
	for i in range(mesh_data_tool.get_vertex_count()):
		var vertex = mesh_data_tool.get_vertex(i)
		var spatial_vertex = Spatial.new()
		spatial_vertex.translation = vertex
		mesh_data_tool.set_vertex(i, Vector3(vertex.x, 0, vertex.z))
		spatial_vertex.set_meta("i", i)
		quadtree.add_body(spatial_vertex, _get_common_bounds(vertex))
		if i % 100 == 0:
			yield(get_tree(), "idle_frame")
	print(mesh_data_tool.get_vertex_count())
	quadtree.draw()
	terrain_tool.show()

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.scancode == KEY_L and event.pressed:
		quadtree.draw(1, true, true, true, $"../ImmediateGeometry", SpatialMaterial.new())
		quadtree.dump()

func _get_common_bounds(vertex):
#	print(vertex)
#	print(AABB(Vector3(vertex.x-0.25, vertex.y, vertex.z-0.25), Vector3(vertex.x+0.5, vertex.y, vertex.z+0.5)))
	return AABB(Vector3(vertex.x-0.25, vertex.y, vertex.z-0.25), Vector3(0.5, 0, 0.5))

func create_datatool_from_mesh():
	var surfacetool = SurfaceTool.new()

	surfacetool.create_from(mesh, 0)
	mesh_data_tool = MeshDataTool.new()

# warning-ignore:return_value_discarded
	mesh_data_tool.create_from_surface(surfacetool.commit(), 0)
	return mesh_data_tool

func _process(delta: float) -> void:
	if terrain_tool.visible:
		if terrain_tool.position:
			_alter_mesh(terrain_tool.get_transformed_aabb(), delta)
			if mesh_changed:
#				print("making mesh")
				create_mesh_from_datatool()
				mesh_changed = false
			terrain_tool.reset_values()

func _alter_mesh(query_bound: AABB, delta):
#	print(query_bound)
	query_bound.size.y += 100
	query_bound.position.y -= 50
#	print(query_bound)
	var bodies = quadtree.query(query_bound)
#	print(bodies)
	for body in bodies:
#		print(bodies.size())
		var vertex = body.get_translation()
		var old_vertex = body.get_translation()
		var i = body.get_meta("i")
		if !terrain_tool.current_state == terrain_tool.TerrainToolStates.SLOPE_FLATTEN:
			vertex.y += terrain_tool.get_strength_at_position(old_vertex, true) * ((2.0 * int(!terrain_tool.current_state == terrain_tool.TerrainToolStates.SLOPE_DOWN)) - 1) * delta
		else:
			if int(vertex.y) == 0:
				vertex.y = lerp(vertex.y, 0, delta*5)
			else:
				vertex.y += terrain_tool.get_strength_at_position(old_vertex, false) * ((2.0 * int(vertex.y < 0)) - 1) * delta
		vertex.y = clamp(vertex.y, -50, 100)
		if vertex != old_vertex:
			mesh_data_tool.set_vertex(i, vertex)
			body.set_translation(vertex)
			quadtree.update_body(body, _get_common_bounds(vertex))
			mesh_changed = true
#		yield(get_tree(), "idle_frame")
	
	# normal calculation
	calculate_normals()

func calculate_normals():
	for i in range(mesh_data_tool.get_face_count()):
		# Get the index in the vertex array.
		var a = mesh_data_tool.get_face_vertex(i, 0)
		var b = mesh_data_tool.get_face_vertex(i, 1)
		var c = mesh_data_tool.get_face_vertex(i, 2)
		# Get vertex position using vertex index.
		var ap = mesh_data_tool.get_vertex(a)
		var bp = mesh_data_tool.get_vertex(b)
		var cp = mesh_data_tool.get_vertex(c)
		# Calculate face normal.
		var n = (bp - cp).cross(ap - bp).normalized()
		var an = (n + mesh_data_tool.get_vertex_normal(a)).normalized()
		var bn = (n + mesh_data_tool.get_vertex_normal(b)).normalized()
		var cn = (n + mesh_data_tool.get_vertex_normal(c)).normalized()
		# Add face normal to current vertex normal.
		# This will not result in perfect normals, but it will be close.
		mesh_data_tool.set_vertex_normal(a, an)
		mesh_data_tool.set_vertex_color(a, Color(an.x, an.y, an.z))
		mesh_data_tool.set_vertex_normal(b, bn)
		mesh_data_tool.set_vertex_color(b, Color(bn.x, bn.y, bn.z))
		mesh_data_tool.set_vertex_normal(c, cn)
		mesh_data_tool.set_vertex_color(c, Color(cn.x, cn.y, cn.z))

	# Run through vertices one last time to normalize normals and
		# set color to normal.

func create_mesh_from_datatool():
	var array_mesh = ArrayMesh.new()
# warning-ignore:return_value_discarded
	mesh_data_tool.commit_to_surface(array_mesh)
	mesh = array_mesh
	$StaticBody/CollisionShape.shape = array_mesh.create_trimesh_shape()
