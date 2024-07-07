tool
extends Spatial


# taken from https://github.com/Zylann/godot_heightmap_plugin/blob/master/addons/zylann.hterrain/util/util.gd
static func next_power_of_two(x: int) -> int:
	x -= 1
	x |= x >> 1
	x |= x >> 2
	x |= x >> 4
	x |= x >> 8
	x |= x >> 16
	x += 1
	return x

static func snap_to_nearest_power_of_two(current: int, x: int) -> int:
	if x < current:
		return previous_power_of_two(x)
	else:
		return next_power_of_two(x)

static func previous_power_of_two(x: int) -> int:
	if x <= 0:
		return 0
	x |= x >> 1
	x |= x >> 2
	x |= x >> 4
	x |= x >> 8
	x |= x >> 16
	return x - (x >> 1);


var _size: int = 64
var _chunk_size: int = 16
var chunks = {}
var height_map: Image = Image.new()
var quad_tree = QuadTreeNode.new()

export(NodePath) var terrain_tool_node
var terrain_tool

export(int) var lod_lvl = 0

export(Material) var terrain_material = SpatialMaterial.new()

func _ready():
	if Engine.editor_hint:
		return
	quad_tree.extents = Vector3(_size/2, 2, _size/2)
	quad_tree.capacity = 4
	quad_tree.max_levels = 6
	quad_tree.name = "QuadTreeNode"
	height_map.create(_size, _size, false, Image.FORMAT_RGBA8)
	quad_tree.immediate_geo_node_path =  "/root/World/Tools/ImmediateGeometry"
	add_child(quad_tree)
	
	if get_node_or_null(terrain_tool_node):
		terrain_tool = get_node(terrain_tool_node)
#	print(range(-_size/2-8, 64-/2+8, 16))
	var r = range((-_size+_chunk_size)/2, (_size+_chunk_size)/2, _chunk_size)
	# var r = range((-2*_chunk_size+_chunk_size)/2, (2*_chunk_size+_chunk_size)/2, _chunk_size)
	for i in r:
		for j in r:
			var image_offset: Vector2 = Vector2(range_lerp(i, -_size/2, _size/2, 0, _size), range_lerp(j, -_size/2, _size/2, 0, _size))
			var chunk = Chunk.new(Vector3(i, 0, j), _chunk_size, lod_lvl, height_map, image_offset)
			add_child(chunk)
			chunks[Vector3(i, 0, j)] = chunk
			chunk.name = "Chunk %d %d" % [i, j]
			chunk.translation = Vector3(i, 0, j)
			chunk.generate_mesh()
			chunk.material_override = terrain_material
			quad_tree.add_body(chunk)
	_draw_chunks()

func _draw_lines(aabb, immediate_geometry):
	for i in range(12):
		immediate_geometry.begin(Mesh.PRIMITIVE_LINES)
		for point in $"../AABBUtils".get_edge(aabb, i):
			immediate_geometry.add_vertex(point)
		immediate_geometry.end()
			

func _draw_chunk(chunk, immediate_geometry):
	var aabb = chunk.get_transformed_aabb()
	aabb.position.y -= 3
	aabb.size.y = 6
	_draw_lines(aabb, immediate_geometry)
	
func _draw_chunks():
	var immediate_geometry = $"../Tools/ImmediateGeometry2"
	immediate_geometry.clear()
	for chunk in chunks.values():
#	var chunk = chunks.values()[2 % chunks.values().size()]
		_draw_chunk(chunk, immediate_geometry)
	

func _process(delta):
	if Engine.editor_hint:
		return
		
	if terrain_tool.visible:
		if terrain_tool.position:
			var aabb = terrain_tool.get_transformed_aabb()
			aabb.position.y -= 50
			aabb.size.y += 100

			# print("--------: ", aabb)

			var vertex_size = 0.5

			var queried_chunks = quad_tree.query(aabb.grow(vertex_size))
			for chunk in queried_chunks:
				var new_aabb = aabb
				var old_aabb = (chunk.global_transform as Transform).xform_inv(new_aabb)
				# print("chunk: ", chunk, " (", chunk.get_transformed_aabb(), "), aabb: ", aabb, ", new: ", new_aabb, ", old: ", old_aabb)
#				old_aabb.position.y -= 50
#				old_aabb.size.y += 100
#				print(old_aabb)
				(chunk as Chunk)._process_chunk(delta, terrain_tool, old_aabb)
				
	terrain_tool.reset_values()
#	quad_tree.draw(0)
#	_draw_chunks()
			
func _unhandled_key_input(event):
	var immediate_geometry = $"../Tools/ImmediateGeometry2"
	if event.scancode == KEY_L:
		quad_tree.dump("cool.txt")
		OS.shell_open(ProjectSettings.globalize_path("user://dumps"))
	if Input.is_key_pressed(KEY_F3) and Input.is_key_pressed(KEY_G):
		immediate_geometry.visible = !immediate_geometry.visible
			

func _get_property_list():
	var properties = []
	properties.append({
		"name": "size",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "16,8192"
	})
	properties.append({
		"name": "chunk_size",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "8,64"
	})
	return properties

func _get(property):
	match property:
		"size":
			return _size
		"chunk_size": 
			return _chunk_size

func _set(property, value):
	match property:
		"size":
			_size = snap_to_nearest_power_of_two(_size, value)
			return true
		"chunk_size":
			_chunk_size = snap_to_nearest_power_of_two(_chunk_size, value)
			return true

