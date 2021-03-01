# -*- coding: utf-8 -*-
# Zonal statistical (mean) by microwatershed
# Use this script for any input or output variable at yearly-montly timescale

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017
# Modified: 2020

import arcpy
import os, sys
import csv
from arcpy import env
from arcpy.sa import *

env.overwriteOutput = True

# Check out any necessary licenses
arcpy.CheckOutExtension("Spatial")

# Use 80% of the cores on the machine
env.parallelProcessingFactor = "100%"

# Let's clean console
os.system("cls")

# Input scenario
scenario = raw_input('Enter the scenario: ')
scenarios = ["baseline", "rcp2.6_2030", "rcp2.6_2050", "rcp8.5_2030", "rcp8.5_2050"]

if scenario not in scenarios:
	print("The entered scenario is not a right one!")
	sys.exit(0)

# Input variable
var = raw_input("Enter the variable to process: ")
in_vars = ["prec", "tmax", "tmean", "tmin", "eto"]
out_vars = ["aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield"]

if var not in (in_vars + out_vars):
	print("The entered variable is not a right one!")
	sys.exit(0)

if (var in in_vars) and (scenario == "baseline"):	
	in_folder = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared"
if (var in in_vars) and (scenario != "baseline"):
	in_folder = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\climate_change\downscaled_ensemble"
if var in out_vars:
	in_folder = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\10_outputs\WPS\Balance_Hidrico\thornthwaite_and_mather"

out_folder = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\06_analysis\Scenarios"

if var == "wyield":
	out_file = "mth_yearly_timeline_" + var + "_inclu_goas.csv"
	polygons = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\06_analysis\Scenarios\mask\Micros_ZOI_Incl_Goas_Update2020.shp"
else:
	out_file = "mth_yearly_timeline_" + var + ".csv"
	polygons = r"\\dapadfs\workspace_cluster_7\Ecosystem_Services\Water_Planning_System\COSUDE_R13\06_analysis\Scenarios\mask\Micros_ZOI_Update2020.shp"

months = range(1, 12 + 1, 1)
years = range(2000, 2014 + 1, 1)

# Field for the zonal statistics
field = "HydroID"

# Stat. operation
statOperation = "MEAN"

temp_folder = r"D:\jvalencia\tmp"
if not os.path.exists(os.path.join(temp_folder, scenario, var)):
    os.makedirs(os.path.join(temp_folder, scenario, var))

# Select output folder for saving the intermediary files (.tif, .dbf and .csv)
env.scratchWorkspace = os.path.join(temp_folder, scenario, var)
outDir = env.scratchWorkspace 

final_data = []
vars_fields = []
for year in years:
	for month in months:
		vars_fields.append(var + "_" + str(year) + "_" + str(month))
		raster_name = var + "_" + str(year) + "_" + str(month) + ".tif"
		print "\t### Processing year: " + str(year) + ", month: " + str(month) + " ###"
		outTable = outDir + "\\table_" + raster_name[0:-4] + ".dbf"
		
		if (var in in_vars) and (scenario == "baseline"):
			raster = os.path.join(in_folder, var, "projected", str(year), raster_name)
		else:
			raster = os.path.join(in_folder, scenario, var, str(year), raster_name)
		
		if var in in_vars:
			print "Dissagregating for smallest polygons......"
			arcpy.Resample_management(raster, os.path.join(outDir, raster_name), "30 30", "NEAREST")
			raster = os.path.join(outDir, raster_name)

		print "Executing ZonalStatisticsAsTable......"
		# Execute ZonalStatisticsAsTable
		ZonalStatisticsAsTable(polygons, field, raster, outTable, "DATA", statOperation)

		outTable2 = outDir + "\\table_" + raster_name[0:-4] + ".csv"

		print "Saving Table as CSV......"
		# Execute TableToTable
		arcpy.TableToTable_conversion(outTable, outDir, "table_" + raster_name[0:-4] + ".csv")

		print "Reading CSV file......\n"
		with open(outTable2) as csvfile:
			readCSV = csv.reader(csvfile, delimiter=',')
			headerCSV = readCSV.next()  # Get and skip header row
			idField = headerCSV.index(field)
			staOpField = headerCSV.index(statOperation)
			if year == years[0] and month == 1:
				final_data = [[str(line[idField]), float(line[staOpField])] for line in readCSV]  # Header not included
			else:
				data2 = [line[staOpField] for line in readCSV]  # Header not included
				for i in range(0, len(final_data)):
					final_data[i] = final_data[i] + [float(data2[i])]


header = [field] + vars_fields
print "Writing final CSV file......"
with open(os.path.join(out_folder, scenario, out_file), 'wb') as f:
    w = csv.writer(f, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    w.writerow(header)
    w.writerows(final_data)

arcpy.Delete_management(outDir)
arcpy.CheckInExtension("Spatial")

print "\nDONE!!!"
