#Summaries

#Summarise all the comparisons for the 'climate normals' comparisons
source("summariseComparisons.R")

bd <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/skill_gcm/results_HND"

for (vb in c("tmean", "prec")) {

	ds <- "wcl"

	sdt <- metricsSummary(bDir=bd, dataset=ds, variable=vb)
	sdt <- dataSummary(bDir=bd, dataset=ds, variable=vb)
	#Copy the output file sumaryMetrics to the _summary folder
	in.file <- paste(bd,"/",ds,"-vs-gcm/summary/",vb,"-",ds,"-vs-gcm-summaryMetrics.csv",sep="")
	ot.file <- paste(bd,"/_summaries/",vb,"-",ds,"-vs-gcm-summaryMetrics.csv",sep="")
	if (file.exists(ot.file)) {file.remove(ot.file)}
	file.copy(in.file,ot.file)

	ds <- "whst"
	# vb <- "tmean"
	sdt <- metricsSummary(bDir=bd, dataset=ds, variable=vb)
	sdt <- dataSummary(bDir=bd, dataset=ds, variable=vb)
	#Copy the output file sumaryMetrics to the _summary folder
	in.file <- paste(bd,"/",ds,"-vs-gcm/summary/",vb,"-",ds,"-vs-gcm-summaryMetrics.csv",sep="")
	ot.file <- paste(bd,"/_summaries/",vb,"-",ds,"-vs-gcm-summaryMetrics.csv",sep="")
	if (file.exists(ot.file)) {file.remove(ot.file)}
	file.copy(in.file,ot.file)

}

######################################################
######################################################
#Generate boxplots

source("summariseComparisons.R")
f.dir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/skill_gcm/results_HND/_summaries"
generateBoxplots(fd=f.dir)
for (vn in c("prec","tmean")) {
  for (dset in c("whst")) {
    for (prd in c("ANNUAL","DJF","JJA","MAM","SON")) {
      if (file.exists(paste(f.dir,"/",vn,"-",dset,"-vs-gcm-summaryMetrics.csv",sep=""))) {
        createColoured(fDir=f.dir, variable=vn, dataset=dset, month="total", period=prd, metric="R2.FORCED")
      }
    }
  }
}




