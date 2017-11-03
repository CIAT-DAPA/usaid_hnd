### Calculate streamflows of microwatersheds at yearly-monthly timescale
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

runoff = read.csv("Y:/06_analysis/Extracts_MicroCuencas/mth_yearly_timeline_runoff.csv")
bflow = read.csv("Y:/06_analysis/Extracts_MicroCuencas/mth_yearly_timeline_bflow.csv")
str_net = read.csv("Y:/Outputs/WPS/Delimitacion_Cuencas/stream_network_ZOI_WPS_updated.csv")
oDir = "Y:/06_analysis/Extracts_MicroCuencas"
yi <- "1991"
yf <- "2014"
years = yi:yf
months = 1:12

wyield = cbind(runoff$HydroID, runoff[-1] + bflow[-1])

yr_mth <- expand.grid(months, years)
names(wyield) = c("HydroID", paste0("wyield_", yr_mth[,2], "_", months))

cat("writing wyield file....")
# Final file is written as CSV
write.csv(wyield, paste0(oDir, "/mth_yearly_timeline_wyield.csv"), row.names = FALSE)

for (i in 1:length(str_net$id)){

  # Get id of the microwatershed
  id = str_net$id[i]
  cat(paste0("Analyzing catchment ", id, "\n"))
  
  # Get areas in m2
  area_m2 = str_net$area_ha_cat[i]*10000
  total_area_m2 = area_m2 + (str_net$area_ha_upstr_cats[i])*10000

  # Get upstream catchments
  upstr_cats = strsplit(as.character(str_net$upstream_catchments[i]), "-")[[1]]
  
  if (id %in% wyield$HydroID){
    # Get row number of the catchment being analyzed

    # Get streamflow (m3/s) contributed by the catchment being analyzed
    monthly_flow_m3s = (wyield[-1]/1000)*area_m2/(30.42*86400)
    
    if (upstr_cats[1] == ""){
      all_flows = rep(monthly_flow_m3s, 2)
    }
    else{
      cats = as.integer(c(id, upstr_cats))
      
      #Get rows of catchments involved
      row_cats = wyield[wyield$HydroID %in% cats,]
      
      # Average by columns
      avg_cats = apply(row_cats[-1], 2, mean)
      
      # Get streamflow (m3/s) contributed by the whole drainage area including the catchment being analyzed
      monthly_flow_m3s_all = (avg_cats/1000)*total_area_m2/(30.42*86400)
      
      # Merge both calculations
      all_flows = c(monthly_flow_m3s, monthly_flow_m3s_all)
      
    }
    
    if (i == 1){
      flow_data = c(id, all_flows)
    }
    else{
      flow_data = rbind(flow_data, c(id, all_flows))
    }
  }
}

# Convert to data frame
flow_data = as.data.frame(flow_data)

# Assign the rigth column names
names(flow_data) = c("HydroID", paste0("caudal_", yr_mth[,2], "_", months), paste0("caudal_total_", yr_mth[,2], "_", months))

row.names(flow_data) = 1:length(flow_data[,1])

cat("writing csv file....")
# Final file is written as CSV
write.csv(as.matrix(flow_data), paste0(oDir, "/mth_yearly_timeline_sflow.csv"), row.names = FALSE)
