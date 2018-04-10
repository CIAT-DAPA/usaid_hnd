# -*- coding: utf-8 -*-
# Script to adjust CNs for slopes different from 5% according to Huang et al.(2006)
# This adjustment was carried out by using the slope in percentage (folder "CNs_Slope_Adjusted")
# Before running this routine, it was calculated the CN2 (raw) by executing the tool "Pick" of ArcGIS using the
# Hydrological Soil Groups (HSG, folder "HSG-CN2_Raw") and the CN2s associated to Land Use/Land Cover (folder "CN2_A-D")
# In order to determine the HSG, it was executed the Module Soil Texture Classification in SAGA GIS (http://www.saga-gis.org/saga_tool_doc/2.2.1/grid_analysis_14.html)
# which derives soil texture classes with USDA scheme from sand, silt and clay contents. Having the texture classes (folder "Soil_Texture"),
# then was associated to each texture class the HSG (A, B, C and D) according to SCS (1986) (appendix A).
# A summary of the analysis carried out can be found in the Excel File "Kc_Tabla.xls"

# Author: Jefferson Valencia Gomez
# Email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
# Year: 2017
# Modification from: Fredy Monserrate <f.monserrate@cgiar.org>

# Import system modules
import os
import arcpy
from arcpy import env
from arcpy.sa import *

# Check the Spatial Analyst Extension
arcpy.CheckOutExtension("spatial")
# Overwriting is activated
env.overwriteOutput = True

# Set workspace
env.workspace = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Info_Inputs\Suelos\CNs_Slope_Adjusted"

# Input rasters: cn2_raw and slope (percent_rise)
cn2_raw = Raster(r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Info_Inputs\Suelos\HSG-CN2_Raw\cn2_raw.tif")
slope_p = Raster("slope_p")

# In the case Williams et al. (2012) is applied (NOT used here because of overestimation of CNs)
# print "Calculating retention parameter (s2s) in mm associated with CN2 adjusted for slope....."
# s2s = (254*((100/cn2_raw) - 1))*(1.1 - (slope_p/(slope_p + Exp(3.7 + (0.02117*slope_p)))))

# In the case Williams et al. (2012) is applied
# print "Calculating CN2 according to Williams et al. (2012)....."
# cn2_slp_adj_pre = Float(Con(slope_p == 5, cn2_raw, (100*254)/(s2s + 254)))

# If CN2 is greater than 98, it is adjusted to a maximum value of 98 following the CN2 values of SWAT Crop database
print "Calculating CN2 (average moisture) according to Huang et al.(2006)....."
# Slope has to be in fraction, that is why the 0.01 factor
cn2_slp_adj_pre = cn2_raw*(322.79 + (15.63*slope_p*0.01))/((slope_p*0.01) + 323.52)
cn2_slp_adj = Con(cn2_slp_adj_pre > 98, 98, cn2_slp_adj_pre)
cn2_slp_adj.save(os.path.join(env.workspace, "cn2_slp_adj.tif"))

print "Calculating CN1 (dry - wilting point) according to Williams et al. (2012)....."
cn1_slp_adj = cn2_slp_adj - ((20*(100 - cn2_slp_adj))/(100 - cn2_slp_adj + Exp(2.533 - (0.0636*(100 - cn2_slp_adj)))))
cn1_slp_adj.save(os.path.join(env.workspace, "cn1_slp_adj.tif"))

print "Calculating CN3 (wet - field capacity) according to Williams et al. (2012)....."
cn3_slp_adj = cn2_slp_adj*Exp(0.00673*(100 - cn2_slp_adj))
cn3_slp_adj.save(os.path.join(env.workspace, "cn3_slp_adj.tif"))

# Check in the ArcGIS Spatial Analyst extension license
arcpy.CheckInExtension("spatial")

print "\nDONE!!"

#################
#  REFERENCES
#################

#  Approach for adjusting CNs for slopes <> 5%: Huang, M., Gallichand, J., Wang, Z., & Goulet, M. (2006). A modification to the Soil Conservation Service curve number method for steep slopes in the Loess Plateau of China. Hydrological Processes, 20(3), 579–589. http://doi.org/10.1002/hyp.5925
#  Approach for adjusting CNs for slopes <> 5%: Williams, J. R., Kannan, N., Wang, X., Santhi, C., & Arnold, J. G. (2012). Evolution of the SCS Runoff Curve Number Method and Its Application to Continuous Runoff Simulation. Journal of Hydrologic Engineering, 17(11), 1221–1229. http://doi.org/10.1061/(ASCE)HE.1943-5584.0000529
#  Approach to associate HSG to Soil Texture Classes: U.S. Soil Conservation Service (now called Natural Resources Conservation Service). Department of Agriculture. Technical Release 55: Urban Hydrology for Small Watersheds. June 1986. Available on the web at https://www.nrcs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb1044171.pdf.