### Calculate monthly streamflows of microwatersheds
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

# Network drive
net_drive = "Y:"

scenario = "rcp2.6_2030"
# scenario = "baseline"

all_vars = read.csv(paste0(net_drive, "/06_analysis/Scenarios/", scenario, "/mth_avg_timeline_all_vars.csv"))
str_net = read.csv(paste0(net_drive, "/Outputs/WPS/Delimitacion_Cuencas/stream_network_ZOI_WPS_updated.csv"))
oDir = paste0(net_drive, "/06_analysis/Scenarios/", scenario)
months = 1:12

for (i in 1:length(str_net$id)){

  # Get id of the microwatershed
  id = str_net$id[i]
  cat(paste0("Analyzing catchment ", id, "\n"))
  
  # Get areas in m2
  area_m2 = str_net$area_ha_cat[i]*10000
  # total_area_m2 = area_m2 + (str_net$area_ha_upstr_cats[i])*10000
  upstr_area_m2 = (str_net$area_ha_upstr_cats[i])*10000

  # Get upstream catchments
  upstr_cats = strsplit(as.character(str_net$upstream_catchments[i]), "-")[[1]]
  
  num_columns = length(all_vars[1,])

  if (id %in% all_vars$HydroID){
    # Get row number of the catchment being analyzed
    match_row = which(all_vars$HydroID == id)
    
    # Get streamflow (m3/s) contributed by the catchment being analyzed
    monthly_flow_m3s = (all_vars[match_row, (num_columns-12):(num_columns-1)]/1000)*area_m2/(30.42*86400)
    
    if (upstr_cats[1] == ""){
      all_flows = rep(monthly_flow_m3s, 2)
    }
    else{
      # cats = as.integer(c(id, upstr_cats))
      cats = as.integer(upstr_cats)
      
      # Get rows of catchments involved
      row_cats = all_vars[all_vars$HydroID %in% cats,]
      
      # Average by columns
      avg_cats = apply(row_cats[,(num_columns-12):(num_columns-1)], 2, mean)
      
      # Get streamflow (m3/s) contributed by the upstream drainage area without including the catchment being analyzed
      # monthly_flow_m3s_all = (avg_cats/1000)*total_area_m2/(30.42*86400)
      monthly_flow_m3s_all = (avg_cats/1000)*upstr_area_m2/(30.42*86400)
      
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
# names(flow_data) = c("HydroID", paste0("caudal_mes_", months), paste0("caudal_total_mes_", months))
names(flow_data) = c("HydroID", paste0("caudal_mes_", months), paste0("caudal_agar_mes_", months))

# Change row names
row.names(flow_data) = 1:length(flow_data[,1])

cat("writing csv file....")
# Final file is written as CSV
write.csv(as.matrix(flow_data), paste0(oDir, "/mth_avg_timeline_sflow.csv"), row.names = FALSE)
