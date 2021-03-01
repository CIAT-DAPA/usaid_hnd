# -*- coding: utf-8 -*-

"""Script to find the upstream catchments of each based on the structure.py script (path_enumeration)"""
__author__      = "Jefferson Valencia Gómez"
__email__       = "jefferson.valencia.gomez@gmail.com"

import arcpy
import structure
import os
import csv
import numpy as np
from tempfile import gettempdir


#fc_catchments = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Delimitacion_Cuencas\Delimitaciones_WPS2017.gdb\Delimitaciones\MicroCuencas"`
fc_catchments = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\03_geodata\ZOI_R13.gdb\Micros_ZOI_Incl_Goas_Update2020"

id_field = "HydroID"
parent_field = "NextDownID"
fields = [id_field, parent_field]
SQL = ("", "ORDER BY " + id_field)
path_enum_file_name = "path_enumeration_wps.csv"
out_folder = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\10_outputs\WPS\Delimitacion_Cuencas"
out_file = "stream_network_R13.csv"


# Read both fields and convert them in integer array
data = [[int(row[0]), int(row[1])] for row in arcpy.da.SearchCursor(fc_catchments, fields, "", "", "", SQL)]
# Replace -1 by 1 (Parent = 1 for root catchments (last catchment in a tree) or coastal catchments (NextDownID = -1))
data = [x if x[1] != -1 else [x[0], 1] for x in data]
# Convert list to numpy array
np_data = np.asarray(data)

# Generate the Path Enumeration Model as CSV
structure.path_enumeration(np_data, gettempdir(), path_enum_file_name)

path_enum_file = os.path.join(gettempdir(), path_enum_file_name)

print "**Path Enumeration file is saved in " + path_enum_file + "**"

with open(path_enum_file) as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')

    path_enum_data = [line for line in readCSV]
    header = path_enum_data[0]
    header.append('upstream_catchments')

    dir_data = []

    print "Looping through all the catchments....."
    # Loop to go through all the catchments
    for row in path_enum_data[1:]:
        id = row[0]
        upstream_catchs = ""

        print "\tAnalyzing catchment " + id

        # Loop to find the upstream catchments
        for row2 in path_enum_data[1:]:

            # The path enumeration is split by "/" as comes by default
            if id in row2[1].split("/"):
                upstream_catchs = upstream_catchs + "-" + row2[0]

        # If the analyzed catchment is a head or coastal catchment
        if len(upstream_catchs) == 0:
            upstream_catchs = "-999"

        # Remove the first hyphen (-), if needed
        if upstream_catchs[0] == "-" and upstream_catchs[0:4] != "-999":
            upstream_catchs = upstream_catchs[1:]

        dir_data.append([int(id), row[1], upstream_catchs])

print "Writing final file and saving it in " + out_folder + '/' + out_file
# Copied from structure.py
with open(out_folder + '/' + out_file, 'wb') as f:
    w = csv.writer(f, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    w.writerow(header)
    w.writerows(dir_data)

print "DONE!!!"
