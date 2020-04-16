# Carlos Navarro 
# CIAT - CCAFS
# May 2018

###############################################
#### 01 Plots annual cycle current, future ####
###############################################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)
library(grid)
library(ggplot2)

anomDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/anomalies_ens_v2"
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/evaluation/by_regions_v3"

rcpLs <- c("rcp26","rcp45", "rcp60", "rcp85")
perLs <- c("2020_2049", "2040_2069", "2070_2099")
regions <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Regiones_Desarrollo_prj_v2.shp")
varLs <- c("prec", "tmean")

mt <- c()

if(!file.exists(paste0(oDir, "/annual_data_regions_v2.csv"))){
  
  for (i in 1:length(as.vector(regions$REGION)) ){
    
    for (var in varLs){
      
      rcpPer <- expand.grid(perLs, rcpLs)
      names(rcpPer) <- c("Period", "RCP")
        
      rg <- regions[regions$REGION == as.vector(regions$REGION)[i], ]

      anom <- stack(paste0(anomDir, "/", rcpPer[,2], "/", rcpPer[,1], "/", var, "_ann.tif"))
      anom_crop <- crop(mask(anom, rg), extent(rg))
    
      anom_stat <- cellStats(anom_crop, stat='mean', na.rm=TRUE)
      
      mt <- rbind(mt, cbind(rcpPer, 
                            as.vector(regions$REGION)[i], 
                            var, 
                            anom_stat 
                            )
                  )
      
    }
  }
  
  names(mt) <- c("Period", "RCP", "Region", "Variable","Median")
  write.csv(mt, paste0(oDir, "/annual_data_regions_v2.csv"), row.names = F)
  
}


annData <- read.csv(paste0(oDir, "/annual_data_regions_v2.csv"), header = T)

for (i in 1:length(as.vector(regions$REGION)) ){
  
  annData_rg <- annData[annData$Region == as.vector(regions$REGION)[i], ]
  annData_rg_var <- annData_rg[annData_rg$Variable  == "prec", ]
  
  annData_rg_var$Period <- as.factor(annData_rg_var$Period)

  p <- ggplot(annData_rg_var, aes(x=Period, y=Median, group=RCP, color=RCP)) +
    scale_color_manual(name="",
                        labels = c("RCP 2.6", "RCP 4.5", "RCP 6.0", "RCP 8.5"),
                       values=c("#0571b0","#92c5de","#f4a582", "#ca0020")) +
    geom_line(aes(color=RCP), size=0.9) +
    scale_x_discrete(labels=c("2020_2049" = "2030s", "2040_2069" = "2050s",
                                "2070_2099" = "2080s"),
                     expand = c(0.05, 0.05)) +
    ylim(-14, 9) +
    xlab("Periodo") + ylab("Cambio precipitación (%)") +
    theme_classic() +
    theme(text = element_text(size=8), legend.position="bottom", plot.margin = unit(c(1,1,1,0.5), "lines"), 
          legend.margin=margin(0,0,0,0), legend.box.margin=margin(-5,-5,-5,-5)) +
    geom_point(size=1.5)
  
  tiff(paste(oDir, "/plot_", as.vector(regions$REGION)[i], "_prec_annchg.tif", sep=""), width=400, height=400, pointsize=8, compression='lzw',res=150)
  plot(p)
  dev.off()

  annData_rg_var <- annData_rg[annData_rg$Variable  == "tmean", ]
  
  annData_rg_var$Period <- as.factor(annData_rg_var$Period)
  
  p <- ggplot(annData_rg_var, aes(x=Period, y=Median, group=RCP, color=RCP)) +
    scale_color_manual(name="",
                       labels = c("RCP 2.6", "RCP 4.5", "RCP 6.0", "RCP 8.5"),
                       values=c("#fed976","#fd8d3c","#e31a1c", "#800026")) +
    geom_line(aes(color=RCP), size=0.9) +
    scale_x_discrete(labels=c("2020_2049" = "2030s", "2040_2069" = "2050s",
                              "2070_2099" = "2080s"),
                     expand = c(0.05, 0.05)) +
    xlab("Periodo") + ylab("Cambio temperatura (°C)") +
    ylim(0, 4) +
    theme_classic() +
    theme(text = element_text(size=8), legend.position="bottom", plot.margin = unit(c(1,1,1,0.5), "lines"), 
          legend.margin=margin(0,0,0,0), legend.box.margin=margin(-5,-5,-5,-5)) +
    geom_point(size=1.5)
  
  tiff(paste(oDir, "/plot_", as.vector(regions$REGION)[i], "_tmean_annchg.tif", sep=""), width=400, height=400, pointsize=8, compression='lzw',res=150)
  plot(p)
  dev.off()
  
}
