### Calculate streamflow contributed by each polygon and divide it by its area (%)
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

require(rgdal)

# Network drive
net_drive = "V:"

#scenario = "wettest_year"
#scenario = "baseline"
scenario = "rcp8.5_2050"

wyield = read.csv(paste0(net_drive, "/06_analysis/Scenarios/", scenario ,"/mth_avg_timeline_microusos_wyield_filled.csv"))
oDir <- paste0(net_drive, "/06_analysis/Scenarios/", scenario)
mask <- paste0(net_drive, "/06_analysis/Scenarios/mask/Micros_ZOI_Update2020_Usos4_Finales.shp")

months = 1:12
prefix = "mth_avg_timeline_microusos_"

# Read mask and convert it to SpatialPolygonsDataFrame
poly_shp <- readOGR(mask) 

for (i in 1:length(wyield$IDMicroUso)){
  
  # Get id of the polygon
  id = as.character(wyield$IDMicroUso[i])
  cat(paste0("Analyzing polygon ", id, "\n"))
  
  # Get area in m2
  area_m2 = poly_shp$Shape_Area[poly_shp$IDMicroUso == id]
  area_perce = poly_shp$area_perce[poly_shp$IDMicroUso == id]
  
  # Get streamflow (m3/s) contributed by the polygon being analyzed
  monthly_flow_m3s = (wyield[i,-1]/1000)*area_m2/(30.42*86400)
  flow_area_perce = monthly_flow_m3s/area_perce
  
  if (i == 1){
    flow_data = c(id, monthly_flow_m3s)
    flow_area_data = c(id, flow_area_perce)
  }
  else{
    flow_data = rbind(flow_data, c(id, monthly_flow_m3s))
    flow_area_data = rbind(flow_area_data, c(id, flow_area_perce))
  }
}

# Convert to data frame
flow_data = as.data.frame(flow_data)
flow_area_data = as.data.frame(flow_area_data)

# Assign the rigth column names
names(flow_data) = c("IDMicroUso", paste0("caudal_", months))
names(flow_area_data) = c("IDMicroUso", paste0("caudal_area_percen_", months))

row.names(flow_data) = 1:length(flow_data[,1])
row.names(flow_area_data) = 1:length(flow_area_data[,1])

cat("writing csv files....")
# Final file is written as CSV
write.csv(as.matrix(flow_data), paste0(oDir, "/", prefix, "sflow.csv"), row.names = FALSE)
write.csv(as.matrix(flow_area_data), paste0(oDir, "/", prefix, "sflow-area_percen.csv"), row.names = FALSE)