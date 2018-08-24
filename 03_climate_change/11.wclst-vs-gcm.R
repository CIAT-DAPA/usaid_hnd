library(rgdal)

repoDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/skill_gcm"
srcDir <- paste(repoDir, "/0002-BaselineComparison", sep="")

setwd(srcDir)
source("compareWSRaster.R")


#################################################################################
#################################################################################
#GCM vs. WCL weather stations (RAIN,TMEAN)
#################################################################################
#################################################################################
mDataDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/skill_gcm"

oDir <- paste(mDataDir, "/results_HND", sep="")
if (!file.exists(oDir)) {
  dir.create(oDir)
}

md <- paste(mDataDir, "/gcm-data/1980_2010", sep="")
gcmList <- list.files(md)

cd <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/01_Estaciones/merge/combined"
shd <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/skill_gcm/Administrative_boundaries"

cList <- c("HND")
mam <- paste(oDir, "/whst-vs-gcm/MAM", sep="")
son <- paste(oDir, "/whst-vs-gcm/SON", sep="")
jja <- paste(oDir, "/whst-vs-gcm/JJA", sep="")
djf <- paste(oDir, "/whst-vs-gcm/DJF", sep="")
ann <- paste(oDir, "/whst-vs-gcm/ANNUAL",sep="")
if (!file.exists(mam)) {dir.create(mam, recursive = T)}
if (!file.exists(son)) {dir.create(son)}
if (!file.exists(jja)) {dir.create(jja)}
if (!file.exists(djf)) {dir.create(djf)}
if (!file.exists(ann)) {dir.create(ann)}

for (ctry in cList) {
  for (mod in gcmList) {
		for (vr in c("tmean", "prec", "tmin", "tmax")) {
			cat("Processing", ctry, mod, vr, "\n")
			if (vr == "prec") {dv <- F} else {dv <- T}
		  outp <- compareWSR(gcmDir=md, gcm=mod, shpDir=shd, stationDir=cd, country=ctry, variable=vr, divide=dv, months=c(3,4,5), outDir=mam, verbose=T)
		  outp <- compareWSR(gcmDir=md, gcm=mod, shpDir=shd, stationDir=cd, country=ctry, variable=vr, divide=dv, months=c(9,10,11), outDir=son, verbose=T)
		  outp <- compareWSR(gcmDir=md, gcm=mod, shpDir=shd, stationDir=cd, country=ctry, variable=vr, divide=dv, months=c(6,7,8), outDir=jja, verbose=T)
			outp <- compareWSR(gcmDir=md, gcm=mod, shpDir=shd, stationDir=cd, country=ctry, variable=vr, divide=dv, months=c(12,1,2), outDir=djf, verbose=T)
			outp <- compareWSR(gcmDir=md, gcm=mod, shpDir=shd, stationDir=cd, country=ctry, variable=vr, divide=dv, months=c(1:12), outDir=ann, verbose=T)
		}
	}
}
