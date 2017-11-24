# -*- coding: utf-8 -*-
# Script to run the Thornthwaite and Mather (tam) water balance model for Western Honduras (USAID project - WPS).
# The model followed here is the compilation of different references enumerated at the end of this routine.

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017

import arcpy
from arcpy import env
from arcpy.sa import *
import os
import csv

arcpy.CheckOutExtension("spatial")
# Let's clean console
os.system("cls")

# Main directories
in_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico"
thornthwaite_and_mather_dir = "thornthwaite_and_mather"
shared_dir = os.path.join(in_dir, "shared")
tam_in_dir = os.path.join(in_dir, thornthwaite_and_mather_dir)
tables_dir = os.path.join(tam_in_dir, 'tables')
out_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Balance_Hidrico"
tam_out_dir = os.path.join(out_dir, thornthwaite_and_mather_dir)
wildcard = "tif"  # Extension of all sets of rasters to be used by the model
prefix_ante_table = '5_last_days_month_'

# Initial variables
years = range(1999, 2014 + 1)  # Years with available weather information to run the water balance
months = range(1, 12 + 1)
weather_vars = {'precipitation': 'prec', 'potential_evap': 'eto', 'runoff': 'runoff', 'effective_prec': 'eprec',
                'actual_evap': 'aet', 'percolation': 'perc', 'soil_storage': 'sstor', 'base_flow': 'bflow',
                'water_yield': 'wyield'}
wettest_month = 9  # User must define the wettest month according to previous analysis
whc = Float(Raster(os.path.join(tam_in_dir, 'whc60.' + wildcard)))  # Raster of Water Holding Capacity = (FC-WP)*600
# CNs adjusted for slope (percent_rise) according to Huang et al.(2006)
cn1 = Float(Raster(os.path.join(tam_in_dir, 'cn1_slp_adj.' + wildcard)))  # Curve Number for Moisture Condition 1
cn2 = Float(Raster(os.path.join(tam_in_dir, 'cn2_slp_adj.' + wildcard)))  # Curve Number for Moisture Condition 2
cn3 = Float(Raster(os.path.join(tam_in_dir, 'cn3_slp_adj.' + wildcard)))  # Curve Number for Moisture Condition 3
kc = Float(Raster(os.path.join(tam_in_dir, 'kc.' + wildcard)))  # Kc values multiplied by 1000
k_dec_apr = Float(Raster(os.path.join(tam_in_dir, 'k_recession1.' + wildcard)))  # Recession constant (k) for Dec-Apr
k_may_nov = Float(Raster(os.path.join(tam_in_dir, 'k_recession2.' + wildcard)))  # Recession constant (k) for May-Nov
b = Float(Raster(os.path.join(tam_in_dir, 'b_runoff.' + wildcard)))
climate_zones = os.path.join(tam_in_dir, 'climate_zones.' + wildcard)
ids_clim_zones = [row[0] for row in arcpy.da.SearchCursor(climate_zones, 'Value')]
zoi = os.path.join(tam_in_dir, 'zoi.shp')  # Zone of Interest: Microwatersheds dissolved for the six states

# Environment variables
env.overwriteOutput = True
env.cellSize = "MINOF"
buffer_zoi = env.scratchGDB + '\\buffer_zoi'
arcpy.Buffer_analysis(zoi, buffer_zoi, '1 Kilometers')
env.mask = buffer_zoi
env.extent = buffer_zoi

# If wettest month is December, the water balance starts in January of next year
if wettest_month == 12:
    years_execution = years[1:]
else:
    years_execution = years


print '\n############################################################'
print '\t\tINITIAL VARIABLES'
print '\tPeriod to be executed: ' + str(years_execution[0]) + '-' + str(years_execution[-1])
print '\tWettest month: ' + str(wettest_month)
print '############################################################'


# Function to create folders if they do not exist
def folders_exist(directories):
    for directory in directories:
        if not os.path.exists(directory):
            os.makedirs(directory)


def read_csv(csv_file):
    with open(csv_file, 'rb') as f:
        reader = csv.reader(f)
        your_list = list(reader)
    return your_list


# Provisional starting values for the water balance model according to Ulmen (2000)
# Initial soil water storage: 90% of water holding capacity
sstor_ant = 0.9*whc
# Base flow of the previous month (mm)
bflow_ant = 10
# Recession constant
# k = 0.5

# Main loop to execute both models
for year in years_execution:

    # Conditions to define the months to be run according to wettest month for tam model
    if year == years[0]:
        months_execution = range(wettest_month + 1, 12 + 1)
    else:
        months_execution = months

    precip_dir = os.path.join(shared_dir, weather_vars['precipitation'], 'projected', str(year))
    eto_dir = os.path.join(shared_dir, weather_vars['potential_evap'], 'projected', str(year))
    five_ante_table = read_csv(os.path.join(tables_dir, prefix_ante_table + str(year) + '.csv'))

    print "\n**Executing THORNTHWAITE AND MATHER model for " + str(year) + "**\n"

    # Create folders for other variables of tam model
    tam_wdir = os.path.join(tam_out_dir, str(year))
    runoff_dir = os.path.join(tam_wdir, weather_vars['runoff'])
    eprec_dir = os.path.join(tam_wdir, weather_vars['effective_prec'])
    sstor_dir = os.path.join(tam_wdir, weather_vars['soil_storage'])
    aet_dir = os.path.join(tam_wdir, weather_vars['actual_evap'])
    perc_dir = os.path.join(tam_wdir, weather_vars['percolation'])
    bflow_dir = os.path.join(tam_wdir, weather_vars['base_flow'])
    wyield_dir = os.path.join(tam_wdir, weather_vars['water_yield'])

    folders_exist([tam_wdir, runoff_dir, eprec_dir, sstor_dir, aet_dir, perc_dir, bflow_dir, wyield_dir])

    # Loop for running tam model monthly
    for month in months_execution:

        print "*Executing water balance for month " + str(month) + "*\n"

        if month == 1:
            pre_year = year - 1
            pre_month = 12
            five_ante_table = read_csv(os.path.join(tables_dir, prefix_ante_table + str(pre_year) + '.csv'))
        else:
            pre_year = year
            pre_month = month - 1

        print "year: " + str(year) + ", month: " + str(month) + ", pre_year: " + str(pre_year) + ", pre_month: " \
              + str(pre_month)

        prec_file = os.path.join(precip_dir,
                                 weather_vars['precipitation'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        prec = Raster(prec_file)
        print "Precipitation is " + prec_file.split("\\")[-1]

        eto_file = os.path.join(eto_dir,
                                weather_vars['potential_evap'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        eto = Raster(eto_file)
        print "Potential evapotranspiration is " + eto_file.split("\\")[-1]

        remap_table = []
        for row in five_ante_table[1:]:
            if int(row[0]) in ids_clim_zones:
                # Values multiplied by 1000 to convert to integer
                remap_table.append([int(row[0]), int(float(row[pre_month])*1000)])

        # Precipitation of 5-last days per month
        # Reclassify function does not allow float values for the new values
        print "\tCalculating precipitation of 5-last days of previous month......"
        penta_raster = Float(Reclassify(climate_zones, 'Value', RemapValue(remap_table), 'NODATA'))/1000

        # Potential maximum retention after runoff begins (inches)
        print "\tCalculating potential maximum retention after runoff begins......"
        samc = Con(penta_raster < 5, (1000 / cn1) - 10,
                   Con((penta_raster >= 5) & (penta_raster <= 55), (1000 / cn2) - 10, (1000 / cn3) - 10))

        print "\tCalculating runoff......"
        # Precipitation in inches
        prec_in = prec/25.4
        runoff_file = os.path.join(runoff_dir,
                                   weather_vars['runoff'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        # runoff_in = Con((-0.095+((0.208*prec_in)/(samc**0.66))) < 0, 0, (-0.095+((0.208*prec_in)/(samc**0.66))))
        runoff_in = Con((-0.095 + ((b * prec_in) / (samc ** 0.66))) < 0, 0, (-0.095 + ((b * prec_in) / (samc ** 0.66))))
        runoff = runoff_in*25.4  # Runoff in mm
        runoff.save(runoff_file)

        print "\tCalculating effective precipitation......"
        eprec_file = os.path.join(eprec_dir,
                                  weather_vars['effective_prec'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        eprec = prec - runoff
        eprec.save(eprec_file)

        print "\tCalculating soil storage......"
        sstor_file = os.path.join(sstor_dir,
                                  weather_vars['soil_storage'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        sstor = Con(eprec > eto, Con(sstor_ant + (eprec - eto) > whc, whc, sstor_ant + (eprec - eto)), sstor_ant * Exp(-((Ln(whc))/((1.1282 * whc)**1.2756))*Abs(eprec - eto)))
        sstor.save(sstor_file)

        print "\tCalculating actual evapotranspiration......"
        aet_file = os.path.join(aet_dir,
                                weather_vars['actual_evap'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        # aet = Con(eprec > eto, eto, eprec + sstor_ant - sstor)
        aet = Con(eprec > eto, eto, eto * (kc/1000))
        aet.save(aet_file)

        print "\tCalculating percolation......"
        perc_file = os.path.join(perc_dir,
                                 weather_vars['percolation'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        perc = Con(eprec > eto, Con(sstor_ant + (eprec - eto) > whc, sstor_ant + (eprec - eto) - whc, 0), 0)
        perc.save(perc_file)

        print "\tCalculating base flow......"
        bflow_file = os.path.join(bflow_dir,
                                  weather_vars['base_flow'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        # Define which k to use depending on season
        if month in [12, 1, 2, 3, 4]:
            k = k_dec_apr
        else:
            k = k_may_nov
        bflow = (k * bflow_ant) + ((1 - k) * perc)
        bflow.save(bflow_file)

        print "\tCalculating water yield......\n"
        wyield_file = os.path.join(wyield_dir,
                                   weather_vars['water_yield'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        wyield = runoff + bflow
        wyield.save(wyield_file)

        # For other months sstor_ant is Si-1
        sstor_ant = sstor
        bflow_ant = bflow

arcpy.CheckInExtension("spatial")

print "\nDONE!!"

#################
#  REFERENCES
#################
#  Main reference for the water balance: Ulmen, C. (2000). Modelling raster-based monthly water balance components for Europe. Koblenz, Germany: Global Data Runoff Centre (GRDC) and Federal Institute of Hydrology (BfG).
#  Approach for adjusting CNs for slopes <> 5%: Huang, M., Gallichand, J., Wang, Z., & Goulet, M. (2006). A modification to the Soil Conservation Service curve number method for steep slopes in the Loess Plateau of China. Hydrological Processes, 20(3), 579–589. http://doi.org/10.1002/hyp.5925
#  Approach for adjusting CNs for slopes <> 5%: Williams, J. R., Kannan, N., Wang, X., Santhi, C., & Arnold, J. G. (2012). Evolution of the SCS Runoff Curve Number Method and Its Application to Continuous Runoff Simulation. Journal of Hydrologic Engineering, 17(11), 1221–1229. http://doi.org/10.1061/(ASCE)HE.1943-5584.0000529
#  Approach for establishing CNs according to 5-day antecedent rainfall: Srinivasan, M. S., & McDowell, R. W. (2007). Hydrological approaches to the delineation of critical-source areas of runoff. New Zealand Journal of Agricultural Research, 50(2), 249–265. http://doi.org/10.1080/00288230709510293
#  Approach for the calculation of runoff: Ferguson, B. K. (1996). Estimation of Direct Runoff in the Thornthwaite Water Balance∗. The Professional Geographer, 48(3), 263–271. http://doi.org/10.1111/j.0033-0124.1996.00263.x
#  Approach for calculation of recession constant: Fish, R. E. (2011). Using water balance models to approximate the effects of climate change on spring catchment discharge: Mt. Hanang, Tanzania (Master’s thesis). Michigan Technological University.
#  Approach for understanding recession constant: Thomas, B. F., Vogel, R. M., Kroll, C. N., & Famiglietti, J. S. (2013). Estimation of the base flow recession constant under human interference. Water Resources Research, 49(11), 7366–7379. http://doi.org/10.1002/wrcr.20532
