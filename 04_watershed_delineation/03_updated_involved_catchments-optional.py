# -*- coding: utf-8 -*-

"""Script to update the final stream_network file in case the user added to or removed catchments from the final layer: Microcuencas_ZOI_Finales
which was generated with the script 02_involved_catchments.py"""
__author__      = "Jefferson Valencia Gómez"
__email__       = "jefferson.valencia.gomez@gmail.com"

import arcpy
import csv
import os

# Clean console
os.system('cls')

#Main inputs
fc_catchments = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Delimitacion_Cuencas\Microcuencas_ZOI_WPS.gdb\Microcuencas_ZOI_Finales"
in_file = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Delimitacion_Cuencas\stream_network.csv"  # Output file of '01_upstream_catchments.py'
out_csv_file = "stream_network_ZOI_WPS_updated.csv"

id_field = "HydroID"
SQL = ("", "ORDER BY " + id_field)

# Analysis of number of polygons in the ZOI
num_polygons = int(arcpy.GetCount_management(fc_catchments).getOutput(0))
print "Number of catchments to be analyzed is: " + str(num_polygons)

print "Reading areas of final catchments...."
# Read polygon area into dictionary; key = HydroID, value = area_ha
areaDictionary = {}
with arcpy.da.SearchCursor(fc_catchments, [id_field, 'SHAPE@AREA'], "", "", "", SQL) as cursor:
    for row in cursor:
        areaDictionary[int(row[0])] = row[1]/10000
		
print "Reading CSV file...."
# Read input CSV file with ids, parents (path enumeration) and upstream catchments
with open(in_file) as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')
    stream_net_data = [line for line in readCSV]
    header = stream_net_data[0]
    header.append("area_ha_cat")
    header.append("area_ha_upstr_cats")
    final_data = []
    print "Defining upstream areas of catchments...."
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
