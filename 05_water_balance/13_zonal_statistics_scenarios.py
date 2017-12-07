# -*- coding: utf-8 -*-
# Zonal statistical (mean) by microwatershed-land use/land cover
# Use this script only for the output variable "wyield" at montly timescale

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017

import arcpy
import os
import csv
from arcpy import env
from arcpy.sa import *

arcpy.env.overwriteOutput = True

# Check out any necessary licenses
arcpy.CheckOutExtension("Spatial")

# Use 80% of the cores on the machine
env.parallelProcessingFactor = "100%"

# Let's clean console
os.system("cls")

# Input variables
scenario = raw_input("Type scenario: ")
in_folder = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Balance_Hidrico\thornthwaite_and_mather"
out_folder = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\06_analysis\Scenarios"
var = "wyield"
out_file = "mth_avg_timeline_microusos_" + var + ".csv"
months = range(1, 12 + 1)

# Select the shapefile containing the polygons to use as boundaries for zonal statistics
polygons = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\06_analysis\Scenarios\masks\Microcuencas_ZOI_Usos4_Finales.shp"

# Field for the zonal statistics
field = "IDMicroUso"

# Stat. operation
statOperation = "MEAN"

# Select output folder for saving the output - zonal tables (.dbf files)
outDir = env.scratchFolder

final_data = []
for month in months:
    raster = var + "_month_" + str(month) + ".tif"
    print "\t### Processing month " + str(month) + " ###"
    outTable = outDir + "\\" + raster[0:-4] + ".dbf"

    print "Executing ZonalStatisticsAsTable......"
    # Execute ZonalStatisticsAsTable
    ZonalStatisticsAsTable(polygons, field, os.path.join(in_folder, scenario, var, raster), outTable, "DATA", statOperation)

    outTable2 = outDir + "\\" + raster[0:-4] + ".csv"

    print "Saving Table as CSV......"
    # Execute TableToTable
    arcpy.TableToTable_conversion(outTable, outDir, raster[0:-4] + ".csv")

    print "Reading CSV file......\n"
    with open(outTable2) as csvfile:
        readCSV = csv.reader(csvfile, delimiter=',')
        headerCSV = readCSV.next()  # Get and skip header row
        idField = headerCSV.index(field)
        staOpField = headerCSV.index(statOperation)
        if month == 1:
            final_data = [[str(line[idField]), float(line[staOpField])] for line in readCSV]  # Header not included
        else:
            data2 = [line[staOpField] for line in readCSV]  # Header not included
            for i in range(0, len(final_data)):
                final_data[i] = final_data[i] + [float(data2[i])]


vars = [var + "_month_" + str(x) for x in months]			
header = [field] + vars
print "Writing final CSV file......"
with open(os.path.join(out_folder, scenario, out_file), 'wb') as f:
    w = csv.writer(f, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    w.writerow(header)
    w.writerows(final_data)


arcpy.CheckInExtension("Spatial")

print "\nDONE!!!"
