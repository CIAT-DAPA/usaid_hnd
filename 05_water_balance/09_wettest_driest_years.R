### Determine the wettest and driest years by microwatershed and get the streamflows and precs for those years
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

# Network drive
net_drive = "Y:"

# Yearly-montly variables
prec = read.csv(paste0(net_drive, "/06_analysis/Extracts_MicroCuencas/mth_yearly_timeline_prec.csv"))
sflow = read.csv(paste0(net_drive, "/06_analysis/Extracts_MicroCuencas/mth_yearly_timeline_sflow.csv"))
oDir = paste0(net_drive, "/06_analysis/Extracts_MicroCuencas")

yi <- "2000"
yf <- "2014"
years = yi:yf
months = 1:12
new_columns =  c("HydroID", "Ano", paste0("caudal_", months), paste0("caudal_agar_", months))
prec_newcols =  c("HydroID", "Ano", paste0("prec_", months))

# Create annual prec by row (microwatershed)
for (year in years){
  columns = paste0("prec_", year, "_", months)
  prec_year = apply(prec[columns], 1, sum)
  
  if (year == years[1]){
    yearly_data = prec_year
  }
  else{
    yearly_data = cbind(yearly_data, prec_year)
  }
}

# Assign colnames according to years
colnames(yearly_data) = years

# Calculate the annual min and max values by row (microwatershed)
min_data = apply(yearly_data, 1, min)
max_data = apply(yearly_data, 1, max)

# Determine what the years are related to those min and max values
for (i in 1:length(prec[,1])){
  
  # Which row we are working with
  id = prec[i, 1]
  
  # Years with the annual min and max values
  min_year = colnames(yearly_data)[yearly_data[i,] == min_data[i]]
  max_year = colnames(yearly_data)[yearly_data[i,] == max_data[i]]
  
  ### STREAMFLOW ###  
  
  # Get the row (HydroID of the microwatershed) from the flow data
  match_row = which(sflow[1] == id)
  # Columns to be extracted
  min_columns = c(paste0("caudal_", min_year, "_", months), paste0("caudal_total_", min_year, "_", months))
  max_columns = c(paste0("caudal_", max_year, "_", months), paste0("caudal_total_", max_year, "_", months))
  # Get the min and max values
  min_values = sflow[match_row, min_columns]
  max_values = sflow[match_row, max_columns]
  
  # Columns to be added 
  columns_to_add_min = cbind(id, min_year, min_values)
  columns_to_add_max = cbind(id, max_year, max_values)
  # Assign of names to avoid problems with differente names of dataframes
  names(columns_to_add_min) = new_columns
  names(columns_to_add_max) = new_columns
  
  
  ### PRECIPITATION ###  
  
  # Get the values for that year
  prec_mincols = paste0("prec_", min_year, "_", months)
  prec_maxcols = paste0("prec_", max_year, "_", months)
  prec_minvs = prec[i, prec_mincols]
  prec_maxvs = prec[i, prec_maxcols]
  prec_mincolstoadd = cbind(id, min_year, prec_minvs)
  prec_maxcolstoadd = cbind(id, max_year, prec_maxvs)
  names(prec_mincolstoadd) = prec_newcols
  names(prec_maxcolstoadd) = prec_newcols
  
  if (i == 1){
    min_dataset = columns_to_add_min
    max_dataset = columns_to_add_max
    
    prec_mindt = prec_mincolstoadd
    prec_maxdt = prec_maxcolstoadd
  }
  else{
    min_dataset = rbind(min_dataset, columns_to_add_min)
    max_dataset = rbind(max_dataset, columns_to_add_max)
    
    prec_mindt = rbind(prec_mindt, prec_mincolstoadd)
    prec_maxdt = rbind(prec_maxdt, prec_maxcolstoadd)
  }
}

write.csv(min_dataset, paste0(oDir, "/driest_year_sflow.csv"), row.names = FALSE)
write.csv(max_dataset, paste0(oDir, "/wettest_year_sflow.csv"), row.names = FALSE)

write.csv(prec_mindt, paste0(oDir, "/driest_year_prec.csv"), row.names = FALSE)
write.csv(prec_maxdt, paste0(oDir, "/wettest_year_prec.csv"), row.names = FALSE)