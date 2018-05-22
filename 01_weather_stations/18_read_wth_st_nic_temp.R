# Created by: Lizeth Llanos l.llanos@cgiar.org
# This script read pdf files for Nicaragua stations 
# Date: May 2018

#install.packages("pdftools")
library(pdftools)
library(dplyr)
library(tidyr)
library(readr)

read_pdf_nica <- function(files, inDir, outDir){
  tryCatch({
data_ini <- pdf_text(files)
data_sep <- strsplit(data_ini, "\n") %>% lapply(.,FUN= function(x) gsub("[\r]", "",x)) %>% unlist(.)

enc_ini <- which(grepl("instituto" , tolower(data_sep))==TRUE)
enc_end <- which(grepl("enero" , tolower(data_sep))==TRUE)


  pos_enc <- list()
  for (i in 1:length(enc_ini))   pos_enc[[i]] <- c(enc_ini[i]:enc_end[i]);  pos_enc <- unlist(pos_enc)


data_end <- data_sep[-c(pos_enc,(length(data_sep)-3):length(data_sep))] %>% strsplit(., split = "             ") %>% 
  lapply(.,paste,collapse=" NA ") %>% unlist %>% strsplit(., split = " ") %>% .[lapply(.,length)>1] %>%  unlist %>% .[.!=""] 

info_cat <- data_sep[enc_ini[1]:enc_end[1]] %>% strsplit(., split = " ")%>% unlist %>% .[.!=""]
st_name <- paste(info_cat[(grep("Estación:", info_cat)+1):(grep("/", info_cat)-1)], collapse = "")

st_lat <- info_cat[grep("Latitud", info_cat)+1] %>% extract_numeric %>% as.numeric
st_lat <- as.numeric(substring(st_lat,1,2)) + as.numeric(substring(st_lat,3,4))/60 + as.numeric(substring(st_lat,5,6))/3600

st_lon <- info_cat[grep("Longitud", info_cat)+1] %>% extract_numeric
st_lon <-  (as.numeric(substring(st_lon,1,2)) + as.numeric(substring(st_lon,3,4))/60 + as.numeric(substring(st_lon,5,6))/3600)*-1

st_cod <- info_cat[grep("Código:", info_cat)+1] 
st_elv <- info_cat[grep("Elevación:", info_cat)+1]

if(length(grep("Máxima", info_cat))>0) {var <- "tmax" ; dir.create(paste0(outDir, "/",var,"-per-station"), showWarnings =F)}
if(length(grep("Mínima", info_cat))>0) {var <- "tmin" ; dir.create(paste0(outDir, "/",var,"-per-station"), showWarnings =F)}

if((length(data_end )/14)%%1==0){
  data_end <-  matrix(data_end ,length(data_end )/14,14,byrow = T, dimnames = list(NULL, c("year", 1:12, "max")))
  
  data_f <- as.data.frame(data_end)  %>% .[,-ncol(.)] %>%  gather(key = month, value = Value,-year) %>% .[order(.[,1]),]
  data_f$Date <- paste(data_f$year,sprintf("%02d",as.numeric(data_f$month)),"01",sep = "-") %>% as.Date %>% 
    format(., "%Y%m")
  
  data_f$Value <- as.numeric(data_f$Value)
  data_f <- data_f[,c(4,3)]
  
  
   
  st_catalog <- cbind(st_name, as.numeric(st_cod), var, st_lat, st_lon, st_elv, paste(data_end[1,1]), paste(data_end[nrow(data_end),1]))
  colnames(st_catalog) <- c("station", "code", "variable", "latitude", "longitude", "elevation", "start_date", "end_date")
  
  
  cat(paste(" - write whtst output file", st_cod, st_name, var" \n"))
  # if(!file.exists(paste0(oDirVar, "/", st_cod, "_raw_", var, ".txt")))
  write.table(data_f, paste0(outDir, "/",var,"-per-station/", st_cod, "_raw_", var, ".txt"), quote = F, row.names = F,append = TRUE, col.names=!file.exists(paste0(outDir,"/",var, "/", st_cod, "_raw_", var, ".txt")))
  write.table(st_catalog, paste0(outDir, "/stations_catalog.csv"), sep = ",", quote = F, row.names = F, append = TRUE, col.names=!file.exists(paste0(outDir, "/stations_catalog.csv")))
  
}else{
  cat(paste("NO coinciden las columnas", st_cod, st_name, var," \n"))
}
  

}, error=function(e){cat("ERROR :",conditionMessage(e), "\n")}) 

   }



inDir <- "Z:/Water_Planning_System/01_weather_stations/nic_ineter/_primary_files/Temperatura"
files_all <- list.files(inDir,full.names = T) %>% list.files(.,pattern = ".pdf",full.names = T)
pos_mean <- which(grepl("media" , tolower(as.character(basename(files_all))))==TRUE)
pos_mean1 <- which(grepl("tmed" , tolower(as.character(basename(files_all))))==TRUE)
pos_mean2 <- which(grepl("med" , tolower(as.character(basename(files_all))))==TRUE)

files_all <- files_all[-c(pos_mean,pos_mean1,pos_mean2)]
outDir <- "Z:/Water_Planning_System/01_weather_stations/nic_ineter/monthly_raw"

lapply(1:length(files_all),function(i) {print(i); read_pdf_nica(files_all[i], inDir, outDir)})

