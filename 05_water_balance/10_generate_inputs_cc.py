# -*- coding: utf-8 -*-
# Script to create the inputs for running the water balance with climate change (cc) scenarios based on anomalies

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017

import arcpy
from arcpy import env
from arcpy.sa import *
import os

arcpy.CheckOutExtension("spatial")
# Let's clean console
os.system("cls")

env.overwriteOutput = True
env.cellSize = "MINOF"

years = range(1999, 2014 + 1)  # Years run for the baseline of the water balance
months = range(1, 12 + 1)
anomalies_folder = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\climate_change\anomalies\projected"
variables_folder = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared"
out_folder = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\climate_change\downscaled_ensemble"
proj_folder = "projected"
directories = os.listdir(anomalies_folder)
vars = ["prec", "tmax", "tmin"]


def folder_exists(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)


for scenario in directories:

    print "########################################"
    print "\t\t###Scenario " + scenario + "###"
    print "########################################"

    sce_dir = os.path.join(out_folder, scenario)
    folder_exists(sce_dir)

    for var in vars:

        print "\t#Variable " + var + "#"

        var_dir = os.path.join(sce_dir, var)
        folder_exists(var_dir)

        for year in years:

            year_dir = os.path.join(var_dir, str(year))
            folder_exists(year_dir)

            for month in months:
                print "Year " + str(year) + ", month: " + str(month)

                raster_file = os.path.join(variables_folder, var, proj_folder, str(year), var + "_" + str(year) + "_" + str(month) + ".tif")
                anomalie = os.path.join(anomalies_folder, scenario, var + "_" + str(month) + ".tif")

                # Execute CellStatistics
                print "Executing CellStatistics (SUM)......"
                outCellStatistics = CellStatistics([raster_file, anomalie], "SUM", "NODATA")

                # Save the output
                outCellStatistics.save(os.path.join(year_dir, var + "_" + str(year) + "_" + str(month) + ".tif"))

arcpy.CheckInExtension("spatial")

print "\nDONE!!"
