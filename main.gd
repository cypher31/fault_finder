extends Node

var json = "res://data/UTM_json.txt"

# Called when the node enters the scene tree for the first time.
func _ready():
	var data = parse_JSON(json)
	
	var coordinates = get_coordinates(data)
	
	var coordinates_reduced = reduce_coordinates(coordinates)
	
	var coordinates_sorted = sort_coordinates(coordinates_reduced)
	
#	print(coordinates_reduced)
	pass # Replace with function body.


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
					var northing = loc["_Northing"]
					var easting = loc["_Easting"]
					var UTMzone = loc["_UTMzone"]
					
					if fault_dict.has(fault):
						fault_dict[fault].append({"northing" : northing, "easting" : easting, "UTMzone" : UTMzone})
					else:
						fault_dict[fault] = []
						
						fault_dict[fault].append({"northing" : northing, "easting" : easting, "UTMzone" : UTMzone})
			else:
				for loc in data["OpenSHA"]["FaultModel"][fault]["FaultTrace"]["UTMLocation"]:
					var northing = loc["_Northing"]
					var easting = loc["_Easting"]
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
	return
	
func custom_sort(a, b):
	var origin = Vector2(5000000, 0)
	
	var ax : float = a[0]
	
	var aVector2 : Vector2 = Vector2(ax, 0)
	
	print(ax)
#	print(point1, point2)
	pass