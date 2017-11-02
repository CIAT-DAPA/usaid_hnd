## Needs java x-64 (if R is 64bits) https://www.java.com/en/download/manual.jsp 
options(java.parameters = "-Xmx4g" )
library(XLConnect)

#### Read DGRH weather data ####
# Note: There are some stations with wrong header. We use the previous 
#       function to correct the header and then run this new function!
iDir <- "C:/Users/lllanos/Desktop/Prioritarios"
oDir <- "C:/Users/lllanos/Desktop"

xlsF_folder <- list.files(iDir, full.names = T)[-2]
xlsF_all <- sapply(xlsF_folder, list.files, full.names = T)
 library(XLConnect)
  library(reshape)

st_name = basename(xlsF_folder)
readDGRH_n <- function(all_files, st_name,iDir="", xlsF="", oDir=""){
  cat(st_name)
   for (i in 1:(length(all_files)-2)){
    tryCatch({  
    #cat(".> Read Sheet", i , "/", nsheets, "\n")
    xlsF <- loadWorkbook(paste0( all_files[i]))
    xlsF_s <- readWorksheet(xlsF, sheet =1, header = T, startRow = 1, startCol = 1)
    
    # Read table and remove unnecessary columns
    #data <- xlsF_s[as.numeric(xlsF_s[,1]) > 1950,]
    data <- xlsF_s[!is.na(xlsF_s[,1]),]
    
  
    
    cat(" - get station info \n")
    
   
    
    year = substring(data[,1],1,4)
    month = substring(data[,1],5,6)
    day=substring(data[,1],7,8)
    
    data_n = aggregate(data[,3], list("day"=day,"month"=month,"year"=year),mean,na.rm=T)
   
   
    # Rearrange table in two columns and sort by date
    month_data = paste0(data_n$year,data_n$month, data_n$day)
   
    if(st_name=="Chinda")  Q = 77.8574*( data_n[,4] - (-0.32))^ 1.8776
    if(st_name=="ElTablon")  Q=94.059*(data_n[,4]-0.25)^1.9997
    if(st_name=="LaVegona")  Q=24.609*(data_n[,4]+0.1116)^2.3236
    if(st_name=="SF_Ojuera")  Q= 73.097*(data_n[,4] -0.090) ^ 2.1387
    
    
    data_end <- cbind(month_data, Q)
    colnames(data_end) <- c("Date", "Value")
    data_end <- data_end[order(data_end[,1]),]
   
    
    oDirVar <- paste0(oDir,"/", "hdl-per-station")
    if(!file.exists(oDirVar)){
      dir.create(oDirVar, recursive = T)
    }
    
   
    if(i==1){
      #write.table(data_end, paste0(oDirVar, "/tablon_raw_hdl.txt"), quote = F, col.names =F, row.names = F)
      write.table(data_end, paste0(oDirVar,"/", st_name,"_raw_hdl.txt"), quote = F, col.names =F, row.names = F)
      
    }else{
         # write.table(data_end, paste0(oDirVar, "/tablon_raw_hdl.txt"), quote = F, col.names =F, row.names = F, append = T)
      write.table(data_end, paste0(oDirVar,"/", st_name,"_raw_hdl.txt"), quote = F, col.names =F, row.names = F, append = T)
  
    }
    
    }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
    
 
  }
  

  
}

### Run function
lapply(1:length(xlsF_all),function(j) readDGRH_n(all_files = xlsF_all[[j]],st_name = st_name[j],iDir, xlsF, oDir))



# Other format ------------------------------------------------------------
iDir <- "C:/Users/lllanos/Desktop/Prioritarios"
oDir <- "C:/Users/lllanos/Desktop"

xlsF_folder <- list.files(iDir, full.names = T)[-2]
xlsF_all <- sapply(xlsF_folder, list.files, full.names = T)
st_name = basename(xlsF_folder)
readDGRH_n <- function(all_files, st_name,iDir="", xlsF="", oDir=""){
  cat(st_name)
 # for (i in (length(all_files)-1):length(all_files)){
    tryCatch({  
      #cat(".> Read Sheet", i , "/", nsheets, "\n")
      i=length(all_files)-1
      xlsF <- loadWorkbook(paste0( all_files[i]))
      
      for(sheet in 1:12){
        cat(sheet)
        xlsF_s <- readWorksheet(xlsF, sheet =sheet, header = T, startRow = 1, startCol = 1)
        data <- xlsF_s[!is.na(xlsF_s[,1]),]
        if(sheet==1){
           data_n <- t(data[nrow(data)-2,])[-1]
        }else{
          data_n <- as.numeric(c(data_n,t(data[nrow(data)-2,])[-1]))
        }
       
      }
      data_n[data_n<0] <- NA
      # Read table and remove unnecessary columns
 
      
      cat(" - get station info \n")
      m <- gregexpr('[0-9]+',basename(all_files[i]))
      year = regmatches(basename(all_files[i]),m)[[1]]
      
 
      
      # Rearrange table in two columns and sort by date
      dates = seq(as.Date(paste0(year,"-01-01")),as.Date(paste0(year,"-12-31")),"days")
      month_ok = format(dates,"%Y%m%d")
      
      if(st_name=="Chinda")  Q = 77.8574*( data_n - (-0.32))^ 1.8776
      if(st_name=="ElTablon")  Q=94.059*(data_n-0.25)^1.9997
      if(st_name=="LaVegona")  Q=24.609*(data_n+0.1116)^2.3236
      if(st_name=="SF_Ojuera")  Q= 73.097*(data_n -0.090) ^ 2.1387
      
      
      data_end <- cbind(month_ok, Q)
      colnames(data_end) <- c("Date", "Value")
      data_end <- data_end[order(data_end[,1]),]
      
      
      oDirVar <- paste0(oDir,"/", "hdl-per-station")
      if(!file.exists(oDirVar)){
        dir.create(oDirVar, recursive = T)
      }
      
        # write.table(data_end, paste0(oDirVar, "/tablon_raw_hdl.txt"), quote = F, col.names =F, row.names = F, append = T)
        write.table(data_end, paste0(oDirVar,"/", st_name,"_raw_hdl.txt"), quote = F, col.names =F, row.names = F, append = T)
        
      
      
    }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
    
    
 # }
  
  
  
}

### Run function
lapply(1:length(xlsF_all),function(j) readDGRH_n(all_files = xlsF_all[[j]],st_name = st_name[j],iDir, xlsF, oDir))


