## Script to merge catchments (with areas less than 100 ha) to their downstream catchments without affecting the net connectivity. These catchments were created with ArcHydro Tools.
## Author:  Jefferson Valencia Gomez
## E-mail: jefferson.valencia.gomez@gmail.com

import arcpy
from arcpy import env
from arcpy.sa import *
import os

# Clean terminal
os.system('cls')

arcpy.CheckOutExtension("spatial")
arcpy.env.overwriteOutput = True

# File Geodatabase
ws = raw_input("Enter workspace (*.gdb): ")

# Catchment polygons feature class stored on a database, no shapefile allowed
layer = raw_input("Enter layer name (no shapefile allowed): ")

# Output name
out_name = raw_input("Enter name of the output layer: ")

# Create a copy of the input layer
print "Copying layer"
in_layer =  os.path.join(ws, layer)
out_layer = os.path.join(ws, out_name)
inpgs = arcpy.CopyFeatures_management(in_layer, out_layer)

# Read polygon geometry into dictionary; key = HydroID, value = geometry
print "Creating initial dictionary. This process can take long time if the input layer contains many polygons!"
geometryDictionary = {}
polyrows = arcpy.SearchCursor(inpgs)
for prow in polyrows:
    geometryDictionary[prow.HydroID] = prow.Shape
del prow
del polyrows

# Fields to be used into the main functions
fields = ['HydroID', 'NextDownID', 'SHAPE@']
# Change the value below depending on the minimum catchment area to preserve. Default 100 ha = 1000000 m2
where1 = '"' + 'Shape_Area' + '" < 1000000'

# Loop through catchments that will be dissolved
should_restart = True
while should_restart:
	should_restart = False
	# Important to order in ascending way to start always from upstream catchments
	with arcpy.da.SearchCursor(inpgs, fields, sql_clause = (None, 'WHERE ' + where1 + ' ORDER BY ' + fields[0])) as cursor:
		for prow1 in cursor:
			# grd1 = HydroID of the current polygon
			grd1 = prow1[0]		
			# grd2 = HydroID of the polygon downstream
			grd2 = prow1[1]
		
			# If the NextDownID field is different from -1 (coastal catchment)
			if grd2 != -1:
				
				print "######################################################"
				print "Analyzing the catchment with HydroID: " + str(grd1)
				print "######################################################"
			
				geometry1 = prow1[2]
				geometry2 = geometryDictionary[grd2]
				
				print "\tMerging the geometries of the current catchment (HydroID: " + str(grd1) + ") and its downstream catchment (HydroID: " + str(grd2) + ")"
				# Merged geometries
				geometries = geometry1.union(geometry2)
				
				# Query to get upstream catchments of the current one
				where2 = '"' + fields[1] + '" = ' + str(grd1)
				
				# Change the NextDownID of the upstream catchments of the current one in order to drain to the catchment with HydroID = grd2
				polyrows1 = arcpy.UpdateCursor(inpgs, where2)	
				print "\tChanging the NextDownID values of the upstream catchments to be the HydroID (" + str(grd2) + ") of the downstream catchment"				
				for ucat in polyrows1:
					print "\t\tChanging the NextDownID (" + str(ucat.getValue(fields[1])) + ") value of the upstream catchment (HydroID: " + str(ucat.getValue(fields[0])) + ") by " + str(grd2)
					ucat.setValue(fields[1], grd2)
					polyrows1.updateRow(ucat)
				del ucat
				del polyrows1
				
				# Query to get the current catchment 
				where3 = '"' + fields[0] + '" = ' + str(grd1)
				
				# Delete the polygon and row of the current catchment
				polyrows2 = arcpy.UpdateCursor(inpgs, where3)
				for ccat in polyrows2:
					print "\tDeleting the current catchment with HydroID: " + str(grd1)
					polyrows2.deleteRow(ccat)
					# Important to delete the item from the geometry dictionary
					del geometryDictionary[grd1]
				del ccat
				del polyrows2
				
				# Query to get the downstream catchment 
				where4 = '"' + fields[0] + '" = ' + str(grd2)
				
				# Change the geometry of the polygon of the downstream catchment
				polyrows3 = arcpy.UpdateCursor(inpgs, where4)
				for dcat in polyrows3:
					print "\tReplacing the geometry of the downstream catchment (HydroID: " + str(grd2) + ") with the merged geometries\n"			
					dcat.Shape = geometries
					polyrows3.updateRow(dcat)					
					# Important to update the dictionary with the new geometry
					geometryDictionary[grd2] = geometries					
				del dcat
				del polyrows3
				
				del geometry1
				del geometry2
				del geometries
		
				# Restart the for loop and create again the SearchCursor as some rows were updated
				should_restart = True
				break

print "###The resulting layer is saved in " + out_layer + "###"
print "DONE!!"

# Do not forget to then run the ArcGIS tool "Spatial Join" with the following configuration:
# - Target Features: DrainageLine
# - Join Features: Catchment (the resulting feature layer of this script)
# - Join Operation (optional): JOIN_ONE_TO_ONE
# - Keep All Target Features (optional): Checked
# - Field Map of Join Features (optional): Keep all the fields of the "Target Features" and only the "HydroID" field of the "Join Features". Remember to rename the last field as "DrainID2"
# - Match Option (optional): HAVE_THEIR_CENTER_IN