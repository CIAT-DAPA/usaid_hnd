# Created by: Lizeth Llanos l.llanos@cgiar.org
# This script read html files for Nicaragua stations 
# Date: May 2018

library(RCurl)
library(XML)
library(dplyr)
library(tidyr)
library(readr)
options(warn=-1)

htmlToText <- function(input, ...) {
  ###---PACKAGES ---###
  require(RCurl)
  require(XML)
  
  
  ###--- LOCAL FUNCTIONS ---###
  # Determine how to grab html for a single input element
  evaluate_input <- function(input) {    
    # if input is a .html file
    if(file.exists(input)) {
      char.vec <- readLines(input, warn = FALSE)
      return(paste(char.vec, collapse = ""))
    }
    
    # if input is html text
    if(grepl("</html>", input, fixed = TRUE)) return(input)
    
    # if input is a URL, probably should use a regex here instead?
    if(!grepl(" ", input)) {
      # downolad SSL certificate in case of https problem
      if(!file.exists("cacert.perm")) download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.perm")
      return(getURL(input, followlocation = TRUE, cainfo = "cacert.perm"))
    }
    
    # return NULL if none of the conditions above apply
    return(NULL)
  }
  
  # convert HTML to plain text
  convert_html_to_text <- function(html) {
    doc <- htmlParse(html, asText = TRUE)
    text <- xpathSApply(doc, "//text()[not(ancestor::script)][not(ancestor::style)][not(ancestor::noscript)][not(ancestor::form)]", xmlValue)
    return(text)
  }
  
  # format text vector into one character string
  collapse_text <- function(txt) {
    return(paste(txt, collapse = " "))
  }
  
  ###--- MAIN ---###
  # STEP 1: Evaluate input
  html.list <- lapply(input, evaluate_input)
  
  # STEP 2: Extract text from HTML
  text.list <- lapply(html.list, convert_html_to_text)
  
  # STEP 3: Return text
  text.vector <- sapply(text.list, collapse_text)
  return(text.vector)
}

# Run function to read html files

read_html_nica <- function(files, inDir, outDir, var){

dir.create(paste0(outDir,"/",var))  

html_files <- files %>% htmlToText %>% strsplit(., split = " ") %>% unlist %>% .[.!=""]
pos_sum <- which(html_files=="Suma")

if(length(pos_sum)>0){
  

data_end <- matrix(html_files[(pos_sum[1]+1):(pos_sum[2]-1)],31,14, byrow = T, dimnames = list(1:31,c("day",1:12,"sume"))) %>% 
            as.data.frame(.) %>% .[,-ncol(.)] %>%  gather(key = month, value = Value,-day)

info_cat <- html_files[1:pos_sum[1]]
year <- info_cat[grep("Año:", info_cat)+1]

data_end$Date <- paste(year,sprintf("%02d",as.numeric(data_end$month)), sprintf("%02d", as.numeric(as.character(data_end$day))),sep = "-") %>% as.Date() %>% 
                 format(., "%Y%m%d")

data_end$Value <- as.numeric(data_end$Value)
data_end <- data_end[!is.na(data_end$Date),c(4,3)]


# date <- data.frame(date=seq(as.Date(paste0(year,"-01-01")),as.Date(paste0(year,"-12-31")),"days"))
# data_end <- data_end %>% right_join(,by = "date")

st_name <- info_cat[grep("Estación:", info_cat)+2]

st_lat <- info_cat[grep("Latitud", info_cat)+1:4] %>% extract_numeric
st_lat <- st_lat[1]+ st_lat[2]/60 + st_lat[3]/3600

st_lon <- info_cat[grep("Longitud", info_cat)+1:4] %>% extract_numeric
st_lon <-  (st_lon[1]+ st_lon[2]/60 + st_lon[3]/3600)*-1

st_cod <- info_cat[grep("Código:", info_cat)+1:2] %>% paste(., collapse = "")
st_elv <- info_cat[grep("Elevación:", info_cat)+1]

st_catalog <- cbind(st_name, as.numeric(st_cod), var, st_lat, st_lon, st_elv, paste(data_end[1,1]), paste(data_end[nrow(data_end),1]))
colnames(st_catalog) <- c("station", "code", "variable", "latitude", "longitude", "elevation", "start_date", "end_date")


cat(paste(" - write whtst output file", st_cod, st_name, year," \n"))
# if(!file.exists(paste0(oDirVar, "/", st_cod, "_raw_", var, ".txt")))
write.table(data_end, paste0(outDir, "/",var,"/", st_cod, "_raw_", var, ".txt"), quote = F, row.names = F,append = TRUE, col.names=!file.exists(paste0(outDir,"/",var, "/", st_cod, "_raw_", var, ".txt")))
write.table(st_catalog, paste0(outDir, "/stations_catalog.csv"), sep = ",", quote = F, row.names = F, append = TRUE, col.names=!file.exists(paste0(outDir, "/stations_catalog.csv")))
}

}

inDir <- "Z:/Water_Planning_System/01_weather_stations/nic_ineter/_primary_files/Precipitacion"
files_all <- list.files(inDir,full.names = T) %>% list.files(.,pattern = ".htm",full.names = T)
pos_month <- which(gsub("[^0-9]+", "",as.character(basename(files_all))) %>% nchar(.)>11)
pos_yearly <- which(grepl("anual" , tolower(as.character(basename(files_all))))==TRUE)

files_all <- files_all[-c(pos_month, pos_yearly)]
outDir <- "Z:/Water_Planning_System/01_weather_stations/nic_ineter/daily_raw"
var <- "prec"

lapply(1:length(files_all),function(i) {print(i); read_html_nica(files_all[i], inDir, outDir, var)})
