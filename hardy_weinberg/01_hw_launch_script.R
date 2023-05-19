setwd("FILEPATH")

library(stringr)
library(data.table)

username <- Sys.getenv("USER")
os <- .Platform$OS.type
if (os == "windows") {
  j <- "FILEPATH"
  h <- "FILEPATH"
} else {
  j <- "FILEPATH"
  h <- "FILEPATH"
}

source("FILEPATH/get_demographics.R")
source("FILEPATH/submit_jobs.R") #jobmon alternative that submits array jobs
source("FILEPATH/hemog_id_queries.R") #source this file if you are curious about what each ME ID is and where it was derived from (examples shown below)


############################################
# 
# Step 1 - Load in modelable entity IDs to be run the HW script
#
# The me_id_map holds all of the ME IDs that will be run and their corresponding output IDs
#
############

#load in the modelable entity id map and review before submitting jobs to the cluster
me_id_map <- read.csv("FILEPATH/hw_me_map.csv")

#this function call returns the name of the modelable entity in the first row of the me_id_map
get_id_name(me_id_map$input_me_id[1],"me")

#this function call shows what bundles/MEs rely on the outputs from running 02_calc_hw.py
get_all_dependencies(me_id_map$input_me_id[1],"me")

#this function shows how the ME ID was derived
get_all_parents(me_id_map$input_me_id[5],"me")

############################################
# 
# Step 2 - Submit array job calculations 
#
# This workflow will parallelize each job by year ID and modelable entity ID, exporting get_draws data frames to .csv files in the output directory defined below within the function
#
############

run_hw <- function(release_id){
  
  #get the demographics needed for running all hardy weinberg draws by year
  hw_demographics <- get_demographics("epi",release_id = release_id)
  year_vec <- hw_demographics$year_id  #parallelize by location, supply all years
  
  #define the parameter map that will be used in the array jobs submission
  #we found that parallelizing by year_id and me_id returned all results in the least amount of time, where everything should finish within ~5 minutes once started on the cluster
  param_map <- as.data.frame(expand.grid(year_vec,unique(me_id_map$output_me_id)))
  colnames(param_map) <- c("year_id","output_me_id")
  write.csv(param_map,"hw_param_map.csv",row.names = F)
  
  #define where get_draws .csv files will be stored on the cluster
  output_directory <- paste0("FILEPATH/")
  out_me_id <- unique(me_id_map$output_me_id)
  for(me_id in out_me_id){
    temp_output_directory <- paste0(output_directory,me_id)
    if(dir.exists(temp_output_directory)){
      unlink(temp_output_directory,recursive = T)
    }
    dir.create(temp_output_directory)
  }
  
  #define cluster resources
  hw_log_output_dir <- paste0("FILEPATH/") #slurm output logs
  hw_log_errors_dir <- paste0("FILEPATH/") #slurm error logs
  launch_script <- "FILEPATH/launch_calc.R"
  job_name <- "hw_get_draws" #job names
  mem <- "4G" #memory
  threads <- 2 #threads
  max_concurrently_running <- nrow(param_map) #amount of jobs that can run at once
  run_time <- "00:30:00" #max run time
  partition <- "all.q" #queue
  
  #submit the job to the cluster
  hold_id <- submit_array_job(script = launch_script,
                   name = job_name,
                   queue = partition,
                   memory = mem,
                   threads = threads,
                   time = run_time,
                   n_jobs = nrow(param_map),
                   task_lim = max_concurrently_running,
                   error_dir = hw_log_errors_dir,
                   output_dir = hw_log_output_dir,
                   args = paste(output_directory,release_id))
  
  job_name <- "hw_save_epi"
  launch_script <- "FILEPATH/launch_save.R"
  mem <- "65G" #memory
  threads <- 25 #threads
  run_time <- "72:00:00" #max run time
  
  args_2_send <- paste(output_directory,release_id)
  
  submit_array_job(script = launch_script,
                   name = job_name,
                   queue = partition,
                   memory = mem,
                   threads = threads,
                   time = run_time,
                   n_jobs = length(out_me_id),
                   task_lim = max_concurrently_running,
                   error_dir = hw_log_errors_dir,
                   output_dir = hw_log_output_dir,
                   hold = hold_id,
                   args = args_2_send)
}

#run the function to submit hardy weinberg to the cluster here
run_hw(release_id = 9)
