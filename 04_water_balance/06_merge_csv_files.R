path = "Y:/06_Analysis/Extracts_MicroCuencas"
setwd(path)

# List of CVS files with a specific pattern
CSVs = list.files(pattern = "mth_avg", full.names = T)
temp_vars = c("tmax", "tmin", "tmean")

# Loop for merging CVS files
count = 1
for (csv in CSVs){
  
  # Variable to be analized
  var = unlist(strsplit(tail(strsplit(csv, "_")[[1]], 1), "[.]"))[1]

  # Conditions to determine operation
  if (var %in% temp_vars){
    operation = mean
  }
  else{
    operation = sum
  }
  
  # Skip iteration in the case the output file already exists
  if (var == "vars"){
    cat("Next iteration\n")
    next
  }
  
  cat(paste0(var, "\n"))
  
  # Keep the column "zone" only the first time
  if (count == 1){
    csv_table = read.csv(csv)
    csv_table = cbind(csv_table, apply(csv_table[,-1], 1, operation))
    # Calculates the annual average or sum
    names(csv_table) = c(names(csv_table)[1:length(csv_table)-1], paste0(var, "_anual"))
  }
  else{
    file_csv = read.csv(csv)[,-1]
    file_csv = cbind(file_csv, apply(file_csv, 1, operation))
    csv_table = cbind(csv_table, file_csv)
    # Calculates the annual average or sum
    names(csv_table) = c(names(csv_table)[1:length(csv_table)-1], paste0(var, "_anual"))
  }
  
  count = count + 1
}
# Replaces the word "month" for "mes"
names(csv_table) = gsub("month", "mes", names(csv_table))

# Final file is written as CSV
write.csv(csv_table, "mth_avg_timeline_all_vars.csv", row.names = FALSE)