scenario = "rcp8.5_2050"
#scenario = "baseline"

iDir <- paste0("Y:/Water_Planning_System/Inputs/WPS/Balance_Hidrico/climate_change/downscaled_ensemble/", scenario, "/")
#iDir = "Y:/Water_Planning_System/Inputs/WPS/Balance_Hidrico/shared/"
#iDir = paste0("S:/10_outputs/WPS/Balance_Hidrico/thornthwaite_and_mather/", scenario, "/")
oDir = paste0("S:/10_outputs/WPS/Balance_Hidrico/maps/",  scenario, "/")

#------------------------------------------------------------------------------------
library(raster)
library(rgdal)
library(RColorBrewer)
library(rasterVis)
library(sp)
library(grDevices)
library(gridExtra)

zoi = shapefile("S:/06_analysis/Scenarios/mask/ZOI.shp")

# Diccionario con todas las posibles variables
dicVars <- cbind(c('prec', 'tmax', 'tmin', 'tmean', 'eto', 'runoff', 'eprec', 'aet', 'perc', 'sstor', 'bflow', 'wyield'),
                  c("Precipitación", "Temperatura Máxima", "Temperatura Mínima", "Temperatura Media", "Evapotranspiración Potencial", "Escorrentía Superficial",
                    "Precipitacón Efectiva", "Evapotranspiración Real", "Percolación", "Humedad del Suelo", "Flujo Base", "Aporte de Agua"))

# Variables a ser ploteadas (inputs)
vars = c("prec", "eto", "tmax", "tmin", "tmean")
#vars = "runoff"
#vars = c('prec', 'tmax', 'tmin')

# Variables a ser ploteadas (outputs)
#vars = c('eprec', 'aet', 'perc', 'sstor', 'bflow', 'wyield', 'runoff')

# Numbers of rows and columns for the distribution of the 12 months
n.rows <- 3
n.cols <- 4
n.months <- n.rows * n.cols 

# Meses
mth_txt = c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")
mth_lb = mth_txt[1:n.months]

split.vector = matrix(1:n.months, n.rows, n.cols, byrow=T)

subtitle = "2000-2014"
cc_sce = c("rcp2.6_2030", "rcp2.6_2050", "rcp8.5_2030", "rcp8.5_2050")

if (scenario %in% cc_sce){
  split_text = strsplit(scenario, "_")[[1]]
  subtitle = paste0(toupper(split_text[1]), " ", split_text[2])
}

for (i in 1:length(vars)){
  
  # Palabra clave
  keyword = vars[i]
  
  cat(paste0("Variable: ", keyword, "\n"))
  
  cat(paste0("Generando raster stack....\n"))
  # Genera stack de todas las capas y las plotea
  #raster_stack = stack(paste0(iDir, keyword, "/projected/", keyword, "_month_", 1:12, ".tif"))
  raster_stack = stack(paste0(iDir, keyword, "/", keyword, "_month_", 1:12, ".tif"))
  #plot(raster_stack)
  
  # Se definen los títulos como los meses
  names(raster_stack) = mth_lb
  
  cat(paste0("Cortando raster stack....\n"))
  # Se corta el raster stack de acuerdo al zoi
  raster_stack_mask = mask(crop(raster_stack, extent(zoi)), zoi)
  #raster_stack_mask = raster_stack
  
    # Definir unidades para el plot
  if (keyword == "tmax" || keyword == "tmin" || keyword == "tmean"){units = "ºC"; colorramp = "YlOrRd"}else{units = "mm"; colorramp = "Blues"}
  
  # Se define escala de colores para la simbología
  mytheme = rasterTheme(region = brewer.pal(4, colorramp))
  
  # Se obtiene el texto para el título de acuerdo a la variable analizada
  text_variable = dicVars[dicVars[,1] == keyword][2]

  # Título del plot
  plot_title = paste0(text_variable, " (", units, ")\n", subtitle)

  current_ext = extent(raster_stack_mask)
  ## For non projected datasets (geographical)
  # xmin = current_ext[1] - 0.009
  # xmax = current_ext[2] + 0.009
  # ymin = current_ext[3] - 0.009
  # ymax = current_ext[4] + 0.009
  
  ## For projected datasets
  xmin = current_ext[1] - 12000
  xmax = current_ext[2] + 12000
  ymin = current_ext[3] - 12000
  ymax = current_ext[4] + 12000
  
  p.list = list()
  
  for(l in 1:length(mth_lb)){
    month = mth_lb[l]
    
    # scales=list(draw=FALSE) para no labels
    plot_stack = levelplot(raster_stack_mask[[l]], xlim=c(xmin, xmax), ylim=c(ymin, ymax), scales=list(draw=FALSE), par.settings=mytheme, main=month, margin=F)
    
    s.arrow = 20000
    s.scale = 30000
    h.t.scale = 10000
    l.scale = "30 km"
    x.sh.scale = 32000
    y.sh.scale = 8000
    cex = 0.35

    cat(paste0("Ploteando - Mes ", l, " ....\n"))
    # Plotea stack con subcuencas y cuenca
    p.list[[l]] = plot_stack + layer(sp.polygons(zoi, fill='transparent', col='black', alpha=1)) + 
            layer({SpatialPolygonsRescale(layout.north.arrow(), offset = c(current_ext[1], current_ext[4]-10000),scale = s.arrow, which = 12)}) +
            layer({SpatialPolygonsRescale(layout.scale.bar(height=0.1), offset = c(current_ext[2]-x.sh.scale,current_ext[3]-y.sh.scale), scale = s.scale, fill=c("transparent","black"), which = 12)}) + 
            layer({sp.text(c(current_ext[2]-x.sh.scale, (current_ext[3]-y.sh.scale)+h.t.scale), "0", cex = cex, which = 12)})+
            layer({sp.text(c((current_ext[2]-x.sh.scale)+s.scale, (current_ext[3]-y.sh.scale)+h.t.scale), l.scale, cex = cex, which = 12)})
    
  }
  # Guardar plot como Tiff. Cambiar el nombre de la imagen
  image = file.path(oDir, paste0(keyword, "_monthly2.tif"))
  tiff(
    file = image,
    width = 1300,
    height = 900,
    pointsize = 8,
    compression = 'lzw',
    res = 150)
  
  grid.arrange(grobs=p.list, layout_matrix=split.vector, top=plot_title)
  
  dev.off()
}

