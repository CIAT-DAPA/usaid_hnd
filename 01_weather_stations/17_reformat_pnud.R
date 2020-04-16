library(dplyr)

inDir = "C:/Users/lllanos/Desktop/all plot/monthly"
files_all = list.files(inDir, full.names = T, pattern = ".csv")
data_station= read.csv(files_all[1],header = T)
variable = substring(basename(files_all),1,4)
entidad = strsplit(basename(files_all),"_") %>% lapply(., `[[`, 3) %>% unlist %>% strsplit(.,"[.]")%>% lapply(., `[[`, 1) %>% unlist

Datos <- lapply(files_all,function(x){read.csv(x,header=T)})

object = Datos[[1]]
nomb_prec = substring(names(object[,-1:-3]),2,nchar(names(object[,-1:-3])))
nomb_s_prec = do.call("rbind",strsplit(nomb_prec,"_"))
name_st = paste0(nomb_s_prec[,2]," (",nomb_s_prec[,1],")")


pdf(paste0(inDir,"/",variable[1],"_",entidad[1],"_line_graph_all.pdf"))

n_plot = seq(4,(ncol(object)-3),3)

for(i in n_plot){
   
 
  par(mfrow = c(4,1),     # 2x2 layout
      oma = c(2, 2, 0, 0), # two rows of text at the outer left and bottom margin
      mar = c(4, 4, 3, 3), # space for one row of text at ticks and to separate plots
      xpd = NA)
  
  seg = i:(i+3)
  if(i == (ncol(object)-3)){ seg = i:ncol(object)}
  
  for(j in seg){
  plot(object[,j],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Precipitación (mm/día)",main = paste0("Estación ",name_st[j-3]),cex.lab=0.8)
  axis(1,at=seq(1,nrow(object),366),labels=seq(min(object$year),max(object$year),1),las=1,col="black",las =2,cex.axis = 0.8)
  axis(2,at=seq(min(object[,j],na.rm=T),max(object[,j],na.rm=T)+0.5,30),labels=seq(min(object[,j],na.rm=T),max(object[,j],na.rm=T)+0.5,30),las=1,col="black",las =1,cex.axis = 0.7)

  }
 
   
  
  
  }

dev.off()



