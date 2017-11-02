# Script to calculate ETo (Potential Evapotranspiration) based on the modified Hargreaves' equation (Droogers and Allen, 2002)
# Extraterrestrial Radiation, an input for the ETo calculation, is calculated according to FAO Evapotranspiration document. Specifically equation 21 (pag. 45)
# Author: Jefferson Valencia Gomez
# Email: jefferson.valencia.gomez@gmail.com

import datetime, arcpy, os, math
from arcpy.sa import *
from calendar import monthrange

arcpy.CheckOutExtension("spatial")
arcpy.env.overwriteOutput = True
arcpy.env.cellSize = "MINOF"

## Inputs
#############################################################################################################################################
# dtr is the difference between mean daily maximum and mean daily minimums (TD)
dtr_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\dtr"

prec_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\prec"
tmean_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\tmean"

# Raster with values of latitude in degrees
lat_deg = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\latitude\latitude.tif"

# Period with available temperature datasets
period = range(1990, 2014 + 1)

months = range(1, 12 + 1)

# Solar constant (MJ*m2*min-1)
gsc = 0.082

# Extraterrestrial Radiation is calculated for the 15th day of each month
day = 15
#############################################################################################################################################


## Outputs
#############################################################################################################################################
eto_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\eto"
ext_rad_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\erad"
#############################################################################################################################################


## Core
#############################################################################################################################################
def calculaJulianDay(y, m, d):
    fmt = '%Y.%m.%d'
    date_txt = str(y) + "." + str(m) + "." + str(d)
    dt = datetime.datetime.strptime(date_txt, fmt)
    tt = dt.timetuple()
    return tt.tm_yday


def folder_exists(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)


lat_rad = Raster(lat_deg) * math.pi / 180

for year in period:
    num_dias_year = calculaJulianDay(year, 12, 31)
    folder_exists(os.path.join(ext_rad_dir, str(year)))
    folder_exists(os.path.join(eto_dir, str(year)))

    for month in months:
        print "Processing year:" + str(year) + ", month:" + str(month)
        julian_day = calculaJulianDay(year, month, day)
        print "\tJulian day: " + str(julian_day)
        dr = 1 + 0.033 * Cos(2 * math.pi * julian_day / num_dias_year)
        solar_decli = 0.409 * Sin((2 * math.pi * julian_day / num_dias_year) - 1.39)
        solar_ang = ACos(-Tan(lat_rad) * Tan(solar_decli))
        print "\tCalculating extraterrestrial radiation........"
        ext_rad = (24 * 60 / math.pi) * gsc * dr * ((solar_ang * Sin(lat_rad) * Sin(solar_decli)) + (Cos(lat_rad) * Cos(solar_decli) * Sin(solar_ang)))
        ext_rad_file = "erad_" + str(year) + "_" + str(month) + ".tif"
        ext_rad.save(os.path.join(ext_rad_dir, str(year), ext_rad_file))

        tav_file = "tmean_" + str(year) + "_" + str(month) + ".asc"
        print "\tMean Temperature file is " + tav_file
        tav = Raster(os.path.join(tmean_dir, str(year), tav_file))

        td_file = "dtr_" + str(year) + "_" + str(month) + ".asc"
        print "\tDifference Temperature file is " + td_file
        td = Raster(os.path.join(dtr_dir, str(year), td_file))

        prec_file = "prec_" + str(year) + "_" + str(month) + ".asc"
        print "\tPrecipitation file is " + prec_file
        prec = Raster(os.path.join(prec_dir, str(year), prec_file))

        print "\tCalculating potential evapotranspiration........"
        # It was necessary to define 0.01 as the minimum value for the math operation (td - 0.0123 * prec) in order to avoid areas with NoData
        eto_daily = 0.0013 * 0.408 * ext_rad * (tav + 17) * Con((td - 0.0123 * prec) <= 0, 0.01**0.76, (td - 0.0123 * prec)**0.76)
        eto_monthly = eto_daily * monthrange(year, month)[1]
        eto_file = "eto_" + str(year) + "_" + str(month) + ".tif"
        eto_monthly.save(os.path.join(eto_dir, str(year), eto_file))

arcpy.CheckInExtension("spatial")
print "DONE!!!"
############################################################################################################################################


## References:
#############################################################################################################################################
# 1. Droogers, P. & Allen, R.G. 2002. "Estimating reference evapotranspiration under inaccurate data conditions." Irrigation and Drainage Systems, vol. 16, Issue 1, February 2002, pp. 33-45
# 2. InVEST source: http://data.naturalcapitalproject.org/nightly-build/invest-users-guide/html/reservoirhydropowerproduction.html
# 3. FAO Evapotranspiration document: http://documentacion.ideam.gov.co/openbiblio/bvirtual/021367/Evapotranspiraciondelcultivo.pdf
#############################################################################################################################################