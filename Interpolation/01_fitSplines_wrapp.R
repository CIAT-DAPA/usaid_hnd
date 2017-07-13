# Carlos Navarro
# CCAFS / CIAT
# February 2016

require(raster)
require(foreign)

stop("error")
sfStop()

# Set params 
vn <- "rain"
bDir <- "D:/cenavarro/hnd_usaid/04_interpolation"
train.per <- 0.75
tile <- 1
ntiles <- 1
suffix <-"hnd"
nfolds <- 25
sY <- 1987
eY <- 1987
cpus <- eY-sY+1

# Folders 
srcDir <- paste0(bDir, "/_scripts")
anuDir <- paste0(bDir, "/anu/Anuspl43/bin")
stDir <- paste0(bDir, "/stations-averages/yearly_pseudost")
rDir <- paste0(bDir, "/region/v3")
oDir <- paste0(bDir, "/outputs_yearly/", vn)

#Reading altitude raster (regional level)
cat("Reading mask file \n")
msk <- raster(paste0(rDir, "/alt-prj-",suffix, ".asc"))
xt <- extent(msk)
xt@xmin <- xt@xmin; xt@xmax <- xt@xmax; xt@ymin <- xt@ymin; xt@ymax <- xt@ymax
rm(msk)

# Main function
setwd(srcDir)
source("fitSplines-yearly.R")

# Do the snowfall stuff here
library(snowfall)
sfInit(parallel=T,cpus=cpus) #initiate cluster

# Export functions
# sfExport("srcDir")
sfExport("splineFitting")
sfExport("stDir")
sfExport("anuDir")
sfExport("rDir")
sfExport("oDir")
sfExport("nfolds")
sfExport("train.per")
sfExport("vn")
sfExport("tile")
sfExport("ntiles")
sfExport("suffix")
sfExport("xt")
sfExport("tile")

controlSplitting <- function(i) { #define a new function
  
  require(raster)
  require(foreign)
  
  source("writeDatFile.R"); source("createFitFile.R"); source("createValFile.R"); source("createPrjFile.R"); source("accuracy.R")  
  oyDir <- paste0(oDir, "/", i)
  
  splineFitting(anuDir, stDir, rDir, oyDir, nfolds, train.per, vn, ntiles, unix=F, suffix, xt, i)
  
}

system.time(sfSapply(as.vector(sY:eY), controlSplitting))

