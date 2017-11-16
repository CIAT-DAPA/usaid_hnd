# Script to move and organize the resulting files of tam model (02_tam_water_balance.py)

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017

import os
import shutil

path = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Outputs\WPS\Balance_Hidrico\thornthwaite_and_mather"
years = range(1999, 2014 + 1)
variables = ["aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield"]


# Function to create folders if they do not exist
def folders_exist(pth, varbs):
    for var in varbs:
        if not os.path.exists(pth + "\\" + str(var)):
            os.makedirs(pth + "\\" + str(var))


def del_folders(pth, varbs):
    for var in varbs:
        if os.path.exists(pth + "\\" + str(var)):
            shutil.rmtree(pth + "\\" + str(var))


folders_exist(path, variables)

for variable in variables:
    folders_exist(path + "\\" + variable, years)
    print "\n\tMoving files of variable " + variable
    for year in years:
        move_from = path + "\\" + str(year) + "\\" + variable + "\\"
        move_to = path + "\\" + variable + "\\" + str(year) + "\\"
        files = os.listdir(move_from)
        files.sort()
        print "Moving files of year " + str(year)
        for f in files:
            src = move_from + f
            dst = move_to + f
            shutil.move(src, dst)

del_folders(path, years)

print "DONE!!!"
