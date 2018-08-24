# -----------------------------------------------------------------------------------------------------
# Author: Carlos Navarro
# Date: September 13th, 2010
# Purpose: Claculate zonal statistics for diseggregated, interpolated, anomalies or downscaled surfaces
# -----------------------------------------------------------------------------------------------------

import arcgisscripting, os, sys, string,glob
gp = arcgisscripting.create(9.3)

#Syntax
if len(sys.argv) < 4:
	os.system('cls')
	print "\n Too few args"
	print "   Syntax	: ZonalStatisticsGCM.py <dirbase> <dirout> <scenario> <resolution> <mask>"
	print "	  - ie: python 08_Zonal_Statistics_GCM_v9_3.py W:\05_downscaling_hnd\downscaled_ens_v2 D:\Workspace\hnd_pnud\downscaling\zonal_statistics W:\03_geodata\microcuencas_spajoin_rg_proj.shp"
	sys.exit(1)

#Set variables
dirbase = sys.argv[1]
dirout = sys.argv[2]
mask = sys.argv[3]

# Clean screen
os.system('cls')

#Check out Spatial Analyst extension license
gp.CheckOutExtension("Spatial")

print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "    Calculate Statistics GCM " 
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


#Get lists of sress and models
rcplist = "rcp26", "rcp45", "rcp85"
periodlist = "2020_2049", "2040_2069", "2070_2099"
varlist = "prec", "tmax", "tmin", "tmean", "rsds", "wsmean"

# Define and create output directory
if not os.path.exists(dirout):
	os.system('mkdir ' + dirout)

# Looping scenarios
for rcp in rcplist:

	# Looping around periods
	for period in periodlist:

		# Set workspace by each model
		gp.workspace = dirbase + "\\" + rcp + "\\" + period
	
		for var in varlist: 
		
			for month in range (1, 12 + 1, 1):
				
				print "\n\t Processing: ", rcp, period, var, str(month) + "\n"
				
				raster = var + "_" + str(month) + ".tif" 
				raster_res = var + "_" + str(month) + "_r"
				
				# Define out table file (dbf extension)
				outDbf = dirout + "\\" + rcp + "_" + period + "_" + var + "_" + str(month) + ".dbf"
				outCsv = dirout + "\\" + rcp + "_" + period + "_" + var + "_" + str(month) + ".csv"
				
				if not gp.Exists(outDbf):
				
					if gp.Exists(raster_res):
						gp.delete_management(raster_res)
					
					# if gp.Exists(outDbf):
						# gp.delete_management(outDbf)
					
					gp.Resample_management(raster,raster_res, "0.00208325 0.00208325","BILINEAR")

					# Zonal statistical function
					gp.ZonalStatisticsAsTable_sa(mask, "ID_MicroCu", gp.workspace + "\\" + raster_res, outDbf, "DATA","MEAN")
					# gp.TableToTable_conversion(outDbf, dirout, rcp + "_" + period + "_" + var + "_" + str(month) + ".csv")
					# os.remove(outDbf)

# # Join dbfs files extracted
# print "\n\t .. Joining outputs"
# dbfList = sorted(glob.glob(dirout + "\\" + "*.dbf"))
# gp.merge_management(dbfList, dirout + '\\'+ 'statistics.dbf')

# for f in dbfList:
	# os.remove(f)
	
# # # Rename join file
# # os.rename(dirout + "\\" + sres + "-" + model + "-" + period + "-bio_1.dbf", outSta)

# Delete Trash
xmlList = sorted(glob.glob(dirout + "\\*.xml"))
for xml in xmlList:
	os.remove(xml)
			
print "\n \t Process done!!"  
