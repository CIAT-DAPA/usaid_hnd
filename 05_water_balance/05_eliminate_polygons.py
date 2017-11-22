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
final_layer =  arcpy.env.scratchGDB + "/Microcuencas_ZOI_Usos_Dissolve"
polygons = arcpy.CopyFeatures_management(inpgs, final_layer)

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
			# areaDictionary = {}
			borderDictionary = {}
			for key, value in geometryDictionary.iteritems():
				if geometry.touches(value) and hydroidDictionary[key] == hydroid:
					# areaDictionary[key] = value.area
					# Get the coincident edge between neighboring polygons as a polyline and then store its length
					border = geometry.intersect(value, 2)
					borderDictionary[key] = border.length

			if len(borderDictionary) > 0:
			
				# Get the OBJECTID of the neighboring polygon with the longest coincident edge
				# neighPoly = max(areaDictionary.iteritems(), key=operator.itemgetter(1))[0]
				neighPoly = max(borderDictionary.iteritems(), key=operator.itemgetter(1))[0]
				print "\tThe neighboring polygon with the longest coincident edge is : " + str(neighPoly)
				
				# Union of both geometries
				print "\tMerging both geometries......"			
				geometries = geometry.union(geometryDictionary[neighPoly])
					
				# Query to get the current polygon 
				where2 = '"' + fields[0] + '" = ' + str(oid)
				
				# Delete the polygon and row
				polyrows2 = arcpy.UpdateCursor(polygons, where2)
				for poly in polyrows2:
					print "\tDeleting the current polygon with OBJECTID: " + str(oid)
					polyrows2.deleteRow(poly)
				del poly
				del polyrows2
				
				# Query to get the neighboring polygon
				where3 = '"' + fields[0] + '" = ' + str(neighPoly)
				
				# Change the geometry of the neighboring polygon
				polyrows3 = arcpy.UpdateCursor(polygons, where3)
				print "\tReplacing the geometry of the neighboring polygon (OBJECTID: " + str(neighPoly) + ") with the merged geometries\n"			
				for poly2 in polyrows3:
					poly2.Shape = geometries
					polyrows3.updateRow(poly2)					
					# Important to update the dictionary with the new geometry
					geometryDictionary[neighPoly] = geometries					
				del poly2
				del polyrows3
				
				del borderDictionary
				del border
				del geometry
				del geometries
		
				# Restart the for loop and create again the SearchCursor as some rows were updated
				should_restart = True
				break

print "###The resulting layer is saved in " + final_layer + "###"
print "DONE!!"