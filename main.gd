extends Node2D

var json = "res://data/UTM_json.txt"

var final_coordinates

# Called when the node enters the scene tree for the first time.
func _ready():
	var data = parse_JSON(json)
	
	var coordinates = get_coordinates(data)
	
	var coordinates_reduced = reduce_coordinates(coordinates)
	
	var coordinates_sorted = sort_coordinates(coordinates_reduced)

	draw_coordinates(coordinates_sorted)

#	print(coordinates_reduced)
	pass # Replace with function body.


func draw_coordinates(data):
	var line_array = []
	
	for fault in data:
		var line = Line2D.new()
		line.set_width(2500)
		
		for loc in data[fault]:
			line.add_point(Vector2(loc[0], loc[1]) * Vector2(1,-1))
			line_array.append(line)
			pass
			
		self.add_child(line)
		pass
		
	var camera = Camera2D.new()
	add_child(camera)
	camera._set_current(true)
	camera.set_position(Vector2(412914.28, -3860704.37))
	camera.set_zoom(Vector2(1000,1000))
	print(camera.get_position())
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
			if data["OpenSHA"]["FaultModel"][fault].has("ZonePolygon"):
				for loc in data["OpenSHA"]["FaultModel"][fault]["ZonePolygon"]["LocationList"]["UTMLocation"]:
					var northing = loc["_Northing"].replace(',', '')
					var easting = loc["_Easting"].replace(',', '')
					var UTMzone = loc["_UTMzone"]
					
					if fault_dict.has(fault):
						fault_dict[fault].append({"northing" : northing, "easting" : easting, "UTMzone" : UTMzone})
					else:
						fault_dict[fault] = []
						
						fault_dict[fault].append({"northing" : northing, "easting" : easting, "UTMzone" : UTMzone})
			else:
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
					var x : float = data[fault][i]["easting"]
					var y : float = data[fault][i]["northing"]
					coordinates_reduced[fault].append([x, y])
				else:
					var array : Array = []
					var x : float = data[fault][i]["easting"]
					var y : float = data[fault][i]["northing"]
					
					coordinates_reduced[fault] = array
					
					coordinates_reduced[fault].append([x,y])
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
	var origin = Vector2(5000000, 0)
	
	var ax : float = a[0]
	var ay : float = a[1]
	var bx : float = b[0]
	var by : float = b[1]
	
	
	var aVector2 : Vector2 = Vector2(ax, by)
	var bVector2 : Vector2 = Vector2(bx, by)
	
	if aVector2.distance_to(origin) < bVector2.distance_to(origin):
		return a < b
	pass