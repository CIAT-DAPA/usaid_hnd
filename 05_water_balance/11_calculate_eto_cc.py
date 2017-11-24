# Script to calculate ETo (Potential Evapotranspiration) based on the modified Hargreaves' equation (Droogers and Allen, 2002)
# Extraterrestrial Radiation, an input for the ETo calculation, is calculated according to FAO Evapotranspiration document. Specifically equation 21 (pag. 45)
# These calculations are carried out for climate change (cc) scenarios
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
in_folders = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\climate_change\downscaled_ensemble"
scenarios = os.listdir(in_folders)

# Raster with values of latitude in degrees
lat_deg = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\latitude\latitude.tif"

# Years run for the baseline of the water balance
period = range(1999, 2014 + 1)

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

for scenario in scenarios:

    print "########################################"
    print "\t\t###Scenario " + scenario + "###"
    print "########################################"

    eto_dir = os.path.join(in_folders, scenario, "eto")

    for year in period:
        num_dias_year = calculaJulianDay(year, 12, 31)
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

            # Weather variables
            prec = Raster(os.path.join(in_folders, scenario, "prec", str(year), "prec_" + str(year) + "_" + str(month) + ".tif"))
            tmax = Raster(os.path.join(in_folders, scenario, "tmax", str(year), "tmax_" + str(year) + "_" + str(month) + ".tif"))
            tmin = Raster(os.path.join(in_folders, scenario, "tmin", str(year), "tmin_" + str(year) + "_" + str(month) + ".tif"))

            print "\tCalculating Mean Temperature........"
            tav = (tmax + tmin) / 2

            print "\tCalculating Difference Temperature........"
            td = tmax - tmin

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