# Carlos Navarro 
# CIAT - CCAFS
# May 2018


########################
#### 01 Across GCMs ####
########################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)

rcp <- c("rcp85")
anomDir <- "W:/05_downscaling_hnd/anomalies_v2"
baseDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/average_v2"
per <- "2040_2069"
perMod <- "2050s"
var <- "prec"
season <- "ann"
# id <- rep(c("ANUAL"), length(perList))
mask <- raster("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/hnd_msk.tif")
limits <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Regiones_Desarrollo_prj_v2.shp")
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/evaluation/uncertainties"

oDir_files <- paste0(oDir, "/base-files")
if (!file.exists(oDir_files)) {dir.create(oDir_files, recursive=T)}

# Calculate annual by GCM 
gcmList <- list.dirs(paste0(anomDir, "/", rcp), recursive = FALSE, full.names = FALSE)

for (gcm in gcmList){
  
  tx <- stack(paste0(anomDir, "/", rcp, "/", gcm, "/", per, "/tmax_res.nc"))
  tn <- stack(paste0(anomDir, "/", rcp, "/", gcm, "/", per, "/tmin_res.nc"))

  tx_ann <- mean(tx)
  tn_ann <- mean(tn)

  tm_ann <- mask(crop( (tx_ann+ tn_ann) / 2, mask), mask)

  writeRaster(tm_ann, paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_", gcm, ".tif"), overwrite=T )

  pr <- stack(paste0(anomDir, "/", rcp, "/", gcm, "/", per, "/prec_res.nc"))
  
  pr_ann <- mask(crop( mean(pr), mask), mask)
  writeRaster(pr_ann, paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_", gcm, ".tif"), overwrite=T )
  
  
}

tm_ann_stk <- stack(paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_", gcmList, ".tif"))

tm_ann_stk_avg <- mean(tm_ann_stk, na.rm=TRUE)
tm_ann_stk_std <- calc(tm_ann_stk, fun = function(x) { sd(x, na.rm = T) })
tm_ann_stk_q10 <- calc(tm_ann_stk, fun = function(x) {quantile(x,probs = c(.1,.9),na.rm=TRUE)} )
tm_ann_stk_q25 <- calc(tm_ann_stk, fun = function(x) {quantile(x,probs = c(.25,.75),na.rm=TRUE)} )

writeRaster(tm_ann_stk_avg, paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_ensemble_avg.tif"))
writeRaster(tm_ann_stk_std, paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_ensemble_std.tif"))
writeRaster(tm_ann_stk_q10[[1]], paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_ensemble_q10.tif"))
writeRaster(tm_ann_stk_q10[[2]], paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_ensemble_q90.tif")) 
writeRaster(tm_ann_stk_q25[[1]], paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_ensemble_q25.tif"))
writeRaster(tm_ann_stk_q25[[2]], paste0(oDir_files, "/", var, "_ann_", per, "_", rcp, "_ensemble_q75.tif")) 



## Precipitation
## [Decimal]

pr_ann_stk <- stack(paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_", gcmList, ".tif"))

pr_ann_stk_avg <- mean(pr_ann_stk, na.rm=TRUE)
pr_ann_stk_std <- calc(pr_ann_stk, fun = function(x) { sd(x, na.rm = T) })
pr_ann_stk_q10 <- calc(pr_ann_stk, fun = function(x) {quantile(x,probs = c(.1,.9),na.rm=TRUE)} )
pr_ann_stk_q25 <- calc(pr_ann_stk, fun = function(x) {quantile(x,probs = c(.25,.75),na.rm=TRUE)} )

writeRaster(pr_ann_stk_avg, paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_ensemble_avg.tif"))
writeRaster(pr_ann_stk_std, paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_ensemble_std.tif"))
writeRaster(pr_ann_stk_q10[[1]], paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_ensemble_q10.tif"))
writeRaster(pr_ann_stk_q10[[2]], paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_ensemble_q90.tif")) 
writeRaster(pr_ann_stk_q25[[1]], paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_ensemble_q25.tif"))
writeRaster(pr_ann_stk_q25[[2]], paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_ensemble_q75.tif")) 


pr_ann_stk_01 <- pr_ann_stk * pr_ann_stk_avg
pr_ann_stk_01[pr_ann_stk_01 >= 0 ] <- 1
pr_ann_stk_01[pr_ann_stk_01 < 0 ] <- 0

pr_ann_stk_agr <- sum(pr_ann_stk_01, na.rm=TRUE)
writeRaster(pr_ann_stk_agr, paste0(oDir_files, "/prec_ann_", per, "_", rcp, "_ensemble_agreement.tif"))


## Plots

if (var == "prec"){ 
  metrics <- c("agreement") # "avg", "q10", "q90", "agreement")
} else {
  metrics <- c("avg", "q10", "q90", "std")
}

for( metric in metrics){
  
  rs <- raster(paste0(oDir_files, "/", var , "_ann_", per, "_", rcp, "_ensemble_", metric,".tif"))

  myTheme <- BuRdTheme() # Define squeme of colors

  if (var == "tmean"){ 
    
    if (metric == "std"){
      unit = "°C"
      zvalues <- seq(0, 1, 0.05) # Define limits  
      myTheme=rasterTheme(region=brewer.pal('Greys', n=length(zvalues)-1)) 
    } else {
      unit = "°C"
      zvalues <- seq(0, 3, 0.2) # Define limits
      myTheme=rasterTheme(region=brewer.pal('OrRd', n=length(zvalues)-1))  
    }
    
  } else {
    
    
    if (metric == "agreement"){
      rs <- rs /18
      unit = "Int"
      zvalues <- seq(0, 1, 0.1) # Define limits  
      myTheme=rasterTheme(region=brewer.pal('Greys', n=length(zvalues)-1))
    } else {
      rs <- rs * 100
      unit = "%"
      zvalues <- seq(-40, 40, 1) # Define limits
      myTheme=rasterTheme(region=brewer.pal('RdBu', n=length(zvalues)-1))
    }
    
  }
  
  plot <- setZ(rs, metric)
  names(plot) <- metric
  
  myTheme$strip.border$col = "white"
  myTheme$axis.line$col = 'white'
 
  tiff(paste(oDir, "/", var , "_ann_", per, "_", rcp, "_ensemble_", metric, ".tif", sep=""), width=1800, height=1200, pointsize=8, compression='lzw',res=200)
  
  print(levelplot(plot, at = zvalues, 
                  scales = list(draw=FALSE), 
                  # layout=c(2, 2), 
                  xlab="", 
                  ylab="", 
                  par.settings = myTheme, 
                  margin=F,
                  colorkey = list(space = "bottom", width=1.6, height=1, labels=list(cex=1.2)))
        + layer(sp.polygons(limits, lwd=0.8))
  )
  
  dev.off()
  
}



###########################
#### 01 Across RCP/GCM ####
###########################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)
require(ggplot2)

rcpLs <- c("rcp26", "rcp45","rcp60","rcp85")
anomDir <- "W:/05_downscaling_hnd/anomalies_v2"
perLs <- c("2020_2049","2040_2069","2070_2099")
mask <- raster("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/hnd_msk.tif")
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/evaluation/uncertainties"

anomVals <- c()

for(rcp in rcpLs){
 
  gcmList <- list.dirs(paste0(anomDir, "/", rcp), recursive = FALSE, full.names = FALSE)

  for (gcm in gcmList){
    
    for (per in perLs){
      
      cat(rcp, gcm, per)
      
      tx <- mask(crop(stack(paste0(anomDir, "/", rcp, "/", gcm, "/", per, "/tmax_res.nc")), mask), mask)
      tn <- mask(crop(stack(paste0(anomDir, "/", rcp, "/", gcm, "/", per, "/tmin_res.nc")), mask), mask)
      pr <- mean(cellStats(mask(crop(stack(paste0(anomDir, "/", rcp, "/", gcm, "/", per, "/prec_res.nc")), mask), mask), 
                      stat='mean', na.rm=TRUE) * 100)
      
      tm <- mean(cellStats(( tx + tn ) / 2, stat='mean', na.rm=TRUE) )
      
      anomVals <- rbind(anomVals, cbind(rcp, per, "prec", gcm, pr) )
      anomVals <- rbind(anomVals, cbind(rcp, per, "tmean", gcm, tm) )
      
    }
    
  }
  
}


colnames(anomVals) <- c("RCP", "Period", "Variable", "GCM", "Value")

write.csv(anomVals, paste0(oDir, "/anom_stats.csv"), row.names = F)


anomVals <- read.csv(paste0(oDir, "/anom_stats.csv"), header=T)

anomVals_pr <- anomVals[anomVals$Variable == "prec",]
anomVals_tm <- anomVals[anomVals$Variable == "tmean",]

anomVals_pr_mean <- aggregate(anomVals_pr$Value, by=list(RCP=anomVals_pr$RCP, PERIOD=anomVals_pr$Period), FUN = function(x) mean(x, na.rm=T))
anomVals_pr_p25 <- aggregate(anomVals_pr$Value, by=list(RCP=anomVals_pr$RCP, PERIOD=anomVals_pr$Period), FUN = function(x) quantile(x, probs = 0.25, na.rm=T))
anomVals_pr_p75 <- aggregate(anomVals_pr$Value, by=list(RCP=anomVals_pr$RCP, PERIOD=anomVals_pr$Period), FUN = function(x) quantile(x, probs = 0.75, na.rm=T))
anomVals_pr_sts <- cbind(anomVals_pr_mean[,1:2], MEAN=anomVals_pr_mean[,3], P25=anomVals_pr_p25[,3], P75=anomVals_pr_p75[,3])

anomVals_tm_mean <- aggregate(anomVals_tm$Value, by=list(RCP=anomVals_tm$RCP, PERIOD=anomVals_tm$Period), FUN = function(x) mean(x, na.rm=T))
anomVals_tm_p25 <- aggregate(anomVals_tm$Value, by=list(RCP=anomVals_tm$RCP, PERIOD=anomVals_tm$Period), FUN = function(x) quantile(x, probs = 0.25, na.rm=T))
anomVals_tm_p75 <- aggregate(anomVals_tm$Value, by=list(RCP=anomVals_tm$RCP, PERIOD=anomVals_tm$Period), FUN = function(x) quantile(x, probs = 0.75, na.rm=T))
anomVals_tm_sts <- cbind(anomVals_tm_mean[,1:2], MEAN=anomVals_tm_mean[,3], P25=anomVals_tm_p25[,3], P75=anomVals_tm_p75[,3])

anomPlotP <- paste0(oDir, "/prec_mean_p25-75.tif")

anomVals_pr_sts$YEAR = c(rep(2030, length(rcpLs)), rep(2050, length(rcpLs)), rep(2080, length(rcpLs)))
anomVals_pr_sts$RCP_name = rep(c("RCP 2.6", "RCP 4.5", "RCP 6.0", "RCP 8.5"), 3)

p <- ggplot() +
  geom_line(data=anomVals_pr_sts, aes(x=YEAR, y=MEAN, colour="band"), size=1.2) +
  geom_point(data=anomVals_pr_sts, aes(x=YEAR, y=MEAN, colour="band"), size=2) +
  geom_ribbon(data=anomVals_pr_sts, aes(x=YEAR, ymin=P25, ymax=P75, fill="navyblue"), alpha=0.5, size=0.2) +
  geom_hline(yintercept=0, linetype="dashed", color = "black", size=0.5) + 
  # theme(panel.background = element_rect(fill = 'gray97', linetype = "g", size = 0.2), legend.title=element_blank()) +
  theme_bw() +
  guides(fill=guide_legend(title=NULL), color=guide_legend(title=NULL), alpha=FALSE) +
  # scale_colour_brewer(palette="Blues") +
  # scale_fill_brewer(palette="Blues") +
  scale_color_manual("", values="royalblue4") +
  scale_fill_manual("", values="royalblue4") +
  theme(legend.position="none") +
  ylim(-30, 20) + 
  facet_wrap( ~ RCP_name, ncol=2) +
  labs(x="Periodos ", y="Anomalía (%)")

tiff(anomPlotP, width=1000, height=900, pointsize=8, compression='lzw',res=150)
plot(p)
dev.off()


anomPlotP <- paste0(oDir, "/tmean_mean_p25-75.tif")

anomVals_tm_sts$YEAR = c(rep(2030, length(rcpLs)), rep(2050, length(rcpLs)), rep(2080, length(rcpLs)))
anomVals_tm_sts$RCP_name = rep(c("RCP 2.6", "RCP 4.5", "RCP 6.0", "RCP 8.5"), 3)

p <- ggplot() +
  geom_line(data=anomVals_tm_sts, aes(x=YEAR, y=MEAN, colour="band"), size=1.2) +
  geom_point(data=anomVals_tm_sts, aes(x=YEAR, y=MEAN, colour="band"), size=2) +
  geom_ribbon(data=anomVals_tm_sts, aes(x=YEAR, ymin=P25, ymax=P75, fill="navyblue"), alpha=0.5, size=0.2) +
  # theme(panel.background = element_rect(fill = 'gray97', linetype = "g", size = 0.2), legend.title=element_blank()) +
  theme_bw() +
  guides(fill=guide_legend(title=NULL), color=guide_legend(title=NULL), alpha=FALSE) +
  # scale_colour_brewer(palette="Blues") +
  # scale_fill_brewer(palette="Blues") +
  scale_color_manual("", values="darkorange2") +
  scale_fill_manual("", values="darkorange3") +
  theme(legend.position="none") +
  ylim(0, 4.2) + 
  facet_wrap( ~ RCP_name, ncol=2) +
  labs(x="Periodos ", y="Anomalía (°C)")

tiff(anomPlotP, width=1000, height=900, pointsize=8, compression='lzw',res=150)
plot(p)
dev.off()

