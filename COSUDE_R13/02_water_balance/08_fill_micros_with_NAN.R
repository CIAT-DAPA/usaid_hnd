### Fill microwatersheds (Islas Cayos Pacifico) with values from others due to their small sizes
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

#scenario = "baseline"
scenario = "rcp8.5_2050"
path = paste0("V:/06_analysis/Scenarios/", scenario)
setwd(path)

# List of CVS files with a specific pattern
CSVs = list.files(pattern = "*.csv")

micro_nans = read.csv("V:/06_analysis/Microwatersheds_withNAN.csv")
in_vars = c("prec", "tmax", "tmean", "tmin", "eto")
out_vars = c("aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield")

# Loop for merging CVS files
for (csv in CSVs){
  
  # Variable to be analized
  var = unlist(strsplit(tail(strsplit(csv, "_")[[1]], 1), "[.]"))[1]
  
  cat(paste0("\nReading csv file ", csv, "....\n"))
  csv_df = read.csv(csv)
  
  if (var %in% in_vars){
    df = micro_nans[c("HydroID","Micro_Asociada_In")]
  }
  else if (var %in% out_vars  || var == "goas"){
    df = micro_nans[c("HydroID","Micro_Asociada_Out")]
  }
  else {
    stop(cat(paste0(var, " is not an allowed variable [ERROR]....\n")))
  }
  
  # Check if there is at least one element of the first list not in the second list
  if (!all((df$HydroID %in% csv_df[,1]))){
    # Get which microwatersheds are not in the CSV file with data
    micros_to_insert = df$HydroID[(df$HydroID %in% csv_df[,1]) == FALSE]
    df_tmp = data.frame(sort(c(micros_to_insert, csv_df[,1])))
    names(df_tmp)[1] = names(csv_df)[1]
    csv_df = merge(x = df_tmp, y = csv_df, by = names(csv_df)[1], all.x = TRUE)
  }
  
  for (i in 1:length(df$HydroID)){
    micro_id = df$HydroID[i]
    micro_to_use = df[i, 2]
    
    cat(paste0("\tReplacing microwatershed ", micro_id, " with ", micro_to_use, "\n"))
    data_to_use = csv_df[csv_df[,1] == micro_to_use,2:ncol(csv_df)]
    csv_df[csv_df[,1] == micro_id,2:ncol(csv_df)] = data_to_use
  }
  
  cat("Writing csv file....\n")
  # Final file is written as CSV
  write.csv(csv_df, paste0(substr(csv,1,nchar(csv)-4), "_filled.csv"), row.names = FALSE)
  
}