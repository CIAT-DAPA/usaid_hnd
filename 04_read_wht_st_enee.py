# ---------------------------------------------------------------------------------------------------------------
# Author: Lizeth Llanos Carlos Navarro
# Date: 2017-03
# ----------------------------------------------------------------------------------------------------------------

import os, sys, string, csv, glob
from csv import writer as csvwriter, reader as cvsreader

#Syntax 
if len(sys.argv) < 4:
	os.system('cls')
	print "\n Too few args"
	print "   - ie: python 04_read_wht_st_enee.py W:\\01_weather_stations\\hnd_enee\\daily_raw\\_primary_files W:\\01_weather_stations\\hnd_enee\\daily_raw summary"
	sys.exit(1)

#Set variables 
dirbase = sys.argv[1]
dirout = sys.argv[2]
summary = sys.argv[3]
if not os.path.exists(dirout):
    os.system('mkdir ' + dirout)

#Clear screen
os.system('cls')

print "\n"
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "     	 Read ENEE daily files			 " 
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "\n"

## List of csv files
stlist = glob.glob(dirbase + "\\*.txt")

for stfile in stlist:

	## Get station code from filename
	stNumber = os.path.basename(stfile).split(".")[0]
	print "Processing", stNumber
	
	if stNumber == "25085":
		
		## Open weather file
		file = open(stfile)
		
		## Loop around lines
		for line in file:
			
			if not line.find("EMPRESA") > -1:
				
				## Read weather info txt plain file
				if line.find("ESTACION:") > -1:
					stName = line.split("\t")[0].split(": ")[-1]
					stWaters = line.split("\t")[5].split(": ")[-1]

				if line.find("CODIGO:") > -1:
					# stNumber = line.split("\t")[5].split(": ")[-1]
					lat = str(int(line.split("\t")[9].split(";")[0].split("-")[0]) + int(line.split("\t")[9].split(";")[0].split("-")[1]) / 60 + int(line.split("\t")[9].split(";")[0].split("-")[2][:2]) / 3600)
					lon = str(int(line.split("\t")[9].split(";")[1].split("-")[0]) + int(line.split("\t")[9].split(";")[1].split("-")[1]) / 60 + int(line.split("\t")[9].split(";")[1].split("-")[2][:2]) / 3600)
						
				if line.find("ELEVACION:") > -1:
					elev = line.split("\t")[9].split(": ")[1].replace("M", "")

				## Define var name
				if line.find("LLUVIA") > -1:
					var = "prec"
					year = line.split("\t")[-1][:-1]
					print line.split("\t")
				# elif line.find("VALORES MEDIOS  DIARIOS DE TEMPERATURA") > -1:
					# var = "tmean"
						
					## Create output folder per variable
					diroutvar = dirout + "\\" + var + "-per-station"
					if not os.path.exists(diroutvar):
						os.system('mkdir ' + diroutvar)

					## Write organized txt weather file
					print stNumber, stName, year, var
					staFile = diroutvar + "\\" + stNumber.lower() + "_raw_" + var + ".txt"
					if not os.path.isfile(staFile):
						wFile = open(staFile, "w")
						wFile.write("Date" + "\t" + "Value" + "\n")
						wFile.close()
					
				## Read and write climate data
				
				if len(line.split("\t")[0]) <= 2 and len(line.split("\t")[0]) > 0:

					for i in range(1, 12 + 1, 1):

						## NA data
						
						if len(line.split("\t")[i]) > 0 or line.split("\t")[i] != "\t\n" or line.split("\t")[i] != "\t"  or line.split("\t")[i] != " ":
							
							## Get date
							if i < 10:
								month = "0" + str(i)
							else:
								month = str(i)
							if int(line.split("\t")[0]) < 10:
								day = "0" + str(line.split("\t")[0])
							else:
								day = str(line.split("\t")[0])
							date = str(year) + str(month) + str(day)
							
							# Get value
							if line.split("\t")[i] == "-" or line.split("\t")[i] == "-\n":
								val = "NA"
							else:
								if i == 12:
									val = line.split("\t")[i][:-1]
								else:
									val = line.split("\t")[i]
							
							if len(val) > 0:
								## Write output file
								wFile = open(staFile, "a")
								wFile.write(date + "\t" + str(val) + "\n")
								wFile.close()
		
		## Write catalog file
		catFile = dirout + "\\" + summary + ".txt"
		infoSta = stNumber + "\t" + stName + "\t" +  stWaters + "\t" + lat + "\t" + lon + "\t" + elev + "\t" + var + "\n"
		
		if not os.path.isfile(catFile):
			cFile = open(catFile, "w")
			cFile.write("StationNumber" + "\t" + "StationName" + "\t" + "StationWS" + "\t" + "Latitude" + "\t" + "Longitude" + "\t" + "Elevation" + "\t" + "Variable" + "\n")
			cFile.write(infoSta)
			cFile.close()
		else:
			cFile = open(catFile, "r")
			lst = cFile.readlines()
			lastline = lst[len(lst)-1]
			if not lastline == infoSta:
				cFile.close()
				cFile = open(catFile, "a")
				cFile.write(infoSta)
				cFile.close()

		## Close input txt file
		file.close()