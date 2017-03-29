# ---------------------------------------------------------------------------------------------------------------
# Author: Lizeth Llanos Carlos Navarro
# Date: 2017-03
# Qbasic | DGRH stations
# ----------------------------------------------------------------------------------------------------------------

import os, sys, string, csv, glob
from csv import writer as csvwriter, reader as cvsreader
import datetime
from shutil import copyfile

#Syntax 
if len(sys.argv) < 3:
	os.system('cls')
	print "\n Too few args"
	print "   - ie: python 05_read_wht_st_dgrh_monthly.py W:\\01_weather_stations\\hnd_dgrh\\monthly_raw\\_primary_files\\qbasic\\error W:\\01_weather_stations\\hnd_dgrh\\monthly_raw"
	sys.exit(1)

#Set variables 
dirbase = sys.argv[1]
dirout = sys.argv[2]
if not os.path.exists(dirout):
    os.system('mkdir ' + dirout)

#Clear screen
os.system('cls')

print "\n"
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "     	 Read DGRH monthly files		 " 
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "\n"

varDc = {1:"tmax", 2:"tmin", 3:"tmean", 6:"rhum", 8:"prec", 9:"evap", 11:"wsmean"} 

## List of csv files
stlist = glob.glob(dirbase + "\\*")

for stfile in stlist:

	if int(os.path.getsize(stfile)) > 3000:

		stNumber = os.path.basename(stfile).split("-")[0]
		
		if stNumber != "a" and stNumber != "c" and stNumber != "h" and stNumber != "CLS" and stNumber != "2014":
		
			catFile = dirout + "\\summary.txt"
			errorFile = dirout + "\\error.txt"
					
			# try: 
			
			## Open weather file
			with open(stfile, 'r') as csvfile:
				file = csv.reader(csvfile)

				# ## Loop around lines
				j = 1
				
				for line in file:
				
					line = ''.join(line)
										
					if not line.find("SECRETARIA") > -1 or not line.find("DIRECCION") > -1 or not line.find("DEPARTAMENTO") > -1:
						
						## Read weather info txt plain file
						if line.find("ESTACION:") > -1:
							# print line.replace(".", "-")
							stName = line.replace(".", "-").replace(" ", "").split("MES:")[0].split(":")[1]
							month = line.replace(".", "-").replace(" ", "").split("MES:")[1].split("-")[0]
							year = line.replace(".", "-").replace(" ", "").split("MES:")[1].split("-")[1]
							
							if not year.find(".") > -1:
							
								if len(year) == 2 :
									if int(year) > 40:
										year = "19" + year
									else:
										year = "20" + year
								
								## Write catalog file
								
								infoSta = stNumber + "\t" + stName + "\t" +  year + "\n"
								
								if not os.path.isfile(catFile):
									cFile = open(catFile, "w")
									cFile.write("StationNumber" + "\t" + "StationName" + "\t" + "Year" + "\n")
									cFile.write(infoSta)
									cFile.close()
								else:
									cFile = open(catFile, "a")
									cFile.write(infoSta)
									cFile.close()

								## Close input txt file
								# file.close()
							
						if 'year' in locals(): 	
											
							if not year.find(".") > -1:
								
								if j == 5:
									print stNumber, stName, year, month
							
								## Read and write climate data
								if len(line[:4].replace(" ", "")) > 0 and len(line[:4].replace(" ", "")) <= 2 and not line.find("\\") > -1 and not line.find("X") > -1 and not line.find("- 1") > -1:
									
									## Get date
									if int(line[:4]) < 10:
										day = "0" + str(int(line[:4]))
									else:
										day = str(int(line[:4]))
									date = str(year) + str(month) + str(day)
									print date
									
									## Get values per variable
									for i in varDc:

										var = varDc[i]
										
										## Create output folder per variable
										diroutvar = dirout + "\\" + var + "-per-station"
										if not os.path.exists(diroutvar):
											os.system('mkdir ' + diroutvar)
										
										## Write organized txt weather file
										staFile = diroutvar + "\\" + stNumber.lower().zfill(3) + "_raw_" + var + ".txt"
										if not os.path.isfile(staFile):
											wFile = open(staFile, "w")
											wFile.write("Date" + "\t" + "Value" + "\n")
											wFile.close()
									
										if len(line[(7*i):7*(i+1)].replace(" ", "")) > 0:
																	
											# Get value
											# if line.split("\t")[i] == "-" or line.split("\t")[i] == "-\n":
												# val = "NA"
											# else:
											if line[(7*(i-1)+4):(7*i+4)].replace(" ", "") == "-1":
												val = "NA"
											else: 
												val = float(line[(7*(i-1)+4):(7*i+4)])
											
											
											## Write output file
											wFile = open(staFile, "a")
											wFile.write(date + "\t" + str(val) + "\n")
											wFile.close()

					j = j + 1
					
			# except:
				# if not os.path.isfile(errorFile):
					# cFile = open(errorFile, "w")
					# cFile.write(stfile + "\n")
					# cFile.close()
				# else:
					# cFile = open(errorFile, "a")
					# cFile.write(stfile + "\n")
					# cFile.close()