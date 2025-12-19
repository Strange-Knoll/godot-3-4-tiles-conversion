# Godot TileSet and TileMap conversion for 3x -> 4x
This repo contains a set of plugins for converting TileSet and TileMap data from Godot 3 to Godot 4. In this repo you'll find the following contents -
```
3x Addons
    - TilesExporter
	    - batch_export
	    - tilemap
	    - tileset
4x Addons
	- TilesImporter
		- batch_importer
		- tilemap
		- tileset
```
# Basic Usage
#### Export Process
Copy the TilesExporter folder from the 3x Addons folder into the res://addons folder of your Godot 3 project, then enable the plugin.

**(Recomended) Batch Exports:** In the top menu bar go to "Project -> Tools -> TileMap/TileSet Batch Exporter." Selecting this option will open a dialog showing the files and scene that have been scanned. Once the scan is complete you can chose to "Export in Place" or "Export to Dir".
- *Export in Place:* This will export the TileSet and TileMap data along side the resources / scene files they originated from. (Note: the batch importer for 4x does not currently handle this case)
- *Export to Dir:* This will allow you to select a directory to export the conversion data too. Choosing this option will open a file dialog where you can select the folder you want the conversion data saved to. A "TileSets" and "TileMaps" folder will be created along side an index.json file. The index file is used by the batch importer during the import process. (It is recommended that you export to a folder outside of your project.)

**Individual Exports:** Select either a TileSet resource from your filesystem, or a TileMap node from the scene tree. In the inspector you will see a button at the top labeled "Export TileMap/TileSet". Pressing this button will open a file dialog where you may chose where to save the export data. (It is recommended you name the file, but if you do not the file will be given the name of the resource/node it is exporting.)

You can now close your project in Godot 3

#### Import Process
Remove the TilesExporter plugin from your project. Open Godot 4 and import the Gd3 version of your project. Run the built in converter and open the converted project in Godot 4. Copy the TilesImporter folder from the 4x Addons folder into the res://addons folder of your project, and enable the plugin.

**Individual Exports:** Right click on a TileSet in the filesystem or a TileMap in the Scene Tree. at the bottom of the right click menu you will see an option to "Convert TileSet/TileMap". Pressing this button will open a file dialogue. navigate to the location you exported the conversion data for that node or resource and select that file. This will use the data contained in that file to recreate and replace the old TileSet into a TileSet that matches what Gd4 expects or replace a TileMap with a TileMapLayer.

**Batch Imports:** In the top menu bar go to "Project -> Tools -> TileMap/TileSet Batch Import." Selecting this option will open a file dialog. Navigate to where you exported data to in the Batch Export step, and select the index.json file. A window will popup, this dialog shows the resources and nodes that were indexed and converted. once the conversion is finished you can close this window. 

Now you can examine the TileSets and scenes containing TileMaps to verify the import was successful.

# Limitations & Known Issues
- This project was built around Single Tiles. Conversion of Auto Tiles and Atlases are known to be broken and will cause inaccurate conversions. (Future updates aim to address this issue)
- It is possible that the tile size of a TileMapLayer can be set incorrectly. Adjusting this value should realign the placed tiles in the layer. 
- The export process for TileMaps runs the fix_invalid_tiles() function on each TileMap it exports. This causes tiles to be removed from the node if they are invalid. If this happens it is not likely to cause large amounts of tiles to be removed, you should check your levels for missing tiles.
- The Batch Importer is not properly threaded, and the dialog window hangs until the conversion is finished.
- The progress bars may be bugged and never reach 100% despite the process having in fact completed

# Development
This repo is for release versions of the conversion pipeline. If you are interested in helping develop the tool there exists an official Development Fork of this repo which contains additional documentation, code with expanded comments, print statements for debugging, test environments, and example export data. (Yes, this isn't the typical development pattern, this is done so that the development environment can contain more resources that are not needed by those who just want to use the pipeline.)
