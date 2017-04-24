## Carlos Navarro
## CIAT-CCAFS
## February 2017
## USAID-HND

## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_121')

library(rgdal)
library(proj4)
library(XLConnect)

# Convert formats 
iDir <- "W:/01_weather_stations/hnd_enee/daily_raw/_primary_files"
stcat <- read.csv("W:/01_weather_stations/hnd_enee/daily_raw/stations_catalog_v2.csv")

# List of the stations in xlsx format
stLs <- list.files(iDir, pattern = "xlsx")

for (st in stLs){
  
  stName <- tolower(strsplit(iconv(st, to='ASCII//TRANSLIT'), " - ")[[1]][1])
  stDpto <- gsub(pattern = "\\.xlsx$", "", tolower(strsplit(iconv(st, to='ASCII//TRANSLIT'), " - ")[[1]][2]))
  
  # Merge with the catalog
  merge <- stcat[which(tolower(iconv(stcat$Estacion, to='ASCII//TRANSLIT')) == stName & tolower(iconv(stcat$DEPTO, to='ASCII//TRANSLIT')) == stDpto), ]
  
  stCode <- paste(merge$COD_NAC)
  
  cat(stName, "\t",stCode, "\n")
  stRead <- readWorksheet(loadWorkbook(paste0(iDir, "/", st)), sheet ="Diaria", header = T)
  write.table(stRead, paste0(iDir, "/", stCode, ".txt"), quote = F, row.names = F, sep="\t", na = "")
  
  
}
  