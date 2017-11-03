### Merge CSV files resulting of the script "05_zonal_statistics.R", calculate water yield (wyield) and summarize variables on annual basis
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

path = "Y:/06_Analysis/Extracts_MicroCuencas"
setwd(path)

# List of CVS files with a specific pattern
CSVs = list.files(pattern = "mth_avg", full.names = T)
temp_vars = c("tmax", "tmin", "tmean")

months = 1:12

# Loop for merging CVS files
count = 1
for (csv in CSVs){
  
  # Variable to be analized
  var = unlist(strsplit(tail(strsplit(csv, "_")[[1]], 1), "[.]"))[1]

  # Conditions to determine operation
  if (var %in% temp_vars){operation = mean}
  else{operation = sum}
  
  # Skip iteration in the case the output file already exists
  if (var == "vars" || var == "sflow" || var == "wyield"){
    cat("Next iteration\n")
    next
  }
  
  cat(paste0(var, "\n"))
  
  # Keep the column "zone" only the first time
  if (count == 1){
    csv_table = read.csv(csv)
    
    if (var == "bflow"){bf = csv_table[,-1]}
    if (var == "runoff"){ro = csv_table[,-1]}
    
    csv_table = cbind(csv_table, apply(csv_table[,-1], 1, operation))
    # Calculates the annual average or sum
    names(csv_table) = c(names(csv_table)[1:length(csv_table)-1], paste0(var, "_anual"))
  }
  else{
    file_csv = read.csv(csv)[,-1]
    
    if (var == "bflow"){bf = file_csv}
    if (var == "runoff"){ro = file_csv}
    
    file_csv = cbind(file_csv, apply(file_csv, 1, operation))
    csv_table = cbind(csv_table, file_csv)
    # Calculates the annual average or sum
    names(csv_table) = c(names(csv_table)[1:length(csv_table)-1], paste0(var, "_anual"))
  }
  
  count = count + 1
}


cat("wyield\n")
# Calculates wyield based on bflow and runoff
if (exists("bf") & exists("ro")){
  for (i in months){
    sum_data = c(bf[,i] + ro[,i])
    if (i == 1){
      wyield = sum_data
    }
    else{
      wyield = cbind(wyield, sum_data)
    }
  }
  wyield_anual = apply(wyield, 1, sum)
  wyield = cbind(wyield, wyield_anual)
  num_names = length(csv_table)
  csv_table = cbind(csv_table, wyield)
  names(csv_table) = c(names(csv_table)[1:num_names], paste0("wyield_mes_", months), names(csv_table)[length(csv_table)])
}

cat("writing wyield file....")
# Final file is written as CSV
write.csv(csv_table[,c(1,(length(csv_table)-12):(length(csv_table)-1))], "mth_avg_timeline_wyield.csv", row.names = FALSE)

# Replaces the word "zone" for "HydroID"
names(csv_table)[1] = "HydroID"

# Replaces the word "month" for "mes"
names(csv_table) = gsub("month", "mes", names(csv_table))

cat("writing csv file....")
# Final file is written as CSV
write.csv(csv_table, "mth_avg_timeline_all_vars.csv", row.names = FALSE)