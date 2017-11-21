## Script to eliminate (merge) single polygons (exploded) with areas less than 1ha to a neighboring polygon with the same HydroID (same microwatershed)
## The layer used for this process is the resulting one of the intersection between "Microcuencas_ZOI_Finales" and "Usos_2014_ZOI_Finales"
## Previous work should have done before executing this script like defining the field "Less_1ha"
## Author:  Jefferson Valencia Gomez
## E-mail: jefferson.valencia.gomez@gmail.com

import arcpy
from arcpy import env
from arcpy.sa import *
import operator

arcpy.CheckOutExtension("spatial")
arcpy.env.overwriteOutput = True

# inpgs = no shapefile allowed
inpgs = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\WPS_datasets.gdb\Microcuencas_ZOI_Usos_Dissolve"

# Create a copy of the input layer
polygons = arcpy.CopyFeatures_management(inpgs, arcpy.env.scratchGDB + "/Microcuencas_ZOI_Usos_Dissolve")

# Read polygon geometry into dictionary; key = OBJECTID, value = geometry
geometryDictionary = {}
hydroidDictionary = {}
polyrows = arcpy.SearchCursor(polygons)
for prow in polyrows:
    geometryDictionary[prow.OBJECTID] = prow.Shape
	hydroidDictionary[prow.OBJECTID] = prow.HydroID
del prow
del polyrows

# Fields to be used into the main functions
fields = ['OBJECTID', 'HydroID', 'SHAPE@']
# Condition of polygons to be analyzed
where1 = "Less_1ha = 'si'"

# Loop through polygons that will be eliminated
should_restart = True
while should_restart:
	should_restart = False
	# Important to order in ascending way
	with arcpy.da.SearchCursor(polygons, fields, sql_clause = (None, 'WHERE ' + where1 + ' ORDER BY ' + fields[0])) as cursor:
		for prow1 in cursor:
			# OBJECTID, HydroID and Geometry of the polygon being analyzed
			oid = prow1[0]
			hydroid = prow1[1]
			geometry = prow1[2]
			
			print "######################################################"
			print "Analyzing the polygon with OBJECTID: " + str(oid)
			print "######################################################"
			
			# Get the neighboring polygons of the analyzed one with the same HydroID (same microwatershed)
			areaDictionary = {}
			for key, value in geometryDictionary.iteritems():
				if geometry.touches(value) and hydroidDictionary[key] == hydroid:
					areaDictionary[key] = value.area
			
			# Get the OBJECTID of the neighboring polygon with the biggest area
			neighPoly = max(areaDictionary.iteritems(), key=operator.itemgetter(1))[0]
			print "\tThe neighboring polygon with the biggest area is : " + str(neighPoly)
			
			# Union of both geometries		
			geometries = geometry.union(geometryDictionary[neighPoly])
				
			# Query to get the current polygon 
			where2 = '"' + fields[0] + '" = ' + str(oid)
			
			# Delete the polygon and row
			polyrows2 = arcpy.UpdateCursor(polygons, where2)
			for poly in polyrows2:
				print "Deleting the current polygon with OBJECTID: " + str(oid)
				polyrows2.deleteRow(poly)
			del poly
			del polyrows2
			
			# Query to get the neighboring polygon
			where3 = '"' + fields[0] + '" = ' + str(neighPoly)
			
			# Change the geometry of the neighboring polygon
			polyrows3 = arcpy.UpdateCursor(polygons, where3)
			print "Replacing the geometry of the neighboring polygon (OBJECTID: " + str(neighPoly) + ") with the merged geometries"			
			for poly2 in polyrows3:
				poly2.Shape = geometries
				polyrows3.updateRow(poly2)					
				# Important to update the dictionary with the new geometry
				geometryDictionary[neighPoly] = geometries					
			del poly2
			del polyrows3
			
			del geometry
			del geometries
	
			# Restart the for loop and create again the SearchCursor as some rows were updated
			should_restart = True
			break

# Do not forget to then run the ArcGIS tool "Spatial Join" with the following configuration:
# - Target Features: DrainageLine
# - Join Features: Catchment (the resulting feature layer of this script)
# - Join Operation (optional): JOIN_ONE_TO_ONE
# - Keep All Target Features (optional): Checked
# - Field Map of Join Features (optional): Keep all the fields of the "Target Features" and only the "HydroID" field of the "Join Features". Remember to rename the last field as "DrainID2"
# - Match Option (optional): HAVE_THEIR_CENTER_IN
