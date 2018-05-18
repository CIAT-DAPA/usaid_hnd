# Created by: Lizeth Llanos l.llanos@cgiar.org
# This script read pdf files for Nicaragua stations 
# Date: May 2018

#install.packages("pdftools")
library(pdftools)

data_ini <- pdf_text("Z:/Water_Planning_System/01_weather_stations/nic_ineter/_primary_files/Temperatura/47002 PUERTO CABEZAS/47002 T max abs.pdf")
data_sep <- strsplit(text, "\n") %>% lapply(.,FUN= function(x) gsub("[\r]", "",x)) %>% unlist(.)

enc_ini <- which(grepl("instituto" , tolower(data_sep))==TRUE)
enc_end <- which(grepl("enero" , tolower(data_sep))==TRUE)
pos_enc <- c(enc_ini[1]:enc_end[1],enc_ini[2]:enc_end[2]) %>% sort(.)

data_end <- data_sep[-c(pos_enc,(length(data_sep)-3):length(data_sep))] %>% strsplit(., split = "             ") %>% 
  lapply(.,paste,collapse=" NA ") %>% unlist %>% strsplit(., split = " ") %>% unlist %>% .[.!=""] %>% 
  matrix(.,length(.)/14,14,byrow = T, dimnames = list(NULL, c("year", 1:12, "max")))

data_f <- as.data.frame(data_end)  %>% .[,-ncol(.)] %>%  gather(key = month, value = Value,-year) %>% .[order(.[,1]),]
data_f$Date <- paste(data_f$year,sprintf("%02d",as.numeric(data_f$month)),"01",sep = "-") %>% as.Date %>% 
  format(., "%Y%m")

