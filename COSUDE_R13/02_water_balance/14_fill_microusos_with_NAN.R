### Fill microwatersheds-land use/land cover (Islas Cayos Pacifico) with values from the same microwatershed due to their small sizes
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

#scenario = "wettest_year"
#scenario = "baseline"
scenario = "rcp8.5_2050"

micro_nans = read.csv("V:/06_analysis/MicroUsos_withNAN.csv")

if (scenario %in% c("driest_year", "wettest_year")){
  wyield = read.csv(paste0("V:/06_analysis/Scenarios/", scenario, "/", scenario, "_wyield.csv"))
} else {
  wyield = read.csv(paste0("V:/06_analysis/Scenarios/", scenario, "/mth_avg_timeline_wyield_filled.csv"))
}

microusos = read.csv(paste0("V:/06_analysis/Scenarios/", scenario, "/mth_avg_timeline_microusos_wyield.csv"))

if("Ano" %in% colnames(wyield))
{
  wyield$Ano = NULL
}


# Check if there is at least one element of the first list not in the second list
if (!all((micro_nans$IDMicroUso %in% microusos$IDMicroUso))){
  # Get which microuses are not in the CSV file with data
  microuses_to_insert = micro_nans$IDMicroUso[(micro_nans$IDMicroUso %in% microusos$IDMicroUso) == FALSE]
  df_tmp = data.frame(sort(c(microuses_to_insert, microusos$IDMicroUso)))
  names(df_tmp)[1] = names(microusos)[1]
  microusos = merge(x = df_tmp, y = microusos, by = names(microusos)[1], all.x = TRUE)
}

for (i in 1:length(micro_nans$IDMicroUso)){
  micro_id = micro_nans$HydroID[i]

  cat(paste0("\tReplacing microuse ", micro_nans$IDMicroUso[i], " with ", micro_id, "\n"))
  data_to_use = wyield[wyield[,1] == micro_id,2:ncol(wyield)]
  microusos[microusos$IDMicroUso == micro_nans$IDMicroUso[i],2:ncol(microusos)] = data_to_use
}

cat("Writing csv file....\n")
# Final file is written as CSV
write.csv(microusos, paste0("V:/06_analysis/Scenarios/", scenario, "/mth_avg_timeline_microusos_wyield_filled.csv"), row.names = FALSE)