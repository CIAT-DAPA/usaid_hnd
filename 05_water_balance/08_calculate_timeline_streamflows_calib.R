### Calculate streamflows contributed by drainage areas of flow stations at yearly-monthly timescale for the calibration process
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

require(rgdal)

# Network drive
net_drive = "Y:"

wyield = read.csv(paste0(net_drive, "/06_analysis/Calibration/Run1/mth_yearly_timeline_wyield.csv"))
oDir <- paste0(net_drive, "/06_analysis/Calibration/Run1")
mask <- paste0(net_drive, "/06_analysis/Calibration/mask/Cuencas_Estaciones_Caudal.shp")
yi <- "2000"
yf <- "2014"
years = yi:yf
months = 1:12

yr_mth <- expand.grid(months, years)

# Read mask and convert it to SpatialPolygonsDataFrame
poly <- readOGR(mask) 

for (i in 1:length(wyield$HydroID)){

  # Get id of the microwatershed
  id = wyield$HydroID[i]
  cat(paste0("Analyzing catchment ", id, "\n"))
  
  # Get areas in m2
  area_m2 = poly$Shape_Area[poly$HydroID == id]

  # Get streamflow (m3/s) contributed by the catchment being analyzed
  monthly_flow_m3s = (wyield[i,-1]/1000)*area_m2/(30.42*86400)

  if (i == 1){
    flow_data = c(id, monthly_flow_m3s)
  }
  else{
    flow_data = rbind(flow_data, c(id, monthly_flow_m3s))
  }
}

# Convert to data frame
flow_data = as.data.frame(flow_data)

# Assign the rigth column names
names(flow_data) = c("HydroID", paste0("caudal_", yr_mth[,2], "_", months))

row.names(flow_data) = 1:length(flow_data[,1])

cat("writing csv file....")
# Final file is written as CSV
write.csv(as.matrix(flow_data), paste0(oDir, "/mth_yearly_timeline_sflow.csv"), row.names = FALSE)
