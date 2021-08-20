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
export var chunk_size = 16
var chunks = {}
var height_map: Image = Image.new()
var quad_tree = QuadTreeNode.new()

export(NodePath) var terrain_tool_node
var terrain_tool

export(Material) var terrain_material = SpatialMaterial.new()

func _ready():
	if Engine.editor_hint:
		return
	quad_tree.extents = Vector3(_size/2, 2, _size/2)
	quad_tree.capacity = 4
	quad_tree.max_levels = 6
	height_map.create(_size, _size, false, Image.FORMAT_RGBA8)
	quad_tree.immediate_geo_node_path =  "/root/World/Tools/ImmediateGeometry"
	add_child(quad_tree)
	
	if get_node_or_null(terrain_tool_node):
		terrain_tool = get_node(terrain_tool_node)
#	print(range(-_size/2-8, 64-/2+8, 16))
	for i in range((-_size+chunk_size)/2, (_size+chunk_size)/2, chunk_size):
		for j in range((-_size+chunk_size)/2, (_size+chunk_size)/2, chunk_size):
			var image_offset: Vector2 = Vector2(range_lerp(i, -_size/2, _size/2, 0, _size), range_lerp(j, -_size/2, _size/2, 0, _size))
			var chunk = Chunk.new(Vector3(i, 0, j), chunk_size, 0, height_map, image_offset)
			add_child(chunk)
			chunks[Vector3(i, 0, j)] = chunk
			chunk.translation = Vector3(i, 0, j)
			chunk.generate_mesh()
			chunk.material_override = terrain_material
			quad_tree.add_body(chunk)

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
			var queried_chunks = quad_tree.query(aabb)
			for chunk in queried_chunks:
				var new_aabb = aabb.intersection(chunk.get_transformed_aabb())
				var old_aabb = (chunk.global_transform as Transform).xform_inv(new_aabb)
				old_aabb.position.y -= 50
				old_aabb.size.y += 100
				(chunk as Chunk)._process_chunk(delta, terrain_tool, old_aabb)
				
	terrain_tool.reset_values()
#	quad_tree.draw(0)
	_draw_chunks()
			
func _unhandled_key_input(event):
	if event.scancode == KEY_L:
		quad_tree.dump("cool.txt")
		OS.shell_open(ProjectSettings.globalize_path("user://dumps"))
			

func _get_property_list():
	var properties = []
	properties.append({
		"name": "size",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "16,8192"
	})
	return properties

func _get(property):
	match property:
		"size":
			return _size

func _set(property, value):
	match property:
		"size":
			_size = snap_to_nearest_power_of_two(_size, value)
			
			return true

