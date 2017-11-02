# -*- coding: utf-8 -*-

"""Script to find all the catchments involved in a ZOI in order to guarantee complete drainage areas"""
__author__      = "Jefferson Valencia Gómez"
__email__       = "jefferson.valencia.gomez@gmail.com"

import arcpy
import csv
import os
import numpy as np

# Clean console
os.system('cls')

# Permit files overwriting
arcpy.env.overwriteOutput = True

#Main inputs
zoi = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\WPS_datasets.gdb\Delimitaciones_Administrativas_ZOI"
fc_catchments = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Delimitacion_Cuencas\Delimitaciones_WPS2017.gdb\Delimitaciones\MicroCuencas"
in_file = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Delimitacion_Cuencas\stream_network.csv"  # Output file of '01_upstream_catchments.py'
outGDB = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Delimitacion_Cuencas\Microcuencas_ZOI_WPS.gdb"
out_csv_file = "stream_network_ZOI_WPS.csv"

id_field = "HydroID"
parent_field = "NextDownID"
catType_field = "CatType"
SQL = ("", "ORDER BY " + id_field)
spatial_operation = 'INTERSECT'  # Change this depending on what you want to get (e.g. 'HAVE_THEIR_CENTER_IN')
# spatial_operation2 = 'HAVE_THEIR_CENTER_IN'

# Make a feature layer of the catchments
arcpy.MakeFeatureLayer_management(fc_catchments, 'catchments_lyr')
# Select only the catchments that intersect the ZOI
arcpy.SelectLayerByLocation_management('catchments_lyr', spatial_operation, zoi, '#', 'NEW_SELECTION')
# Intersected catchments are saved
arcpy.CopyFeatures_management('catchments_lyr', outGDB + "/Microcuencas_ZOI")
# Read id fields and convert them in integer array
ids = [int(row[0]) for row in arcpy.da.SearchCursor('catchments_lyr', [id_field], "", "", "", SQL)]
print str(len(ids)) + " catchments that intersect the ZOI!"

# Read input CSV file with ids, parents (path enumeration) and upstream catchments
with open(in_file) as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')
    stream_net_data = [line for line in readCSV]
    header = stream_net_data[0]
    involved_cats = []
    downstr_cats = {}
    no_upstr_cats = []

    print "Looping through all the catchments....."
    # Loop to go through all the catchments
    for row in stream_net_data[1:]:

        # Capture the downstream (parent) catchments
        array_roots = row[1].split("/")
        # If the catchment drains to any other
        if len(array_roots) > 2:
            downstr_cats[int(row[0])] = [int(n) for n in array_roots[2:]]
        # If the catchment do not drain to any other
        if len(array_roots) <= 2:
            downstr_cats[int(row[0])] = ["-999"]

        # Identify all upstream catchments of those intersected with ZOI
        if int(row[0]) in ids:
            involved_cats.append(int(row[0]))
            # If the catchment is drained upstream by another one
            if row[2] != "-999":
                involved_cats.extend([int(n) for n in row[2].split("-")])
            if row[2] == "-999":
                no_upstr_cats.append(int(row[0]))

    # Get unique values
    unique_involved_cats = list(set(involved_cats))

print str(len(unique_involved_cats)) + " catchments that apparently are involved in the ZOI!"


# Analysis of number of polygons in the ZOI
num_polygons = int(arcpy.GetCount_management(zoi).getOutput(0))
pol_geometries = []
if num_polygons > 1:
    print "Dissolving ZOI because contains multiple polygons...."
    zoi_dissolve = arcpy.Dissolve_management(zoi, "in_memory\zoi_dissolve")
    pol_geometry = [row[0] for row in arcpy.da.SearchCursor(zoi_dissolve, ["SHAPE@"])][0]
else:
    pol_geometry = [row[0] for row in arcpy.da.SearchCursor(zoi, ["SHAPE@"])][0]


print "Analyzing what the catchments that have their centroid in the ZOI are...."
ids2 = []
spatial_ref = arcpy.Describe(fc_catchments).spatialReference
# Capture id fields of only those catchments with their centroid in the ZOI
for row in arcpy.da.SearchCursor('catchments_lyr', [id_field, "SHAPE@"], "", "", "", SQL):
    # Creates the geometry of the centroid
    centroid = arcpy.Geometry("Point", row[1].centroid, spatial_ref)

    # Two geometries intersect if disjoint returns False
    if not centroid.disjoint(pol_geometry):
        ids2.append(int(row[0]))

np_ids2 = np.array(ids2)
print str(len(ids2)) + " catchments that have their centroid in the ZOI!"


# Clean features selected with INTERSECT method
arcpy.SelectLayerByAttribute_management('catchments_lyr', "CLEAR_SELECTION")


print "Selecting the final catchments...."
for value in unique_involved_cats:
    query = id_field + " = " + str(value)
    arcpy.SelectLayerByAttribute_management('catchments_lyr', "ADD_TO_SELECTION", query)

# Involved catchments are saved
arcpy.CopyFeatures_management('catchments_lyr', outGDB + "/Microcuencas_ZOI_Involucradas")

ids_selected = []
parents_selected = []
catType_selected = []

# Read fields of the pre-final catchments (selected)
with arcpy.da.SearchCursor('catchments_lyr', [id_field, parent_field, catType_field], "", "", "", SQL) as cursor:
    for row in cursor:
        ids_selected.append(int(row[0]))
        parents_selected.append(int(row[1]))
        catType_selected.append(row[2])

print "Removing catchments that should not be considered...."
# Remove the surrounding catchments that do not drain to any other catchment and is not drained by another one
for i, j, k in zip(ids_selected, parents_selected, catType_selected):
    # Convert the resulting downstream (parent) catchments to numpy array
    np_downstr_cats = np.array(downstr_cats[i])

    # First case - catchments that: are not coastal, with no upstream and downstream catchments, and are drainage catchments
    # Second case - catchments that: do not have their centroid in the ZOI and none of their downstream cathchments have their centroid in the ZOI
    # Third case - catchments that: have their centroid in the ZOI, do not have upstream catchments, none of their downstream cathchments have their centroid in the ZOI and are not coastal
    if (j != -1 and j not in ids_selected and i not in parents_selected and k == "Drenaje") or (i not in ids2 and not np.any(np.in1d(np_downstr_cats, np_ids2))) or (i in ids2 and i in no_upstr_cats and not np.any(np.in1d(np_downstr_cats, np_ids2)) and j != -1):
        query = id_field + " = " + str(i)
        arcpy.SelectLayerByAttribute_management('catchments_lyr', "REMOVE_FROM_SELECTION", query)

num_final_cats = int(arcpy.GetCount_management('catchments_lyr').getOutput(0))

print str(num_final_cats) + " catchments that meet all the criteria!"

print "Saving the final catchments...."
final_cats = arcpy.CopyFeatures_management('catchments_lyr', outGDB + "/Microcuencas_ZOI_Preliminares")

print "Reading areas of final catchments...."
# Read polygon area into dictionary; key = HydroID, value = area_ha
areaDictionary = {}
with arcpy.da.SearchCursor(final_cats, [id_field, 'SHAPE@AREA'], "", "", "", SQL) as cursor:
    for row in cursor:
        areaDictionary[int(row[0])] = row[1]/10000

print "Defining upstream areas of catchments...."
final_data = []
header.append("area_ha_cat")
header.append("area_ha_upstr_cats")
# Loop to go through all the catchments
for row in stream_net_data[1:]:
    id = int(row[0])
    if id in areaDictionary.keys():
        area_cat = areaDictionary[id]
        if row[2] == "-999":
            new_row = [id, row[1], row[2], area_cat, 0]
        else:
            areas_cat = 0
            for n in row[2].split("-"):
                areas_cat = areas_cat + areaDictionary[int(n)]
            new_row = [id, row[1], row[2], area_cat, areas_cat]

        final_data.append(new_row)

out_folder = os.path.dirname(in_file)

print "Writing final file and saving it in " + out_folder + '/' + out_csv_file
# Copied from structure.py
with open(out_folder + '/' + out_csv_file, 'wb') as f:
    w = csv.writer(f, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    w.writerow(header)
    w.writerows(final_data)


print "DONE!!!"
