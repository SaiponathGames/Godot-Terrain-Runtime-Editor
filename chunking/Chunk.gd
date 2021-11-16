extends MeshInstance
class_name Chunk

var position = Vector3()
var image: Image
var size = 16
var lod_level = 0

const QuadTreeNode = preload("res://addons/sairam.quadtree/QuadTreeNode.gd")

var mesh_data_tool: MeshDataTool
var quad_tree: QuadTreeNode
var mesh_changed: bool = false
var draw_immediate_geometry: ImmediateGeometry
var collision_shape: CollisionShape
var draw_quad_tree = false

func _init(p_position, p_size, p_lod_level, p_image: Image, p_image_offset):
	position = p_position
	size = p_size
	image = p_image
	
	if range(0, 10+1).has(lod_level):
		lod_level = p_lod_level
	else:
		print("Lod level too high or low.")
	

func _ready():
	
	if draw_quad_tree:
		draw_immediate_geometry = ImmediateGeometry.new()
		draw_immediate_geometry.material_override = load("res://Materials/Drawing.material")
		add_child(draw_immediate_geometry)
	
	quad_tree = QuadTreeNode.new()
	quad_tree.max_levels = 50
	quad_tree.extents = Vector3(1, 0, 1) * size + Vector3.UP * 2
	quad_tree.capacity = 10
	if draw_quad_tree:
		quad_tree.immediate_geo_node_path = draw_immediate_geometry.get_path()
	add_child(quad_tree)
	
	var static_body = StaticBody.new()
	collision_shape = CollisionShape.new()
	static_body.add_child(collision_shape)
	add_child(static_body)
	

func generate_mesh():
	mesh = PlaneMesh.new()
	mesh.size = Vector2(size, size)
	
	if lod_level == 0:
		mesh.subdivide_width = (size * 2)-1
		mesh.subdivide_depth = (size * 2)-1
	if lod_level == 1:
		mesh.subdivide_width = size-1
		mesh.subdivide_depth = size-1
	if lod_level > 1:
		mesh.subdivide_width = (size/lod_level)-1
		mesh.subdivide_depth = (size/lod_level)-1
	
	mesh_data_tool = create_datatool_from_mesh()
	generate_collision_mesh()

	setup_quadtree()

func setup_quadtree():
	for i in range(mesh_data_tool.get_vertex_count()):
		var vertex = mesh_data_tool.get_vertex(i)
		var spatial_vertex = Spatial.new()
		spatial_vertex.translation = vertex
		mesh_data_tool.set_vertex(i, Vector3(vertex.x, 0, vertex.z))
		# print("vertex ", i, ": ", vertex)
		spatial_vertex.set_meta("i", i)
		quad_tree.add_body(spatial_vertex, _get_common_bounds(vertex))
	if draw_quad_tree:
		quad_tree.draw(1, true, true, true, global_transform)
#	print(mesh_data_tool.get_vertex_count())

func _get_common_bounds(vertex):
	return AABB(Vector3(vertex.x-0.25, vertex.y, vertex.z-0.25), Vector3(0.5, 0, 0.5))

func _process_chunk(delta, terrain_tool, aabb: AABB):
	var vertex_size = 0.5
	aabb.position.x = floor(aabb.position.x / vertex_size)*vertex_size
	aabb.position.z = floor(aabb.position.z / vertex_size)*vertex_size
	aabb.end.x = ceil(aabb.end.x / vertex_size)*vertex_size
	aabb.end.x = ceil(aabb.end.x / vertex_size)*vertex_size

	var bodies = quad_tree.query(aabb.grow(0.05))
	# print("chunk: ", self, "aabb:", aabb, " -> ", bodies.size())

	for body in bodies:
		var vertex = body.get_translation()
		var transformed_vertex = global_transform.xform(vertex)
		var old_vertex = body.get_translation()
		var i = body.get_meta("i")
#		print(transformed_vertex)
		if !terrain_tool.current_state == terrain_tool.TerrainToolStates.SLOPE_FLATTEN:
			vertex.y += terrain_tool.get_strength_at_position(transformed_vertex, false) * ((2.0 * int(!terrain_tool.current_state == terrain_tool.TerrainToolStates.SLOPE_DOWN)) - 1) * delta * 5
#			print(vertex.y)
		else:
			if int(vertex.y) == 0:
				vertex.y = lerp(vertex.y, 0, delta*5)
			else:
				vertex.y += terrain_tool.get_strength_at_position(transformed_vertex, false) * ((2.0 * int(vertex.y < 0)) - 1) * delta * 5
#		print(vertex.y)
		vertex.y = clamp(vertex.y, -100, 100)
		if vertex != old_vertex:
#			print("vertex ", i, ": ", vertex, ": ", old_vertex.y, " -> ", vertex.y)
			mesh_data_tool.set_vertex(i, vertex)
			body.set_translation(vertex)
			quad_tree.update_body(body, _get_common_bounds(vertex))
			mesh_changed = true
	if mesh_changed:
		calculate_normals()
		create_mesh_from_datatool()
		mesh_changed = false

func create_mesh_from_datatool():
	var array_mesh = ArrayMesh.new()
# warning-ignore:return_value_discarded
	mesh_data_tool.commit_to_surface(array_mesh)
	mesh = array_mesh
	if collision_shape:
		collision_shape.shape = mesh.create_convex_shape()


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

func generate_collision_mesh():
	var static_body = StaticBody.new()
	static_body.name = "StaticBody"
	var collision_shape = CollisionShape.new()
	collision_shape.name = "CollisionShape"
	var shape = mesh.create_trimesh_shape()
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	add_child(static_body)
	
func create_datatool_from_mesh():
	var surfacetool = SurfaceTool.new()

	surfacetool.create_from(mesh, 0)
	mesh_data_tool = MeshDataTool.new()

# warning-ignore:return_value_discarded
	mesh_data_tool.create_from_surface(surfacetool.commit(), 0)
	return mesh_data_tool
