## Authors: Carlos Navarro - Lizeth Llanos / c.e.navarro@cgiar.org
## CIAT-CCAFS
## May 2018
## PNUD-HND

## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_171')

#### Read MARN weather data ####
iDir <- "W:/01_weather_stations/slv_marn/monthly_raw/_primary_files"
xlsF <- "prec_temp.xlsx"
oDir <- "W:/01_weather_stations/slv_marn/monthly_raw"
st <- "W:/01_weather_stations/slv_marn/stations_catalog.csv"

library(rJava)
library(XLConnect)
library(reshape)

i = 1
xlsF <- loadWorkbook(paste0(iDir, "/", xlsF))
xlsF_s_all <- readWorksheet(xlsF, sheet =i, header = T, startRow = 5)

st_cat <- read.csv(st)
codLs <- st_cat$Code

# Loop around codes
for(code in 1:length(codLs)){
  
  xlsF_s <- xlsF_s_all[which(xlsF_s_all$Indice == paste(codLs[code])),]
  
  if (nrow(xlsF_s) > 1){
    
    date <- xlsF_s$Fecha
    
    yrs <- unlist(strsplit(date, "-"))[2*(1:length(date))-1]
    mts <- sprintf("%02d", as.numeric(unlist(strsplit(date, "-"))[2*(1:length(date))]))
    date <- paste(yrs, mts, sep="")
    
    prec <- round(as.numeric(xlsF_s$Lluvia.mm.), 1)
    tean <- round(as.numeric(xlsF_s$T.MediaÂ.C.), 1)
    
    prec <- as.data.frame(cbind(date, prec))
    tean <- as.data.frame(cbind(date, tean))
    
    colnames(prec) <- c("Date", "Value")
    colnames(tean) <- c("Date", "Value")
    
    cat(" - write whtst output file", code, " \n")
    
    oDirPrec <- paste0(oDir,"/prec-per-station")
    if(!file.exists(oDirPrec)){dir.create(oDirPrec, recursive = T)}
    
    oDirTean <- paste0(oDir,"/tmean-per-station")
    if(!file.exists(oDirTean)){dir.create(oDirTean, recursive = T)}
    
    write.table(prec, paste0(oDirPrec, "/", tolower(codLs[code]), "_raw_prec.txt"), quote = F, row.names = F, sep="\t")
    write.table(tean, paste0(oDirTean, "/", tolower(codLs[code]), "_raw_tmean.txt"), quote = F, row.names = F, sep="\t")  
  }
  
}