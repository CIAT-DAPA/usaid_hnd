## Carlos Navarro
## CIAT-CCAFS
## May 2017
## USAID-HND

## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_121')

# Set libraries
# if(!require(XLConnect)){install.packages("XLConnect")}
library(XLConnect)
library(reshape)

#### Read ENEE temperature weather data ####
iDir <- "W:/01_weather_stations/hnd_enee/daily_raw/_primary_files/HMO-CRUDO"
oDir <- "W:/01_weather_stations/hnd_enee/daily_raw"
oDirtx <- "W:/01_weather_stations/hnd_enee/daily_raw/tmax-per-station"
oDirtn <- "W:/01_weather_stations/hnd_enee/daily_raw/tmin-per-station"
stcat <- read.csv("W:/01_weather_stations/hnd_enee/daily_raw/stations_catalog_v2_sel.csv")

# Create output folders
if(!file.exists(oDirtx)){ dir.create(oDirtx, recursive = T) }
if(!file.exists(oDirtn)){ dir.create(oDirtn, recursive = T) }

# Get a list of stations (directories)
stLs <- list.files(iDir)
cat_sel <- c()

for(stName in stLs){
  
  # Get all years from one station
  yrLs <- list.files(paste0(iDir, "/", stName), pattern = "Calculo")
  
  tmin <- c()
  tmax <- c()
  
  for (yrSt in yrLs){
    
    # Read station file in xlsx format
    stFile <- loadWorkbook(paste0(iDir, "/", stName, "/", yrSt))
    yr <- strsplit(tail(strsplit(yrSt, "_")[[1]], n=1), "\\.")[[1]][1]
    nsheets <- length(getSheets(stFile))
    sheet_i <- which(getSheets(stFile) == "CRUDO")
    
    if (length(sheet_i) >= 1){
      
      cat(".> Read Sheet", iconv(stName, to='ASCII//TRANSLIT'), yr , "\n")
      
      xlsF_s <- readWorksheet(stFile, sheet =1, header = FALSE, startRow = 2)
      
      # Remove unnecesary rows 
      xlsF_s <-  xlsF_s[!is.na(xlsF_s[,1]), ]
      xlsF_s <-  xlsF_s[xlsF_s[,2] == yr, ]
      
      stCode <- xlsF_s[1,1]
      
      # Get values
      date <- paste(sprintf("%04d", as.numeric(xlsF_s[,2])), sprintf("%02d", as.numeric(xlsF_s[,3])), sprintf("%02d", as.numeric(xlsF_s[,4])), sep="")
      
      tmin <- rbind(tmin, cbind("Date"=date, "Value"=as.numeric(xlsF_s[,7])))
      tmax <- rbind(tmax, cbind("Date"=date, "Value"=as.numeric(xlsF_s[,24])))
      
      # Reeplace null values
      tmax[which(tmax[,2]=="-1"),2] <- NA
      tmin[which(tmin[,2]=="-1"),2] <- NA
      
      # Remove rows with NAs
      tmax <- tmax[complete.cases(tmax),] 
      tmin <- tmin[complete.cases(tmin),] 
      
    } else {
      
      cat(".> Read Sheet", iconv(stName, to='ASCII//TRANSLIT'), yr , " sheet not found\n")
      
    }
    
  }
  
  # Merge with the catalog
  merge <- stcat[tolower(stcat$Estacion) == tolower(iconv(stName, to='ASCII//TRANSLIT')), ]
  stCodNac <- paste(merge$COD_NAC)
  cat_sel <- rbind(cat_sel, cbind(merge$COD_NAC, toupper(paste(merge$Estacion)), toupper(paste(merge$CUENCA)), merge$GEO_Y, merge$GEO_X, merge$ALTITUD, "tmax"))
  cat_sel <- rbind(cat_sel, cbind(merge$COD_NAC, toupper(paste(merge$Estacion)), toupper(paste(merge$CUENCA)), merge$GEO_Y, merge$GEO_X, merge$ALTITUD, "tmin"))
  
  cat(".> Write Sheet", iconv(stName, to='ASCII//TRANSLIT'), stCodNac,  " tmin \n")
  write.table(tmin, paste0(oDirtn, "/", stCodNac, "_raw_tmin.txt"), quote = F, row.names = F, sep="\t")
  
  cat(".> Write Sheet", iconv(stName, to='ASCII//TRANSLIT'), stCodNac, " tmax \n")
  write.table(tmax, paste0(oDirtx, "/", stCodNac, "_raw_tmax.txt"), quote = F, row.names = F, sep="\t")
  
}

# Append to a exists catalog file 
cat(".> Write catalog file \n")
colnames(cat_sel) <- c("StationNumber", "StationName", "StationWS", "Latitude", "Longitude", "Elevation", "Variable")
write.table(cat_sel, paste0(oDir, "/summary.txt"), quote = F, row.names = F, col.names = F, append=TRUE, sep="\t")


