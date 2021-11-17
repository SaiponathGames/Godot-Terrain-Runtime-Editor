extends Control


func _process(_delta):
	$Label.text = "FPS: %d\n" % Engine.get_frames_per_second()
	$Label.text += "Static Memory: %s\n" % String().humanize_size(OS.get_static_memory_usage())
	$Label.text += "Dynamic Memory: %s\n" % String().humanize_size(OS.get_dynamic_memory_usage())
	$Label.text += "Position: %s\n" % $"../Tools/TerrainTool".translation
#	var aabb = $"../Tools/TerrainTool".get_transformed_aabb()
#	aabb.position.y -= 50
#	aabb.size.y += 100
#	$Label.text += "Nearby Chunks + Current Chunk: %s" % [$"../Terrain".quad_tree.query(aabb)]
