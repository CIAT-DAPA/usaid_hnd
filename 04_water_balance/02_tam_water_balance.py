# Script to run the Thornthwaite and Mather (tam) water balance model for Western Honduras (USAID project - WPS).

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017

import arcpy
from arcpy import env
from arcpy.sa import *
import os
import csv


# Main directories
in_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico"
thornthwaite_and_mather_dir = "thornthwaite_and_mather"
shared_dir = os.path.join(in_dir, "shared")
tam_in_dir = os.path.join(in_dir, thornthwaite_and_mather_dir)
tables_dir = os.path.join(tam_in_dir, 'tables')
out_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Balance_Hidrico"
tam_out_dir = os.path.join(out_dir, thornthwaite_and_mather_dir)
wildcard = "tif"  # Extension of all sets of rasters to be used by swy model
prefix_ante_table = '5_last_days_month_'

# Initial variables
years = range(1990, 2014 + 1)  # Years with available weather information to run the coupled water balance
months = range(1, 12 + 1)
weather_vars = {'precipitation': 'prec', 'potential_evap': 'eto', 'runoff': 'runoff', 'effective_prec': 'eprec',
                'actual_evap': 'aet', 'percolation': 'perc', 'soil_storage': 'sstor'}
wettest_month = 9  # User must define the wettest month according to previous analysis
whc = Raster(os.path.join(tam_in_dir, 'whc60.' + wildcard))  # Raster of Water Holding Capacity = (FC-WP)*600
cn1 = Raster(os.path.join(tam_in_dir, 'cn1.' + wildcard))  # Curve Number for Moisture Condition 1
cn2 = Raster(os.path.join(tam_in_dir, 'cn2.' + wildcard))  # Curve Number for Moisture Condition 2
cn3 = Raster(os.path.join(tam_in_dir, 'cn3.' + wildcard))  # Curve Number for Moisture Condition 3
climate_zones = os.path.join(tam_in_dir, 'climate_zones.' + wildcard)
ids_clim_zones = [row[0] for row in arcpy.da.SearchCursor(climate_zones, 'Value')]
zoi = os.path.join(tam_in_dir, 'zoi.shp')  # Zone of Interest: Microwatersheds dissolved for the six states

# Environment variables
arcpy.CheckOutExtension("spatial")
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

# Let's clean console
os.system("cls")
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


# Defining whc as the initial humidity for the first month (tam model)
sant = whc

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

    folders_exist([tam_wdir, runoff_dir, eprec_dir, sstor_dir, aet_dir, perc_dir])

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

        # Potential maximum retention after runoff begins (mm)
        print "\tCalculating potential maximum retention after runoff begins......"
        samc = Con(penta_raster < 5, 254 * ((100 / cn1) - 1),
                   Con((penta_raster >= 5) & (penta_raster <= 55), 254 * ((100 / cn2) - 1), 254 * ((100 / cn3) - 1)))

        print "\tCalculating runoff......"
        runoff_file = os.path.join(runoff_dir,
                                   weather_vars['runoff'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        runoff = Con((-0.095+((0.208*prec)/samc**0.66)) <= 0, 0, (-0.095+((0.208*prec)/samc**0.66)))
        runoff.save(runoff_file)

        print "\tCalculating effective precipitation......"
        eprec_file = os.path.join(eprec_dir,
                                  weather_vars['effective_prec'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        eprec = prec - runoff
        eprec.save(eprec_file)
        # print "Effective precipitation is " + eprec_file.split("\\")[-1]

        print "\tCalculating soil storage......"
        sstor_file = os.path.join(sstor_dir,
                                  weather_vars['soil_storage'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        sstor = Con(eprec > eto, Con(sant + (eprec - eto) > whc, whc, sant + (eprec - eto)), sant * Exp(-((Ln(whc))/((1.1282 * whc)**1.2756))*Abs(eprec - eto)))
        sstor.save(sstor_file)
        # print "Soil storage is " + sstor_file.split("\\")[-1]

        print "\tCalculating actual evapotranspiration......"
        aet_file = os.path.join(aet_dir,
                                weather_vars['actual_evap'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        aet = Con(eprec > eto, eto, eprec + sant - sstor)
        aet.save(aet_file)
        # print "Actual evapotranspiration is " + aet_file.split("\\")[-1]

        print "\tCalculating percolation......\n"
        perc_file = os.path.join(perc_dir,
                                 weather_vars['percolation'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        perc = Con(eprec > eto, Con(sant + (eprec - eto) > whc, sant + (eprec - eto) - whc, 0), 0)
        perc.save(perc_file)
        # print "Percolation is " + perc_file.split("\\")[-1]

        # For other months sant is Si-1
        sant = sstor

print "\nDONE!!"