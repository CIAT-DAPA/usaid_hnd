#---------------------------------------------------------------------------------------------------------
# Description: This script is to prepare the CMIP5 raw climate data, spliting in monthly files. 
# Author: Carlos Navarro
# Date: 25/04/13
# Notes: This python script is to be run under Windows or Linux or with the proper software (cdo) available
# 		 within any of the following folders:
#      	 -/bin/
#      	 -/usr/local/bin/
#      	 -/USERNAME/bin/
# 		 cdo is required to merge raw files, separate years and then months. 
#---------------------------------------------------------------------------------------------------------

# Import system modules
import os, sys, string, glob, shutil

# Syntax
if len(sys.argv) < 2:
	os.system('cls')
	print "\n Too few args"
	print "   - ie: python 00-merge-monthly-raw-data.py T:\gcm\cmip5\ocean"
	sys.exit(1)

# Define arguments
dirbase = sys.argv[1]
# dirout = sys.argv[2]

# Clearing screen and getting the arguments
os.system("cls")

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "   Prepare Monthly CMIP5 raw files    "
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"

var = "zos"
ens = "r1i1p1"

ncList = sorted(glob.glob(dirbase + "\\" + var + "_Omon*.nc"))
if not len(ncList) == 0:
	for nc in ncList:

		nc_name = os.path.basename(nc)
		
		rcp = nc_name.split("_")[3]
		model = nc_name.split("_")[2]
		ens = nc_name.split("_")[4]
			
		print "\tMoving ", rcp, model, ens, "\n"
		
		dirout = dirbase + "\\" +  rcp + "\\" + model + "\\" + ens
		if not os.path.exists(dirout):
			os.system("mkdir " + dirout)
		
		shutil.move(nc, dirout + "\\" + os.path.basename(nc))


pathScript = dirbase
summary = pathScript + "\\cmip5-omon-data-summary.txt"
if not os.path.isfile(summary):
	sumFile = open(summary, "w")
	sumFile.write("rcp" + "\t" + "gcm" + "\t" + "ensemble" + "\t" + "omon" + "\n")
	sumFile.close()
	
# Define variables, rcp's adn ensemble members
rcpList = "historical", "rcp26", "rcp45", "rcp60", "rcp85"

# Reorganize raw data files into a new subfolder 
for rcp in rcpList:
	rcpDir = dirbase + "\\" + rcp

	# Get a list of models
	modelList = sorted(os.listdir(rcpDir))
	for model in modelList:
		
		# Get an ensemble list
		ensList = sorted(os.listdir(rcpDir + "\\" + model))
		for ens in ensList:
			
			if os.path.isdir(rcpDir + "\\" + model + "\\" + ens):
				
				ensDir = rcpDir + "\\" + model + "\\" + ens
				
				# Get a list of nc files per variable
				ncList = sorted(glob.glob(ensDir + "\\" + var + "_Omon*.nc"))

				if not len(ncList) == 0:

					# Extract start and end date
					staYear = os.path.basename(ncList[0]).split("_")[-1].split("-")[0]
					endYear = os.path.basename(ncList[-1]).split("_")[-1].split("-")[1]
					
					# Define merge file by variable
					merNc = ensDir + "\\" + var + "_Omon_" + os.path.basename(ncList[0]).split("_")[2] + "_" + os.path.basename(ncList[0]).split("_")[3] + "_" + os.path.basename(ncList[0]).split("_")[4] + "_" + staYear + "-" + endYear
					
					#### Merge nc files per variable (or rename for raw singles files)
					if len(ncList) > 1:
						print " .> Merge ", rcp, model, ens, var
						
						# Define new folder for original files
						rawDir = ensDir + "\\original-data"
						if not os.path.exists(rawDir):
							os.system("mkdir " + rawDir)
				
						if not os.path.exists(merNc):
							os.system("cdo mergetime " + ' '.join(ncList) + " " + merNc)
							for nc in ncList:
								shutil.move(nc, rawDir + "\\" + os.path.basename(nc))
						
					# else:
						# print " .> Not need merge ", rcp, model, ens, var
						# if not os.path.exists(merNc):
							# shutil.copyfile(ncList[0], merNc)
							
					# Compressing original data
					# for nc in ncList:
						# inZip = rawDir + "\\" + var + ".zip"
						# os.system('7za a ' + inZip + " " + nc)
						# os.remove(nc)

				
					# Move merge file
					# shutil.move(merNc, rawDir + "\\" + os.path.basename(merNc))
			
				# Write check txt file (one per model-ensemble)
				# checkFile = open(checkFile, "w")
				# checkFile.write(str(ncList))
				# checkFile.close()
			
				# print "\tProcess done for ", rcp, model, ens, "\n"
			
			# else:
			
				print "\tProcess done for ", rcp, model, ens, "\n"
				lineCheck = rcp + "\t" + model + "\t" + ens 

				ncList  = sorted(glob.glob(ensDir + "\\" + var + "_Omon_*.nc"))
				if not len(ncList) == 0:
					staYear = os.path.basename(ncList[0]).split("_")[-1].split("-")[0]
					endYear = os.path.basename(ncList[-1]).split("_")[-1].split("-")[1]
					lineCheck = lineCheck + "\t" + str(staYear) + "-" + str(endYear)
				else:
					lineCheck = lineCheck + "\tN/A"
					
				print str(lineCheck)
				sumFile = open(summary, "a")
				sumFile.write(lineCheck + "\n" )
				sumFile.close()
					
print "Process done!"
