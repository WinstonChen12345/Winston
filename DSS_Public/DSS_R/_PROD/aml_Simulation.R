# ----------------------------------------------------------------------------------------
# R Script to simulate several inputs and determine the best input for aml algorithm
# ----------------------------------------------------------------------------------------
# (C) 2019,2022 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# Make sure to setup Environmental Variables, see script set_environment.R
#
# load libraries to use and custom functions
library(dplyr)
library(readr)
library(h2o)
library(lazytrade)
library(magrittr)
library(lubridate)
library(stats)

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')

#settings from options
ncpu <- as.numeric(Sys.getenv('OPT_AML_NCPU'))

#absolute path with the data (choose MT4 directory where files are generated)
path_terminal <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

#### Read asset prices and indicators ==========================================

#absolute path with the data
path_sim <- file.path(path_user, "_SIM")

# check if the directory exists or create
if(!dir.exists(path_sim)){dir.create(path_sim)}

## copy files from sub-folders into the _SIM folders!
# vector containing paths to the sub-folders
path_sub <- list.dirs(path_terminal,recursive = FALSE)
# copy/paste these folders to _SIM folder
res_copy <- file.copy(from = path_sub, to = path_sim, recursive = TRUE, overwrite = TRUE)
# check that all went well during the copy process... res_copy[3] <- FALSE
if(all(res_copy) != TRUE){warning("Copy error, some folders were not copied")}else{
                          warning("All folders were copied")}

#time frames used
timeframeHP <- as.numeric(Sys.getenv('OPT_AML_PerMin'))

#record time when the script starts to run
time_start <- Sys.time()

# directories we will use for simulations
dirs_sim <- list.dirs(path_sim,recursive = FALSE)

h2o.init(nthreads = ncpu)


# Performing Testing => Building -> Testing..
for (DIR in dirs_sim) {
  ## DIR <- dirs_sim[1]

  #simulate different amount of num_epoch for model
  numBars <- c(4,8)
  VectorSim <- 0
  for (SIMS in VectorSim) {
    # SIMS <- VectorSim[1]
  
    file.copy(from = file.path(path_terminal,"TickSize_AI_RSIADX.csv"),
              to = file.path(DIR, "TickSize_AI_RSIADX.csv"), overwrite = TRUE)

      # file.copy(from = file.path(DIR, "_DATA","TickSize_AI_RSIADX.csv"),
  #           to = file.path(DIR, "TickSize_AI_RSIADX.csv"), overwrite = TRUE)
    
    # run this simulation 
  # data transformation using the custom function for one symbol
  aml_simulation(timeframe = timeframeHP, 
                 path_sim_input = DIR,
                 path_sim_result = path_sim,
                 par_simulate1 = 100,
                 par_simulate2 = SIMS,
                 demo_mode = FALSE)
    
  # once simulation is done we will copy folder with Models into separate location
  curr_folder <- file.path(DIR,"_MODELS")
  new_folder <- file.path(DIR,paste0("_SIM_OUT", SIMS))
  if(!dir.exists(new_folder)) {dir.create(new_folder)}
  list_of_files <- list.files(curr_folder)
  file.copy(file.path(curr_folder, list_of_files), new_folder, overwrite = TRUE)
    
  }

}  
  

 # stop h2o engine
h2o.shutdown(prompt = F)


#set delay to insure h2o unit closes properly
Sys.sleep(5)

## Analyse results of simulation:
# read result file 'all_results.rds'
all_results <- read_rds(file.path(path_sim, "all_results.rds"))
todays_results <- all_results %>% 
  dplyr::filter(TimeTest >= time_start)
# find the index of the best folder
best_folder <- dirs_sim[which.max(todays_results$MeanPerf)]
# find the folder name string
b_folder <- stringr::str_remove(best_folder, path_sim) %>% stringr::str_remove(pattern = "/") %>% as_tibble()
# write the best folder name into DSS
readr::write_csv(b_folder, file.path(path_terminal, "AccountBestInput.csv"))


#we have to avoid execution of this task again so this must be scheduled later:
## Delete task
taskscheduleR::taskscheduler_delete("dss_aml_simulate")


end_run <- Sys.time()
tot_run <- end_run - time_start
print(tot_run)
