## Carlos Navarro
## CIAT-CCAFS
## February 2017
## USAID-HND

## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_121')


###### Convert meters to lat lon using projection for HND

iDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_sanaa/monthly_raw/_primary_files"
xlsF_all <- list.files(iDir, ".xls")
oDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_sanaa/monthly_raw/prec-per-station"


readDGRH <- function(iDir="", xlsF="", oDir=""){
  
  # Set libraries
  # if(!require(XLConnect)){install.packages("XLConnect")}
  library(XLConnect)
  library(reshape)
  
  # Open xls file 
 
  #nsheets <- length(getSheets(xlsF))
  
  st_catalog <- c()
  
  for (i in 1:length(xlsF_all)){
    
    #cat(".> Read Sheet", i , "/", nsheets, "\n")
    xlsF <- loadWorkbook(paste0(iDir, "/", xlsF_all[i]))
    xlsF_s <- readWorksheet(xlsF, sheet =1, header = FALSE, startRow = 4, startCol = 1, endCol = 13)
    
    # Read table and remove unnecessary columns
    data <- xlsF_s[as.numeric(xlsF_s[,1]) > 1950,]
    data <- data[!is.na(data[,1]),]
    #if (ncol(data) >=15 && nrow(data) > 20){data <- data[, colSums(is.na(data)) != nrow(data)]}
    #data <- data[,-(ncol(data))]
    names(data) <- c("Year", 1:12)
    
    # Rearrange table in two columns and sort by date
    data <- melt(data,id=c("Year"))
    data <- cbind(paste(data[,1], sprintf("%02d", data[,2]), sep=""), as.numeric(as.character(data[,3])))
    colnames(data) <- c("Date", "Value")
    data <- data[order(data[,1]),]
    
    cat(" - get station info \n")
    
    # Read station info
    irow <- which(sapply(lapply(strsplit(xlsF_s[1:4,1], " "), function(ch) grep("estacion", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE)
    irow <- strsplit(xlsF_s[irow, 1], " " )[[1]]
    irow <- unlist(strsplit(irow[which(irow!="")],":"))
    # irow <- gsub("estacion|:|departamento|tipo|lat|long|elev|msnm|codigo|subcuenca", "", tolower(irow))
    # irow[which(irow == "")] <- NA
    # irow <- irow[!is.na(irow)]
     
    st_name <- irow[grep("estacion", tolower(irow))+1]
    if(irow[grep("estacion", tolower(irow))+4]!="")  st_name <-paste0(irow[grep("estacion", tolower(irow))+1],irow[grep("estacion", tolower(irow))+2])
   
    
      
      st_lat <- irow[grep("lat", tolower(irow))+1]
     # st_lat <- as.numeric(substr(st_lat[[1]][1], nchar(st_lat[[1]][1])-1, nchar(st_lat[[1]][1]))) + as.numeric(st_lat[[1]][2])/60 + as.numeric(st_lat[[1]][2])/3600
      st_lon <- irow[grep("lat", tolower(irow))+1]
    #  st_lon <- as.numeric(substr(st_lon[[1]][1], nchar(st_lon[[1]][1])-1, nchar(st_lon[[1]][1]))) + as.numeric(st_lon[[1]][2])/60 + as.numeric(st_lon[[1]][2])/3600
      
      st_cod <- irow[grep("codigo", tolower(irow))+1]
      st_elv <- irow[grep("elev", tolower(irow))+1]

  
    
    
    #irow <- which(sapply(lapply(strsplit(xlsF_s[,1], " "), function(ch) grep("cuenca", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE)
    #irow <- xlsF_s[irow, ]
    # irow <- gsub("cuenca|:| ", "", tolower(irow))
    # irow[which(irow == "")] <- NA
    # irow <- irow[!is.na(irow)]
    # st_wth <- irow[1]
    
    # if(which(sapply(lapply(strsplit(xlsF_s[,1], " "), function(ch) grep("precipitacion", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE) > 0) {
       var <- "prec"
    # } 
    
    # oDirVar <- paste0(oDir, "/monthly-raw/", var, "-per-station")
    # if(!file.exists(oDirVar)){
    #   dir.create(oDirVar, recursive = T)
    # }
    
    cat(" - write whtst output file \n")
    write.table(data, paste0(oDir, "/", if(!is.na(as.numeric(st_cod))){as.numeric(st_cod)}else{st_name}, "_raw_", var, ".txt"), quote = F, row.names = F)
    
    st_catalog <- rbind(st_catalog, cbind(st_name, as.numeric(st_cod), var, st_lat, st_lon, st_elv, paste(data[1,1]), paste(data[nrow(data),1])))
    rm(irow)
    rm(data)
  }
  
  cat(".> Write catalog file \n")
  colnames(st_catalog) <- c("station", "code", "variable", "latitude", "longitude", "elevation", "start_date", "end_date")
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