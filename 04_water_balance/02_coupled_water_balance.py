# Script to run the coupled water balance for Western Honduras (USAID project - WPS). The Seasonal Water Yield (swy)
# model is used to determine Runoff to then be used as input for the Thornthwaite and Mather (tam) model which
# determines the other variables.

# Note: In order to run the swy model successfully, it's necessary to have folders with only the files (rasters) to be
# used by the model. No *.tfw or *.aux.xml allowed in those folders.

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017

import natcap.invest.seasonal_water_yield.seasonal_water_yield
import arcpy
from arcpy.sa import *
import os
import glob
import logging
import pygeoprocessing

# Get loggers from libraries and format it
MODEL_LOGGER = natcap.invest.seasonal_water_yield.seasonal_water_yield.LOGGER
PYGEO_LOGGER = pygeoprocessing.geoprocessing.LOGGER
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%d/%m/%Y %H:%M:%S')

# Environment variables
arcpy.CheckOutExtension("spatial")
arcpy.env.overwriteOutput = True
arcpy.env.extent = "MINOF"

# Main directories
in_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico"
seasonal_water_yield_dir = "seasonal_water_yield"
thornthwaite_and_mather_dir = "thornthwaite_and_mather"
shared_dir = os.path.join(in_dir, "shared")
swy_in_dir = os.path.join(in_dir, seasonal_water_yield_dir)
tam_in_dir = os.path.join(in_dir, thornthwaite_and_mather_dir)
out_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Balance_Hidrico"
swy_out_dir = os.path.join(out_dir, seasonal_water_yield_dir)
tam_out_dir = os.path.join(out_dir, thornthwaite_and_mather_dir)
wildcard = "tif"  # Extension of all sets of rasters to be used by swy model

# Initial variables
years = range(1990, 2014 + 1)  # Years with available weather information to run the coupled water balance
months = range(1, 12 + 1)
weather_vars = {'precipitation': 'prec', 'potential_evap': 'eto', 'runoff': 'qf', 'effective_prec': 'eprec',
                'actual_evap': 'aet', 'percolation': 'perc', 'soil_storage': 'sstor'}
wettest_month = 9  # User must define the wettest month according to previous analysis
threshold_flow_accumulation = 500  # Accumulation threshold used for definition of stream network

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
print '\tThreshold Flow Accumulation: ' + str(threshold_flow_accumulation)
print '############################################################'

# Initial parameters of Seasonal Water Yield (swy) model
args = {
        u'alpha_m': u'1/12',
        u'aoi_path': os.path.join(swy_in_dir, 'zoi.shp'),
        u'beta_i': u'1.0',
        u'biophysical_table_path': os.path.join(swy_in_dir, 'biophysical_table.csv'),
        u'climate_zone_raster_path': os.path.join(swy_in_dir, 'climate_zones.tif'),
        u'dem_raster_path': os.path.join(swy_in_dir, 'hydro_dem_5.tif'),
        u'gamma': u'1.0',
        u'lulc_raster_path': os.path.join(swy_in_dir, 'lulc.tif'),
        u'monthly_alpha': False,
        u'soil_group_path': os.path.join(swy_in_dir, 'hsg.tif'),
        u'threshold_flow_accumulation': threshold_flow_accumulation,
        u'user_defined_climate_zones': True,
        u'user_defined_local_recharge': False,
        u'rain_events_table_path': u'',
}


# Function to create folders if they do not exist
def folders_exist(directories):
    for directory in directories:
        if not os.path.exists(directory):
            os.makedirs(directory)


def delete_files_no_needed(path):
    os.chdir(path)
    for file in glob.glob("*"):
        ext = ((file.split("\\")[-1]).split(".")[-1]).lower()
        if ext != wildcard.lower():
            os.remove(file)


# Function to define the rain events table to be used by swy model according to a specific year. There is a table
# already generated for each 5-year interval based on the period (years) of weather information
def define_rain_events_table(years2, year2):
    preffix = 'climate_zone_events'
    interval_width = 5  # Change this value depending on how the tables were generated
    num_intervs = int(round((years2[-1] - years2[0] + 1)/interval_width, 0))
    initial_year = years2[0]
    for interval in range(1, num_intervs + 1):
        final_year = initial_year + 4

        if year2 in range(initial_year, final_year + 1):
            return preffix + '_' + str(initial_year) + '-' + str(final_year) + '.csv'

        initial_year = final_year + 1


# Raster of Water Holding Capacity
whc = Raster(os.path.join(tam_in_dir, 'WHC60.asc'))  # = (FC-WP)*600

# Defining whc as the initial humidity for the first month (tam model)
sant = whc

# Main loop to execute both models
for year in years_execution:

    # Define other variables for swy model
    swy_wdir = os.path.join(swy_out_dir, str(year))
    folders_exist([swy_wdir])
    args['workspace_dir'] = swy_wdir
    args['suffix'] = str(year)
    precip_dir = os.path.join(shared_dir, weather_vars['precipitation'], 'projected', str(year))
    eto_dir = os.path.join(shared_dir, weather_vars['potential_evap'], 'projected', str(year))
    delete_files_no_needed(precip_dir)
    delete_files_no_needed(eto_dir)
    args['precip_dir'] = precip_dir
    args['et0_dir'] = eto_dir
    args['climate_zone_table_path'] = os.path.join(swy_in_dir, define_rain_events_table(years, year))

    # Open logfile and set format
    handler = logging.FileHandler(os.path.join(swy_wdir, 'logfile.txt'))
    handler.setFormatter(formatter)

    # Write all SWY log messages to logfile
    MODEL_LOGGER.addHandler(handler)

    # log pygeoprocessing messages to the same logfile
    PYGEO_LOGGER.addHandler(handler)

    print "\n**Executing SEASONAL WATER YIELD model for " + str(year) + "**\n"

    # Run swy model yearly but including the twelve months internally
    natcap.invest.seasonal_water_yield.seasonal_water_yield.execute(args)
    handler.close()

    print "\n**Executing THORNTHWAITE AND MATHER model for " + str(year) + "**\n"

    # Create folders for other variables of tam model
    tam_wdir = os.path.join(tam_out_dir, str(year))
    eprec_dir = os.path.join(tam_wdir, weather_vars['effective_prec'])
    sstor_dir = os.path.join(tam_wdir, weather_vars['soil_storage'])
    aet_dir = os.path.join(tam_wdir, weather_vars['actual_evap'])
    perc_dir = os.path.join(tam_wdir, weather_vars['percolation'])

    folders_exist([tam_wdir, eprec_dir, sstor_dir, aet_dir, perc_dir])

    # Conditions to define the months to be run according to wettest month for tam model
    if year == years[0]:
        months_execution = range(wettest_month + 1, 12 + 1)
    else:
        months_execution = months

    # Loop for running tam model monthly
    for month in months_execution:

        print "*Executing water balance for month " + str(month) + "*\n"

        prec_file = os.path.join(precip_dir,
                                 weather_vars['precipitation'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        prec = Raster(prec_file)
        print "Precipitation is " + prec_file.split("\\")[-1]

        runoff_file = os.path.join(swy_wdir, 'intermediate_outputs',
                                   weather_vars['runoff'] + '_' + str(month) + '.' + wildcard)
        runoff = Raster(runoff_file)
        print "Runoff is " + runoff_file.split("\\")[-1]

        eto_file = os.path.join(eto_dir,
                                weather_vars['potential_evap'] + '_' + str(year) + '_' + str(month) + '.' + wildcard)
        eto = Raster(eto_file)
        print "Potential evapotranspiration is " + eto_file.split("\\")[-1]

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