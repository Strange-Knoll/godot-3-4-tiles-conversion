# Godot TileMap and TileSet conversion for 3x -> 4x
this project contains a set of scripts which are tools for fixing the conversion of TileMaps and TileSets from 3x to 4x. The process is not entirely automatic, a step by step instruction of how to use these tools is described below

### Whats Inside?
```
3x Addons
	- tilemap_exporter.gd  # this addon exports TileMap data to JSON
	- tilemap_exporter.gd  # this addon exports TileSet data to JSON

4x Addons
	- tilemap_converter  # this addon converts TileMap JSON data into a TileMapLayer 
	- tileset_converter  # this addon converts TileSet JSON data into a TileSet
```

**Step 1 - Setup:** copy the 3x Addons into the Godot-3.x version of your projects res://addons folder, and the 4x Addons into the res://addons folder of the converted Godot-4x version of your project. Create a new folder in the root of your 4.x project named "conversion_dump" ( res://conversion_dump ), this folder is a backup of old TileSet resources after it has been converted

**Step 2 - Exporting TileSets:** 
1. Select a TileSet you want to export.
2. Press the new Export TileSet button at the top of the Inspector Panel
3. A file dialogue will appear, navigate to the location you with to save the exported JSON data, and press save
- If you do not enter a file name into the dialog, the file will be named the same as the resource it is exported from ( MyTileSet.tres -> MyTileSet.json ). Otherwise the JSON file will have the name entered into the dialog

**Step 3 - Exporting TileMaps:**
1. Select a TileMap you want to export.
2. Press the Export TileMap button at the top of the Inspector Panel
3. A file dialogue will appear, navigate to the location you with to save the exported JSON data, and press save
- If you do not enter a file name into the dialog, the file will be named the same as the node it is exported from ( MyTileMap.tres -> MyTileMap.json ). Otherwise the JSON file will have the name entered into the dialog

**Step 4 - Importing TileSets:**
1. Right click on a TileSet resource in the FileSystem. At the bottom of the right click menu you will see an option "Convert TileSet". Select it.
2. A file dialogue will open. Navigate to the folder where you exported your TileSet data from 3x and select the JSON file whose name matches the TileSet resource you right clicked.
This will create a new TileSet resource in place of the old one with its data replaced to support the new 4.x TileSet system. The old TileSet is moved into the conversion_dump folder. 

**Step 5 - Importing TileMaps:**
1. Right click on a TileMap resource in the FileSystem. At the bottom of the right click menu you will see an option "Convert TileMap". Select it.
2. A file dialogue will open. Navigate to the folder where you exported your TileMap data from 3x and select the JSON file whose name matches the TileMap node you right clicked.
This will create a new TileMapLayer node in place of the old one and remove the old TileMap from the tree. 