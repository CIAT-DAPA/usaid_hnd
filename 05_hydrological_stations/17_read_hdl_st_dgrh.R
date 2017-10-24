## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_121')
options(java.parameters = "-Xmx4g" )
library(XLConnect)

#### Read DGRH weather data ####
# Note: There are some stations with wrong header. We use the previous 
#       function to correct the header and then run this new function!
iDir <- "X:/Water_Planning_System/02_hydrological_stations/daily_raw/_primary_files"
xlsF_all <- list.files(iDir,pattern = ".xlsx")
oDir <- "X:/Water_Planning_System/02_hydrological_stations/daily_raw"

readDGRH_n <- function(iDir="", xlsF="", oDir=""){
  
  # Set libraries
  # if(!require(XLConnect)){install.packages("XLConnect")}
  library(XLConnect)
  library(reshape)
  
  # Open xls file 
  st_name <- c()
  for (i in 1:length(xlsF_all)){
    
    #cat(".> Read Sheet", i , "/", nsheets, "\n")
    xlsF <- loadWorkbook(paste0(iDir, "/", xlsF_all[i]))
    xlsF_s <- readWorksheet(xlsF, sheet =3, header = FALSE, startRow = 5, startCol = 1)
    
    # Read table and remove unnecessary columns
    #data <- xlsF_s[as.numeric(xlsF_s[,1]) > 1950,]
    data <- xlsF_s[!is.na(xlsF_s[,1]),]
    data <- data[-((which(data[,1]==31)+1):nrow(data)),]
    
  
    
    cat(" - get station info \n")
    
    # Read station info
    #irow <- which(sapply(lapply(strsplit(xlsF_s[,1], " "), function(ch) grep("ESTACION", tolower(ch))), function(x) length(x) > 0), arr.ind = TRUE)
    irow <- xlsF_s[1, ]
    irow <- gsub("ESTACION :|CUENCA : |RIO |AÑO HIDROLOGICO |", "", irow)
    irow[which(irow == "")] <- NA
    irow <- irow[!is.na(irow)]
    irow <- strsplit(irow, " ")[[1]]
    irow[which(irow == "")] <- NA
    irow <- irow[!is.na(irow)]
    
    
    st_name[i] <- paste(tolower(irow[1:(length(irow)-2)]), collapse = '_')
    st_river <- irow[length(irow)-1]
    st_year <- irow[length(irow)]
    
    year.ini = substring(st_year,1,4)
    year.end = substring(st_year,6,10)
   
    #may hasta abril
    data <- data[-3:-1,]
    month_n = month.abb[c(5:12,1:4)]
 
    names(data) <- c("day", month_n)
    
    dates = seq(as.Date(paste0(year.ini,"-05-01")),as.Date(paste0(year.end,"-04-30")),"days")
    month_ok = format(dates,"%b-%d")
    
    # Rearrange table in two columns and sort by date
    data <- melt(data,id=c("day"))
    month_data = paste0(data$variable,"-",sprintf("%02d",as.numeric(data[,1])))
    
    data <- data[which(month_data %in% month_ok),]
    data_end <- cbind(format(dates,"%Y%m%d"), as.numeric(as.character(data[,3])))
    colnames(data_end) <- c("Date", "Value")
    data_end <- data_end[order(data_end[,1]),]
   
    
    oDirVar <- paste0(oDir,"/", "hdl-per-station")
    if(!file.exists(oDirVar)){
      dir.create(oDirVar, recursive = T)
    }
    
    cat(paste(" - write whtst output file ",i,st_name[i] ,"\n"))
    
    if(st_name[i] %in% st_name){
      write.table(data_end, paste0(oDirVar, "/", st_name[i], "_raw_hdl.txt"), quote = F, col.names =F, row.names = F, append = T)
  
    }else{
      write.table(data_end, paste0(oDirVar, "/", st_name[i], "_raw_hdl.txt"), quote = F, row.names = F)
      
    }
      
 
  }
  

  
}

### Run function
readDGRH_n(iDir, xlsF, oDir)

