# This script averages/sums the monthly water balance variables into multiannual monthly variables

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017

import os
import fnmatch
import glob
import arcpy
from arcpy import env
from arcpy.sa import *

arcpy.CheckOutExtension("spatial")
env.overwriteOutput = True

# Clean terminal
os.system('cls')

# Input parameters
wd = raw_input("Enter the path of the variable to be precessed: ")
rangeYears = raw_input("Type the interval of years to process (e.g. '2000-2014') or just press Enter to take the "
                       "interval by default: ")
variable = int(raw_input("Type 0: 'prec', 1: 'tmax', 2: 'tmin', 3: 'tmean', 4: 'eto', 5: 'runoff', 6: 'eprec', "
                         "7: 'aet', 8: 'perc', 9: 'sstor', 10: 'bflow', 11: 'wyield' :"))

# Options of variables
weather_vars = {0: 'prec', 1: 'tmax', 2: 'tmin', 3: 'tmean', 4: 'eto', 5: 'runoff', 6: 'eprec', 7: 'aet', 8: 'perc',
                9: 'sstor', 10: "bflow", 11: 'wyield'}

# Variable to be processed
working_var = weather_vars[variable]

if rangeYears == "":
    # If blank, it is set the default interval
    # Statistics start one year later because of warm-up year
    finalRange = range(1999 + 1, 2014 + 1)
else:
    splitRange = rangeYears.split("-")
    finalRange = range(int(splitRange[0]), int(splitRange[1]) + 1)


def average_monthly(folder, wv, fr):
    print ""
    print "************************************************************************"
    print "         Averaging " + working_var + " datasets"
    print "************************************************************************"
    print ""

    for month in range(1, 12 + 1):
        print "\tMonth " + str(month)
        out_raster = folder + "\\" + wv + "_month_" + str(month) + ".tif"
        rasters = []
        for root, dirnames, filenames in os.walk(folder):
            for year in fr:
                for filename in fnmatch.filter(filenames, wv + "_" + str(year) + "_" + str(month) + ".tif"):
                    rasters.append(os.path.join(root, filename))
        print rasters
        out_cell_statistics = CellStatistics(rasters, "MEAN", "DATA")
        out_cell_statistics.save(out_raster)


def generate_annual(folder, wv, fr):
    print ""
    print "************************************************************************"
    print "         Generating " + working_var + " datasets"
    print "************************************************************************"
    print ""

    # Different math operation for temperatures
    if wv[0] == 't':
        operation = "MEAN"
    else:
        operation = "SUM"

    for year in fr:
        print "\tYear " + str(year)
        out_raster = folder + "\\" + str(year) + "\\" + wv + "_year_" + str(year) + ".tif"
        rasters = glob.glob(folder + "\\" + str(year) + "\\" + wv + "_" + str(year) + "_*.tif")
        print rasters
        out_cell_statistics = CellStatistics(rasters, operation, "DATA")
        out_cell_statistics.save(out_raster)


def average_annual(folder, wv, fr):
    print ""
    print "************************************************************************"
    print "         Averaging " + working_var + " datasets"
    print "************************************************************************"
    print ""

    out_raster = folder + "\\" + wv + "_annual.tif"
    rasters = []
    for root, dirnames, filenames in os.walk(folder):
        for year in fr:
            for filename in fnmatch.filter(filenames, wv + "_year_" + str(year) + ".tif"):
                rasters.append(os.path.join(root, filename))
    print rasters
    out_cell_statistics = CellStatistics(rasters, "MEAN", "DATA")
    out_cell_statistics.save(out_raster)

###########################################################

average_monthly(wd, working_var, finalRange)
generate_annual(wd, working_var, finalRange)
average_annual(wd, working_var, finalRange)

print "DONE!!!"
