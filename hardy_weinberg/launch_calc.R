username <- Sys.getenv("USER")
os <- .Platform$OS.type
if (os == "windows") {
  j <- "FILEPATH"
  h <- "FILEPATH"
} else {
  j <- "FILEPATH"
  h <- "FILEPATH"
}

library(data.table)

task_id <- as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))
hw_map <- fread("FILEPATH/hw_param_map.csv")
output_me_id <- hw_map[task_id,output_me_id]
year_id <- hw_map[task_id,year_id]
args <- commandArgs(trailingOnly = TRUE)
output_directory <- args[1]
release_id <- args[2]
output_directory <- paste0(output_directory,output_me_id)

system(paste("FILEPATH/hw_launch_shell.sh",output_me_id,year_id,release_id,output_directory))