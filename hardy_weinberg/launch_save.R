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
library(stringr)

me_id_map <- data.table(fread("FILEPATH/hw_me_map.csv"))

task_id <- as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))
out_me_id_vec <- unique(me_id_map$output_me_id)
command_args <- commandArgs(trailingOnly = TRUE)
output_directory <- paste0(command_args[1],out_me_id_vec[task_id])
release_id <- command_args[2]
bundle_info <- me_id_map[output_me_id==out_me_id_vec[task_id],.(parent_bundle_id,xwalk_version,description)]
bundle_id <- bundle_info[1,parent_bundle_id]
xwalk_id <- bundle_info[1,xwalk_version]
memo <- str_replace_all(as.character(bundle_info[1,description])," ","_")

system_call <- paste("FILEPATH/hw_save_shell.sh",out_me_id_vec[task_id],bundle_id,xwalk_id,output_directory,release_id,memo)
print(system_call)

system(system_call)