## Authors: Lizeth Llanos l.llanos@cgiar.org / Carlos Navarro
## CIAT-CCAFS
## April 2018
## USAID-HND

## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_161')


#### Read COPECO-SERNA weather data ####

# Precipitation

iDir <- "W:/01_weather_stations/hnd_copeco/daily_raw/_primary_files/Precipitacion Diaria"
xlsF <- "Precipitaciones.xlsx"
oDir <- "W:/01_weather_stations/hnd_copeco/daily_raw"

readCOPECO <- function(iDir="", xlsF="", oDir=""){
  
  # Set libraries
  # if(!require(XLConnect)){install.packages("XLConnect")}
  options(java.parameters = "-Xmx2048m")
  library(rJava)
  library(XLConnect)
  library(reshape)
  
  # Open xls file 
  xlsF <- loadWorkbook(paste0(iDir, "/", xlsF))
  nsheets <- length(getSheets(xlsF))
  
  st_catalog <- c()
  
  for (i in 1:nsheets){
    
    cat(".> Read Sheet", i , "/", nsheets, "\n")
    
    xlsF_s <- readWorksheet(xlsF, sheet =i, header = FALSE, startRow = 2, startCol = 2)
    
    # Read table and remove unnecessary columns
    data <- xlsF_s[as.numeric(xlsF_s[,1]) > 1950,]
    data <- data[!is.na(data[,1]),]
    if (ncol(data) >=15 && nrow(data) > 20){data <- data[, colSums(is.na(data)) != nrow(data)]}
    data <- data[,-(ncol(data))]
    names(data) <- c("Year", 1:12)
    
    # Rearrange table in two columns and sort by date
    data <- melt(data,id=c("Year"))
    data <- cbind(paste(data[,1], sprintf("%02d", data[,2]), sep=""), as.numeric(as.character(data[,3])))
    colnames(data) <- c("Date", "Value")
    data <- data[order(data[,1]),]
    
    cat(" - get station info \n")
    
    # Read station info
    irow <- which(sapply(lapply(strsplit(xlsF_s[,1], " "), function(ch) grep("estacion", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE)
    irow <- xlsF_s[irow, ]
    irow <- gsub("estacion|:|departamento|tipo|", "", tolower(irow))
    irow[which(irow == "")] <- NA
    irow <- irow[!is.na(irow)]
    
    st_name <- tolower(getSheets(xlsF)[i])
    st_type <- irow[2]
    st_dept <- irow[3]
    
    irow <- which(sapply(lapply(strsplit(xlsF_s[,1], " "), function(ch) grep("latitud", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE)
    irow <- xlsF_s[irow, ]
    irow <- gsub("latitud|longitud|nomenclatura|elevacion|cion|:|msnm|00:00:00| |,|latitud.", "", tolower(irow))
    irow[which(irow == "")] <- NA
    irow <- irow[!is.na(irow)]
    
    if(length(irow) == 4){
      
      st_lat <- strsplit(irow[1], "-")
      st_lat <- as.numeric(substr(st_lat[[1]][1], nchar(st_lat[[1]][1])-1, nchar(st_lat[[1]][1]))) + as.numeric(st_lat[[1]][2])/60 + as.numeric(st_lat[[1]][2])/3600
      st_lon <- strsplit(irow[2], "-")
      st_lon <- as.numeric(substr(st_lon[[1]][1], nchar(st_lon[[1]][1])-1, nchar(st_lon[[1]][1]))) + as.numeric(st_lon[[1]][2])/60 + as.numeric(st_lon[[1]][2])/3600
      
      st_cod <- gsub(" ", "", irow[3])
      st_elv <- gsub(" ", "", irow[4])

    } else {
      st_lat=NA; st_lon=NA; st_cod=st_name; st_elv=NA
    }
    
    
    irow <- which(sapply(lapply(strsplit(xlsF_s[,1], " "), function(ch) grep("cuenca", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE)
    irow <- xlsF_s[irow, ]
    irow <- gsub("cuenca|:| ", "", tolower(irow))
    irow[which(irow == "")] <- NA
    irow <- irow[!is.na(irow)]
    st_wth <- irow[1]
    
    if(which(sapply(lapply(strsplit(xlsF_s[,1], " "), function(ch) grep("precipitacion", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE) > 0) {
      var <- "prec"
    } 
    
    oDirVar <- paste0(oDir, "/monthly-raw/", var, "-per-station")
    if(!file.exists(oDirVar)){
      dir.create(oDirVar, recursive = T)
    }
    
    cat(" - write whtst output file \n")
    write.table(data, paste0(oDirVar, "/", st_cod, "_raw_", var, ".txt"), quote = F, row.names = F)
    
    st_catalog <- rbind(st_catalog, cbind(st_name, st_cod, var, st_type, st_dept, st_lat, st_lon*-1, st_elv, st_wth, paste(data[1,1]), paste(data[nrow(data),1])))
    
  }
  
  cat(".> Write catalog file \n")
  colnames(st_catalog) <- c("station", "code", "variable", "type", "departament", "latitude", "longitude", "elevation", "watershed", "start_date", "end_date")
  write.csv(st_catalog, paste0(oDir, "/stations_catalog.csv"), quote = F, row.names = F)
  
  
  
}

### Run function
readDGRH(iDir, xlsF, oDir)


#### Read DGRH weather data - qbasic data ####

iDir <- "W:/01_weather_stations/hnd_dgrh/monthly_raw/_primary_files/qbasic"
oDir <- "W:/01_weather_stations/hnd_dgrh/monthly_raw"

stLs <- list.files(iDir)

for(st in stLs){
  st <- stLs[7]
  if (file.size(paste0(iDir, "/", st)) > 3){
    data <- readLines(paste0(iDir, "/", st))  
    
    irow <- which(sapply(lapply(strsplit(data, ":"), function(ch) grep("ESTACION", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE)
    
  }
  
  
  
  
}