extends Node2D

var json = "res://data/UTM_json2.txt"
var parsed_json

var final_coordinates

var final_faults : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var data = parse_JSON(json)
	
	parsed_json = data
	
	var coordinates = get_coordinates(data)
	
	var coordinates_reduced = reduce_coordinates(coordinates)
	
	var coordinates_sorted = sort_coordinates(coordinates_reduced)

	draw_coordinates(coordinates_sorted)
	
	var polygon_coordinates = generate_polygon_data(coordinates_sorted, parsed_json)
	
	draw_3d_faults(polygon_coordinates)
	
	final_faults = [] # clear all faults - needs to be done somewhere else once out of prototyping
	pass # Replace with function body.


func draw_coordinates(data):
	var line_array = []
	
	for fault in data:
		var line = Line2D.new()
		line.set_width(500)
		
		var fault_id : String
		
		for loc in data[fault]:
			line.add_point(Vector2(loc[0], loc[1]) * Vector2(1,-1))
			fault_id = loc[2]
			pass
		
		for i in range(0, line.get_point_count() - 1):
			var line_area = Area2D.new()
			var line_collider = CollisionShape2D.new()
			var line_shape = SegmentShape2D.new()
			
			line_area.connect("area_entered", self, "_fault_check")
			
			line_shape.set_a(line.get_point_position(i))
			line_shape.set_b(line.get_point_position(i + 1))
			
			line_collider.set_shape(line_shape)
			
			line_area.add_child(line_collider)
			line.add_child(line_area)
			line_area.add_to_group("fault")
			pass
		
		var parent_node = Node.new()
		parent_node.set_name(fault_id)
		
		parent_node.add_child(line)
		$fault_parent.add_child(parent_node)
		line_array.append(line)
		pass
	
	update()
	
	var camera = Camera2D.new()
	add_child(camera)
	camera._set_current(true)
	camera.set_position(Vector2(347834.625, -3780795))
	camera.set_zoom(Vector2(1000,1000))
	pass


func parse_JSON(data):
	var load_file = File.new()
	
	load_file.open(data, File.READ)
	
	var file_text = load_file.get_as_text()
	load_file.close()
	
	var data_parse = JSON.parse(file_text)
	
	var data_parsed = data_parse.result
	
#	print(data_parsed["OpenSHA"]["FaultModel"]["i2"]["ZonePolygon"]["LocationList"]["UTMLocation"])
	
	return data_parsed


func get_coordinates(data):
	var fault_dict : Dictionary = {}
	
	for fault in data["OpenSHA"]["FaultModel"]:
		if fault != "_faultModName":
			for loc in data["OpenSHA"]["FaultModel"][fault]["FaultTrace"]["UTMLocation"]:
				var northing = loc["_Northing"].replace(',', '')
				var easting = loc["_Easting"].replace(',', '')
				var UTMzone = loc["_UTMzone"]
				
				if fault_dict.has(fault):
					fault_dict[fault].append({"northing" : northing, "easting" : easting, "UTMzone" : UTMzone})
				else:
					fault_dict[fault] = []
					fault_dict[fault].append({"northing" : northing, "easting" : easting, "UTMzone" : UTMzone})
			pass
	return fault_dict
	
	
func reduce_coordinates(data):
	#convert dictionary values to combined array 
	var coordinates_reduced = {}
	
	for fault in data:
		for i in range(0, data[fault].size()):
			if data[fault][i]["UTMzone"] == "UTM Zone 11":
				if coordinates_reduced.has(fault):
					var id : String = fault
					var x : float = data[fault][i]["easting"]
					var y : float = data[fault][i]["northing"]
					coordinates_reduced[fault].append([x, y, id])
				else:
					var array : Array = []
					var id : String = fault
					var x : float = data[fault][i]["easting"]
					var y : float = data[fault][i]["northing"]
					
					coordinates_reduced[fault] = array
					
					coordinates_reduced[fault].append([x,y, id])
					pass
				pass
			pass
		pass
	return coordinates_reduced
	
	
func sort_coordinates(data):
	for fault in data:
		data[fault].sort_custom(self, "custom_sort")
		pass
	return data
	
func custom_sort(a, b):
	var origin = Vector2(500000, 0)
	
	var ax : float = a[0]
	var ay : float = a[1]
	var bx : float = b[0]
	var by : float = b[1]
	
	
	var aVector2 : Vector2 = Vector2(ax, ay)
	var bVector2 : Vector2 = Vector2(bx, by)
	
	if aVector2.x < bVector2.x:
		return a > b
	pass
	
func _fault_check(area):
	var areas = []
	var final_areas = []
	
	if !area.is_in_group("fault"):
		areas = area.get_overlapping_areas()
		
	if areas.size() > 0:
		for fault in areas:
			var fault_json_id : String = fault.get_parent().get_parent().get_name()
			if !final_areas.has(fault_json_id):
				if final_faults.has(fault_json_id):
					return
				final_areas.append(fault_json_id)
				pass
			pass
		pass
	
	if final_areas.size() > 0:
		final_faults = final_areas
		get_fault_data(final_faults, parsed_json)
		return
	pass

func get_fault_data(faults, data):
	for fault in faults:
#		print(data["OpenSHA"]["FaultModel"][fault]["_sectionName"])
		pass
	pass
	
	
func generate_polygon_data(coord_data, fault_data):
	var poly_dict : Dictionary = {}
	var temp_dict : Dictionary = {}
	
	for coord in coord_data:
		var fault_id = coord
		var fault_points = coord_data[coord]
		var _section_name : String = fault_data["OpenSHA"]["FaultModel"][fault_id]["_sectionName"]
		var _ave_dip : String  = fault_data["OpenSHA"]["FaultModel"][fault_id]["_aveDip"]
		var _ave_lower_depth : String  = fault_data["OpenSHA"]["FaultModel"][fault_id]["_aveLowerDepth"]
		var _dip_direction : String  = fault_data["OpenSHA"]["FaultModel"][fault_id]["_dipDirection"]
		var polygon_data
		
		polygon_data = calculate_polygon_data(_ave_dip, _ave_lower_depth, _dip_direction, fault_points)
	
		poly_dict[coord] = polygon_data
		pass
		
	return poly_dict
	
func calculate_polygon_data(dip, depth, dip_direction, coords):
	#calculate from the back of the array to the front - this way the coordinates stay in order
	#find what side of the segment the dip is 
	var a = Vector2(coords[0][0], coords[0][1])
	var b = Vector2(coords.back()[0], coords.back()[1])
	
	#calc vector from a to b
	var dvec = (b - a).normalized()
	#rotate dvec 90 degrees
	var normal = Vector2(dvec.y, -dvec.x)
	
	var N = normal
	var D = normal.dot(a)
	
	var dip_dir_angle = rad2deg(N.angle())
	
	var size = coords.size() - 1
	var poly_dict = {}
	#work thru array backwards
	for i in range(0, size):
		var old_coord : Vector3
		var new_coord : Vector3
		
		var x_1 : float = coords[size - i][0]
		var y_1 : float = coords[size - i][1]
		var z_1 : float = 0
		
		var pos1 = "top" + str(i)
		old_coord = Vector3(x_1, y_1, z_1)
		poly_dict[pos1] = old_coord
		
		var x_2 = float(x_1) + float(depth) * cos(dip_dir_angle)
		var y_2 = float(y_1) + float(depth) * sin(dip_dir_angle)
		var z_2 = float(z_1) + float(depth) * tan(deg2rad(float(dip)))
		
		var pos2 = "bot" + str(i)
		new_coord = Vector3(x_2, y_2, z_2)
		poly_dict[pos2] = new_coord
		pass
	
	return poly_dict
	
	
func draw_3d_faults(data):
	for fault in data:
		var fault_3d = ImmediateGeometry.new()
		
		fault_3d.begin(1, null)
		for i in range((data[fault].size() / 2) - 1):
			if i + 1 < data[fault].size() / 2:
				var A = data[fault]["top" + str(i)]
				var B = data[fault]["top" + str(i + 1)]
				fault_3d.add_vertex(A)
				fault_3d.add_vertex(B)
				pass
		for i in range((data[fault].size() / 2) - 1):
			if i + 1 < data[fault].size() / 2:
				var A = data[fault]["bot" + str(i)]
				var B = data[fault]["bot" + str(i + 1)]
				fault_3d.add_vertex(A)
				fault_3d.add_vertex(B)
				pass
		fault_3d.end()
		$"3d_fault_parent".add_child(fault_3d)
		pass
	
	var camera = $"3d_fault_parent/Camera"
	
	$"3d_fault_parent".remove_child(camera)
	$"3d_fault_parent".get_child(0).add_child(camera)
	print($"3d_fault_parent".get_child_count())
	pass