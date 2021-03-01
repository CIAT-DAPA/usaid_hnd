# -*- coding: utf-8 -*-
# Zonal statistical (mean) by microwatershed-land use/land cover for the wettest and driest years
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
in_folder = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\10_outputs\WPS\Balance_Hidrico\thornthwaite_and_mather"
iFile = os.path.join(r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\06_analysis\Scenarios", scenario, scenario + "_prec.csv")
out_folder = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\06_analysis\Scenarios"
var = "wyield"
out_file = "mth_avg_timeline_microusos_" + var + ".csv"
months = range(1, 12 + 1)

# Select the layer containing the polygons to use as boundaries for zonal statistics
polygons = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\10_outputs\WPS\WPS_datasets.gdb\R13\Micros_ZOI_Update2020_Usos4_Finales"

# Field for the zonal statistics
field = "IDMicroUso"

# Field for making query and contained on iFile
field_query = "HydroID"

# Field with years
field_ano = "Ano"

# Stat. operation
statOperation = "MEAN"

temp_folder = r"D:\jvalencia\tmp"
if not os.path.exists(os.path.join(temp_folder, scenario, var)):
    os.makedirs(os.path.join(temp_folder, scenario, var))

# Select output folder for saving the intermediary files (.tif, .dbf and .csv)
env.scratchWorkspace = os.path.join(temp_folder, scenario, var)
outDir = env.scratchWorkspace 

dataDic = {}
# Read input csv file
with open(iFile) as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')
    headerCSV = readCSV.next()  # Get and skip header row
    hydroID = headerCSV.index(field_query)
    ano = headerCSV.index(field_ano)
    for row in readCSV:
        dataDic[int(row[hydroID])] = int(row[ano])

# Get unique years
uniqueYears = list(set(dataDic.values()))

# Make a layer from the feature class
arcpy.MakeFeatureLayer_management(polygons, "polygons_lyr")

final_data = []
for year in uniqueYears:
    print "\t\t#### Processing year " + str(year) + " #####"

    # Clean selected features
    arcpy.SelectLayerByAttribute_management("polygons_lyr", "CLEAR_SELECTION")

    for key, value in dataDic.iteritems():
        if value == year:
            query = field_query + " = " + str(key)
            arcpy.SelectLayerByAttribute_management("polygons_lyr", "ADD_TO_SELECTION", query)

    num_polys = int(arcpy.GetCount_management("polygons_lyr").getOutput(0))
    print "Number of polygons to be processed: " + str(num_polys)

    print "Saving polygons as new layer......"
    new_layer = "in_memory\polygons_" + scenario + "_" + str(year)
    arcpy.CopyFeatures_management("polygons_lyr", new_layer)

    monthly_data = []
    for month in months:
        raster = var + "_" + str(year) + "_" + str(month) + ".tif"
        print "\t## Processing month " + str(month) + " ##"
        outTable = outDir + "\\" + raster[0:-4] + ".dbf"

        print "Executing ZonalStatisticsAsTable......"
        # Execute ZonalStatisticsAsTable
        ZonalStatisticsAsTable(new_layer, field, os.path.join(in_folder, "baseline", var, str(year), raster), outTable, "DATA", statOperation)

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
                monthly_data = [[str(line[idField]), float(line[staOpField])] for line in readCSV]  # Header not included
            else:
                data2 = [line[staOpField] for line in readCSV]  # Header not included
                for i in range(0, len(monthly_data)):
                    monthly_data[i] = monthly_data[i] + [float(data2[i])]

    if year == uniqueYears[0]:
        final_data = monthly_data
    else:
        final_data.extend(monthly_data)


vars = [var + "_month_" + str(x) for x in months]
header = [field] + vars
print "Writing final CSV file......"
with open(os.path.join(out_folder, scenario, out_file), 'wb') as f:
    w = csv.writer(f, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    w.writerow(header)
    w.writerows(final_data)


arcpy.CheckInExtension("Spatial")

print "\nDONE!!!"
