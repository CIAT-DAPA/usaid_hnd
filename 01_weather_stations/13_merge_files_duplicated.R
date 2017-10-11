## Author: Carlos Navarro
## Date: April 2017
## Purpose: Merge stations with different codes but they are the same based on a table, and then remove duplicates

###############
## For DGHR ###
###############

# Set variables
variables <- c("tmax","tmin","tmean","rhum","evap","wsmean")
rutfinal <- "W:/01_weather_stations/hnd_dgrh/daily_raw_org"

# Load duplicated registry
dup_reg <- "W:/01_weather_stations/duplicated_registry.csv"
dup_reg <- read.csv(dup_reg)


for (var in variables){
  
  for (i in 1:nrow(dup_reg)){
    
    iDir <- paste0(rutfinal, "/", var, "-per-station")
    iFile <- paste0(iDir, "/", sprintf("%03d", dup_reg$qbasic[i]), "_", var, "_raw.txt")
    oFile <- paste0(iDir, "/", dup_reg$code_nal[i], "_raw_", var, ".txt")
    
    cat("Renaming ", sprintf("%03d", dup_reg$qbasic[i]), " -->", dup_reg$code_nal[i], "\n")
    
    # Read and write stations with new code (merge duplicated stations)
    if (file.exists(iFile)){
      if (!file.exists(oFile)){
        write.table(read.table(iFile, header = T), oFile, row.names=F, sep="\t", col.names = T, quote = F)
      } else {
        join <- rbind(read.table(iFile, header = T), read.table(oFile, header = T))
        join_dup_rem <- join[!duplicated(join), ]
        write.table(join_dup_rem, oFile, row.names=F, sep="\t", col.names = T, quote = F)
      }
      
      file.remove(iFile)
      
    }
  }
}

###############
## For NOAA ###
###############

# Set variables
variables <- c("tmax","tmin","prec")
rutfinal <- "W:/01_weather_stations/hnd_noaa/daily_raw"

# Load duplicated registry
dup_reg <- "W:/01_weather_stations/hnd_noaa/duplicated_registry.csv"
dup_reg <- read.csv(dup_reg)


for (var in variables){
  
  oDir <- paste0(rutfinal, "_org/", var, "-per-station") 
  if (!file.exists(oDir)) {dir.create(oDir, recursive = T)}
  
  for (i in 1:nrow(dup_reg)){
    
    iDir <- paste0(rutfinal, "/", var, "-per-station")
    iFile <- paste0(iDir, "/", dup_reg$noaa_code[i], "_raw_", var, ".txt")
    oFile <- paste0(oDir, "/", dup_reg$nal_code[i], "_raw_", var, ".txt")
    
    cat("Renaming ", paste(dup_reg$noaa_code[i]), " -->", paste(dup_reg$nal_code[i]), "\n")
    
    # Read and write stations with new code (merge duplicated stations)
    if (file.exists(iFile)){
      
      iFile_r <- read.table(iFile, header = T)
      if (!file.exists(oFile)){
        write.table(iFile_r, oFile, row.names=F, sep="\t", col.names = T, quote = F)
      } else {
        oFile_r <- read.table(oFile, header = T)
        join <- rbind(iFile_r[complete.cases(iFile_r),], oFile_r[complete.cases(oFile_r),])
        join_dup_rem <- join[!duplicated(join), ]
        write.table(join_dup_rem, oFile, row.names=F, sep="\t", col.names = T, quote = F)
      }
      
    }
  }
}

