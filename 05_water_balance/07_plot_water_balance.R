### Plot resulting variables of the water balance
### Note: Do not use variable names that could be functions or masked variables of packages (e.g. "mask", "poly")
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

# Load libraries
require(raster)
require(rgdal)
require(maptools)
require(rasterVis)

# Network drive
net_drive = "Y:"

scenario = "rcp2.6_2030"
# scenario = "baseline"

# Arguments

#iDir <- paste0(net_drive, "/Inputs/WPS/Balance_Hidrico/climate_change/downscaled_ensemble/", scenario)
#iDir <- paste0(net_drive, "/Inputs/WPS/Balance_Hidrico/shared") # This line goes with line # 16
#varLs <- c("prec", "eto", "tmax", "tmin", "tmean")
#varRs <- c("Precipitación", "Evapotranspiración de Referencia", "Temperatura Máxima", "Temperatura Mínima", "Temperatura Promedio")

iDir <- paste0(net_drive, "/Outputs/WPS/Balance_Hidrico/thornthwaite_and_mather/", scenario)
varLs <- c("aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield")
varRs <- c("Evapotranspiración Real", "Precipitacón Efectiva", "Percolación", "Escorrentía Superficial", "Humedad del Suelo", "Flujo Base", "Aporte de Agua")

dicVar <- vector(mode="list", length=length(varLs))
names(dicVar) = varLs
subtitle = "2000-2014"
cc_sce = c("rcp2.6_2030", "rcp2.6_2050", "rcp8.5_2030", "rcp8.5_2050")

if (scenario %in% cc_sce){
  split_text = strsplit(scenario, "_")[[1]]
  subtitle = paste0(toupper(split_text[1]), " ", split_text[2])
}

for (i in 1:length(varLs)){
  dicVar[[i]] <- varRs[i]
}

oDir <- paste0(net_drive, "/Outputs/WPS/Balance_Hidrico/maps/", scenario)
mask_shp <- paste0(net_drive, "/06_analysis/Scenarios/masks/ZOI.shp")

months = c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")

# Temporal folder for raster calculations
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir= paste0(oDir, "/tmp"))

# Read ZOI
poly_shp <- readOGR(mask_shp, layer= "ZOI")

# For monthly timescale (average)
for (var in varLs){
  
  if (var %in% c("tmax", "tmin", "tmean")){
    # Define symbology of yellow/reds. Number of intervals has to be equal to length(zvalues)-1
    mytheme = rasterTheme(region = brewer.pal(9, "YlOrRd"))
    units = "ºC"
  }
  else{
    # Define symbology of blues. Number of intervals has to be equal to length(zvalues)-1
    mytheme = rasterTheme(region = brewer.pal(9, "Blues"))
    units = "mm"
  }
  
  #mytheme$strip.border$col = "white"  # Eliminate frame from maps
  mytheme$axis.line$col = 'white'  # Eliminate frame from maps
  
  # Raster stack
  rs_stk <- stack(paste0(iDir, "/", var, "/",  var, "_month_", 1:12, ".tif"))
  
  cat(var, "\n")

  # Crop and mask raster stack
  #rs_stk_crop <- crop(rs_stk, extent(poly_shp))
  #extent(rs_stk_crop) <- extent(poly_shp)
  rs_stk_crop <- mask(crop(rs_stk, extent(poly_shp)), poly_shp)
  names(rs_stk_crop) = months

  # Minimum and maximum values of the stack raster
  min.value = min(minValue(rs_stk_crop))
  max.value = max(maxValue(rs_stk_crop))
  zvalues =  seq(min.value, max.value, length.out = 10)
  
  # plot title
  plot.title = paste0(dicVar[var], " (", units, ")\n", subtitle)
  
  # Save plot as Tiff
  image = file.path(oDir, paste0(var, "_monthly.tiff"))
  tiff(
    file = image,
    width = 4000,
    height = 2800,
    res = 300,
    compression ='lzw')

  # scales=list(draw=FALSE) for no labels
  lvl.plot = levelplot(rs_stk_crop, at= zvalues, scales=list(draw=FALSE), par.settings=mytheme, main=plot.title)
  
  print(lvl.plot  + layer(sp.polygons(poly_shp)))

  dev.off()
}

# Delete temp files
unlink(rasterOptions()$tmpdir, recursive=TRUE)
