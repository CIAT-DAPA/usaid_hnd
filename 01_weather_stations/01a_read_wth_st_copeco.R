## Authors: Lizeth Llanos l.llanos@cgiar.org / Carlos Navarro
## CIAT-CCAFS
## April 2018
## USAID-HND

## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_161')

# Set libraries 
options(java.parameters = "-Xmx8000m")
library(rJava)
# if(!require(XLConnect)){install.packages("XLConnect")}
library(XLConnect)
library(reshape)
    
#### Read COPECO-SERNA weather data ####

var <- "tmin"
# readCOPECO(iDir, xlsF, oDir, var)

readCOPECO <- function(iDir="", xlsF="", oDir="", var){
  
  if (var == "prec"){
    
    iDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/_primary_files/Precipitacion Diaria"
    xlsF <- "Precipitaciones.xlsx"
    oDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw"

    # Open xls file 
    xlsF <- loadWorkbook(paste0(iDir, "/", xlsF))
    nsheets <- length(getSheets(xlsF))
    name_sh <- getSheets(xlsF)
    st_catalog <- read.csv("Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/_primary_files/coordenadas.csv",header = T)
    
    for (i in 2:nsheets){
      
      cat(".> Read Sheet", i , "/", nsheets, "\n")
      
      xlsF_s <- readWorksheet(xlsF, sheet =i, header = FALSE, startRow = 7, startCol = 2, endCol = 34)
      
      # Read table and remove unnecessary columns
      data <- xlsF_s[as.numeric(xlsF_s[,1]) >= 1970,]
      data <- data[!is.na(data[,1]),]
       names(data) <- c("Year", "Month", 1:31)
      
      # Rearrange table in two columns and sort by date
      data <- melt(data,id=c("Year", "Month"))
      names(data)[3] <- "Day"
      data <- data [order(data$Year, data$Month),]
      
      dates_s <- as.Date(paste(data[,1], data[,2], data[,3], sep = "-"))
      dates_f <- seq.Date(as.Date("1970-01-01"), as.Date(paste(data[nrow(data),1], 12, 31, sep="-")), "days")
      
      data_f <- data[which(dates_s %in% dates_f),]
      
      data_f <- cbind.data.frame(Date = paste(data_f[,1], sprintf("%02d", data_f[,2]),sprintf("%02d", data_f[,3]), sep=""), Value = as.numeric(as.character(data_f[,4])))
      data_f <- data_f[order(data_f[,1]),]
      
      oDirVar <- paste0(oDir,"/", var, "-per-station")
      if(!file.exists(oDirVar)){
        dir.create(oDirVar, recursive = T)
      }
      
      st_cod <- st_catalog[which(tolower(name_sh[i]) == tolower(st_catalog[,1])), 5]
      cat(" - write whtst output file \n")
      print(as.character(st_cod))
      write.table(data_f, paste0(oDirVar, "/", st_cod, "_raw_", var, ".txt"), quote = F, row.names = F)
      
      
    }
    
   
    
  } 
  
  if (var == "tmax"){
    
    iDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/_primary_files/Temperatura Máxima Absoluta"
    xlsF_all <- list.files(iDir, ".xls")
    oDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw"
    
    # Open xls file 
    # nsheets <- length(getSheets(xlsF))
    name_sh <- gsub(" ","",gsub(" Temperatura Máxima Absoluta.xls", "", xlsF_all))
    st_catalog <- read.csv("Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/_primary_files/coordenadas.csv",header = T)
    
    for (i in 1:length(xlsF_all)){
      
      cat(".> Read Sheet", i , "\n")
      xlsF <- loadWorkbook(paste0(iDir, "/", xlsF_all[i]))
 
      xlsF_s <- readWorksheet(xlsF, sheet =1, header = FALSE, startRow = 7, startCol = 2, endCol = 34)
      
      # Read table and remove unnecessary columns
      data <- xlsF_s[as.numeric(xlsF_s[,1]) >= 1970,]
      data <- data[!is.na(data[,1]),]
      names(data) <- c("Year", "Month", 1:31)
      
      # Rearrange table in two columns and sort by date
      data <- melt(data,id=c("Year", "Month"))
      names(data)[3] <- "Day"
      data <- data [order(data$Year, data$Month),]
      
      dates_s <- as.Date(paste(data[,1], data[,2], data[,3], sep = "-"))
      dates_f <- seq.Date(as.Date("1970-01-01"), as.Date(paste(data[nrow(data),1], 12, 31, sep="-")), "days")
      
      data_f <- data[which(dates_s %in% dates_f),]
      
      data_f <- cbind.data.frame(Date = paste(data_f[,1], sprintf("%02d", data_f[,2]),sprintf("%02d", data_f[,3]), sep=""), Value = as.numeric(as.character(data_f[,4])))
      data_f <- data_f[order(data_f[,1]),]
      
      oDirVar <- paste0(oDir,"/", var, "-per-station")
      if(!file.exists(oDirVar)){
        dir.create(oDirVar, recursive = T)
      }
      
      st_cod <- st_catalog[which(tolower(name_sh[i]) == tolower(st_catalog[,1])), 5]
      cat(" - write whtst output file \n")
      print(as.character(st_cod))
      write.table(data_f, paste0(oDirVar, "/", st_cod, "_raw_", var, ".txt"), quote = F, row.names = F)
      
      
    }
    
    
    
  } 
  
  if (var == "tmin"){
    
    iDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/_primary_files/Temperatura Mínima Absoluta/"
    xlsF_all <- list.files(iDir, ".xls")
    oDir <- "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw"
    
    # Open xls file 
    # nsheets <- length(getSheets(xlsF))
    name_sh <- gsub(" ","",gsub(" Temperatura Mínima Absoluta.xls", "", xlsF_all))
    st_catalog <- read.csv("Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/_primary_files/coordenadas.csv",header = T)
    
    for (i in 1:length(xlsF_all)){
      
      cat(".> Read Sheet", i , "\n")
      xlsF <- loadWorkbook(paste0(iDir, "/", xlsF_all[i]))
      
      xlsF_s <- readWorksheet(xlsF, sheet =1, header = FALSE, startRow = 7, startCol = 2, endCol = 34)
      
      # Read table and remove unnecessary columns
      data <- xlsF_s[as.numeric(xlsF_s[,1]) >= 1970,]
      data <- data[!is.na(data[,1]),]
      names(data) <- c("Year", "Month", 1:31)
      
      # Rearrange table in two columns and sort by date
      data <- melt(data,id=c("Year", "Month"))
      names(data)[3] <- "Day"
      data <- data [order(data$Year, data$Month),]
      
      dates_s <- as.Date(paste(data[,1], data[,2], data[,3], sep = "-"))
      dates_f <- seq.Date(as.Date("1970-01-01"), as.Date(paste(data[nrow(data),1], 12, 31, sep="-")), "days")
      
      data_f <- data[which(dates_s %in% dates_f),]
      
      data_f <- cbind.data.frame(Date = paste(data_f[,1], sprintf("%02d", data_f[,2]),sprintf("%02d", data_f[,3]), sep=""), Value = as.numeric(as.character(data_f[,4])))
      data_f <- data_f[order(data_f[,1]),]
      
      oDirVar <- paste0(oDir,"/", var, "-per-station")
      if(!file.exists(oDirVar)){
        dir.create(oDirVar, recursive = T)
      }
      
      st_cod <- st_catalog[which(tolower(name_sh[i]) == tolower(st_catalog[,1])), 5]
      cat(" - write whtst output file \n")
      print(as.character(st_cod))
      write.table(data_f, paste0(oDirVar, "/", st_cod, "_raw_", var, ".txt"), quote = F, row.names = F)
      
      
    }
    
    
    
  } 
  
  
}


