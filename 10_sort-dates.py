# ---------------------------------------------------------------------------------------------------------------
# Author: Carlos Navarro
# Date: 4-4-2013
# ----------------------------------------------------------------------------------------------------------------

import os, sys, string, glob

#Syntax 
if len(sys.argv) < 2:
	os.system('cls')
	print "\n Too few args"
	print "   - ie: python 10_sort-dates.py W:\01_weather_stations\hnd_dgrh\daily_raw_org"
	sys.exit(1)

#Set variables 
dirbase = sys.argv[1]

#Clear screen
os.system('cls')

print "\n"
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "     Sort by date ideam daily files		" 
print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
print "\n"

varlist = "evap", "rhum", "sbright", "tmax", "tmean", "tmin", "wsmean", "wsmeand", "wsmax", "wtotal"
# varlist = "evap", "prec", "srad", "sradv", "tmax", "tmin", "wsmean"

# for var in varlist:

	# stlist = sorted(glob.glob(dirbase + "\\" + var + "-per-station" + "\\*.txt"))
	# for st in stlist:
		
		# if os.path.basename(st)[-5:-4] == " ":
			# os.rename(st, st[:-5] + "0.txt")

for var in varlist:

	stlist = sorted(glob.glob(dirbase + "\\" + var + "-per-station" + "\\*.txt"))
	for st in stlist:

		print var, os.path.basename(st)
		
		## Rename weather file
		stproc = dirbase + "\\" + var + "-per-station\\" + os.path.basename(st)
		# os.rename(st, stproc)
		
		# Open renamed file
		stf = open(st,'r')
		lines = stf.readlines()

		## Write sorted weather file
		wFile = open(stproc, "w")
		wFile.write("Date" + "\t" + "Value" + "\n")
		wFile.close()
		wFile = open(stproc, "a")
		for line in sorted(lines)[:-1]:
			wFile.write(line)

		# ## Close files and remove proc File
		# wFile.close()
		stf.close()
		# os.remove(st)

		## Open sorted file
		wFile = open(stproc, "r")
		lines = wFile.readlines()
		
		## Writing start and end date in new txt file
		yFile = dirbase + "\\stations-years.txt"
		if not os.path.exists(yFile):
			yFile = open(yFile,'w')
			yFile.write("St_Number" + "\t" + "Variable" + "\t" + "Start_Date" + "\t" + "End_Date" + "\n")
			yFile.write(os.path.basename(st).split("_")[0] + "\t" + var + "\t" + lines[1].split("\t")[0] + "\t" + lines[-1].split("\t")[0] + "\n")
		else:
			yFile = open(yFile,'a')
			yFile.write(os.path.basename(st).split("_")[0] + "\t" + var + "\t" + lines[1].split("\t")[0] + "\t" + lines[-1].split("\t")[0] + "\n")
		
		## Close files and remove proc File
		wFile.close()
		yFile.close()
		stf.close()
print "Sorted Ideam Stations done!"