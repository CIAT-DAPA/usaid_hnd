library(foreign)
iDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/zonal_statistics/dbf"
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/zonal_statistics"

baseFile <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/microcuencas_spajoin_rg_proj.dbf"
dbflist <- list.files(iDir, full.names=T, recursive = TRUE, pattern='.dbf')

microwht_rg <- read.dbf(baseFile)

for (dbf in dbflist){
  
  # dbf <- dbflist[1]
  
  dbf_i <- read.dbf(dbf)
  
  dbf_i$ZONE_CODE <- NULL
  dbf_i$COUNT <- NULL
  dbf_i$AREA <- NULL
  

  var <- paste(  strsplit(strsplit(basename(dbf), "\\.")[[1]][1] , "_")[[1]][4]  )
  
  if (var == "tmin" || var == "tmax" || var == "tmean"){
    dbf_i$MEAN <- dbf_i$MEAN / 10 
  }
  
  rcp <- paste(  strsplit(strsplit(basename(dbf), "\\.")[[1]][1] , "_")[[1]][1]  )
  
  if (rcp != "historical" && var == "wsmean"){
    dbf_i$MEAN <- dbf_i$MEAN / 10 
  }
  
  dbf_i$MEAN <- round(dbf_i$MEAN, digits = 1)
  names(dbf_i)[2] <- paste(strsplit(basename(dbf), "\\.")[[1]][1])
  
  microwht_rg <- merge(microwht_rg, dbf_i, by = "ID_MicroCu", all = TRUE)

  cat(paste(strsplit(basename(dbf), "\\.")[[1]][1]), "merged", "\n")
    
}
  
write.csv(microwht_rg, paste0(oDir, "/microcuencas_rg_averages_v3.csv"), row.names=F)




# microwht_rg <- read.csv(paste0(oDir, "/microcuencas_rg_averages.csv"), header=T)
# 
# microwht_rg$Check <- complete.cases(microwht_rg)
# 
# write.csv(microwht_rg, paste0(oDir, "/microcuencas_rg_averages_check.csv"), row.names=F)

