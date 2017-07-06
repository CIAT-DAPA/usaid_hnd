# Carlos Navarro
# CCAFS / CIAT
# February 2016
sfStop()

srcDir <- "D:/cenavarro/col-usaid/00_scripts"
anuDir <- "D:/cenavarro/col-usaid/00_scripts/anu/Anuspl43/bin"
stDir <- "D:/cenavarro/col-usaid/02-monthly-interpolations/stations-averages/1976-1985"
rDir <- "D:/cenavarro/col-usaid/02-monthly-interpolations/region"
oDir <- "D:/cenavarro/col-usaid/02-monthly-interpolations/outputs/1976-1985"
train.per <- 0.90
vn <- "rain"
tile <- 1
ntiles <- 1
suffix <-"ris"
nfolds <- 25
unix <- F

setwd(srcDir)
source("fitSplines.R")

# varlist <- c("rain", "tmax", "tmin")
# for (vn in varlist){
#   
  otp <- splineFitting(anuDir, stDir, rDir, oDir, nfolds, train.per, vn, ntiles, unix=F, suffix)  
# }


#do the snowfall stuff here
library(snowfall)
sfInit(parallel=T,cpus=1) #initiate cluster
# oDir_vn <- paste0(oDir, "/", vn)

# for (i in 1:nfolds){
#   splineFitting(anuDir, stDir, rDir, oDir, i, train.per, vn, ntiles, unix=F, suffix)
# }

#export functions
sfExport("splineFitting")
sfExport("stDir")
sfExport("anuDir")
sfExport("rDir")
sfExport("oDir")
sfExport("train.per")
sfExport("vn")
sfExport("tile")
sfExport("ntiles")
sfExport("suffix")
sfExport("tile")
sfExport("srcDir")

controlSplitting <- function(i) { #define a new function
  require(raster)
  require(foreign)
  splineFitting(anuDir, stDir, rDir, oDir, i, train.per, vn, ntiles, unix=F, suffix, srcDir)
}

system.time(sfSapply(as.vector(1:25), controlSplitting))
