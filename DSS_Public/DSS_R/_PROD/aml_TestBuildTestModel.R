# ----------------------------------------------------------------------------------------
# R Script to build or update Deep Learning model for every Currency Pair
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

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
path_repo <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')

#path with the setup info
path_setup <- file.path(path_repo, 'DSS_Bot', 'DSS_Setup')

#settings from options
ncpu <- as.numeric(Sys.getenv('OPT_AML_NCPU'))
nhrs <- as.numeric(Sys.getenv('OPT_AML_TrainTimeHrs'))
dint <- as.numeric(Sys.getenv('OPT_AML_RetrainIntervTimeDays'))

#### Read asset prices and indicators ==========================================

#absolute path with the data
path_data <- file.path(path_user, "_DATA")

#absolute path to store model objects (useful when scheduling tasks)
path_model <- file.path(path_user, "_MODELS")

#path to store logs data (e.g. duration of machine learning steps)
path_logs <- file.path(path_user, "_LOGS")

# check if the directory exists or create
if(!dir.exists(path_model)){dir.create(path_model)}
if(!dir.exists(path_data)){dir.create(path_data)}
if(!dir.exists(path_logs)){dir.create(path_logs)}

# Vector of currency pairs used
Pairs <- readLines(file.path(path_setup, '5_pairs.txt')) %>% 
  stringr::str_split(pattern = ',') %>% unlist() 

#absolute path with the data (choose MT4 directory where files are generated)
path_terminal <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

##find which input is used?
#find character name of the input
best_input <- readr::read_csv(file.path(path_terminal, "AccountBestInput.csv")) %$% value 

#create sub-folder for best model
path_best_model <- file.path(path_model, best_input)
if(!dir.exists(path_best_model)){dir.create(path_best_model)}

#create sub-folder for best data
path_best_data <- file.path(path_data, best_input)
if(!dir.exists(path_best_data)){dir.create(path_best_data)}

## copy files from sub-folder into the _DATA/path_best_data folder!
sub_best_data <- file.path(path_terminal, best_input)
# copy/paste these folders to _SIM folder
res_copy <- file.copy(from = sub_best_data, to = path_data, recursive = TRUE, overwrite = TRUE)
# check that all went well during the copy process
if(all(res_copy) != TRUE){warning("Copy error, some folders were not copied")}
#time frames used
timeframeHP <- as.numeric(Sys.getenv('OPT_AML_PerMin'))

path_sbxm <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_sbxs <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')

#copy file with tick size info
file.copy(from = file.path(path_sbxm, "TickSize_AI_RSIADX.csv"),
          to = file.path(path_best_data, "TickSize_AI_RSIADX.csv"),
          overwrite = TRUE)

h2o.init(nthreads = ncpu)

for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
  # performing data collection
  indHP = file.path(path_best_data, paste0("AI_RSIADX",PAIR,timeframeHP,".csv")) %>%
    readr::read_csv(col_names = FALSE, col_types = cols())
  
  indHP$X1 <- ymd_hms(indHP$X1)  
  
  # data transformation using the custom function for one symbol
  aml_collect_data(indicator_dataset = indHP,
                   symbol = PAIR,
                   timeframe = timeframeHP,
                   path_data = path_best_data,
                   max_nrows = 2400)
  
  # performing Deep Learning Regression using the custom function
  aml_make_model(symbol = PAIR,
                 timeframe = timeframeHP,
                 path_model = path_best_model,
                 path_data = path_best_data,
                 force_update = TRUE,
                 objective_test = TRUE,
                 num_epoch = 100,
                 num_nn_options = 12,
                 num_bars_test = 600,
                 num_bars_ahead = 34,
                 num_cols_used = 0,
                 min_perf = 0)
  
  ##test result:
  #full_path <- file.path(FOLD, 'AI_RSIADXEURUSD15.rds')
  #x1 <- read_rds(full_path)
  
} #end of for loop for PAIR

#record time when the script starts to run
time_start <- Sys.time()



# Performing Testing => Building -> Testing...until specific condition is met


start_run <- Sys.time()



  # Performing Testing => Building -> Testing...
  for (PAIR in Pairs) {
    ## PAIR <- "EURUSD"

    # repeat testing and training several times
    aml_test_model(symbol = PAIR,
                   num_bars = 600,
                   timeframe = timeframeHP,
                   path_model = path_best_model,
                   path_data = path_best_data,
                   path_sbxm = path_sbxm,
                   path_sbxs = path_sbxs)
  }

  # function to consolidate results and write that to the files
  perf <- aml_consolidate_results(timeframe = timeframeHP,
                                  used_symbols = Pairs,
                                  path_model = path_best_model,
                                  path_sbxm = path_sbxm,
                                  path_sbxs = path_sbxs,
                                  min_quality = 0.4,
                                  get_quantile = TRUE)




 

# stop h2o engine
h2o.shutdown(prompt = F)


#record time when the script ended to run
time_end_M60 <- Sys.time()




#calculate total time difference in seconds
time_M60 <- difftime(time_end_M60,time_start,units="sec")

#convert to numeric
as.double(time_M60)

#setup a log dataframe
logs <- data.frame(dtm = Sys.time(), timerunM60 = time_M60)

#read existing log (if exists) and add there a new log data
if(!file.exists(file.path(path_logs, 'time_exec.rds'))){
  write_rds(logs, file.path(path_logs, 'time_exec.rds'))
} else {
  read_rds(file.path(path_logs, 'time_exec.rds')) %>% 
    bind_rows(logs) %>% 
    write_rds(file.path(path_logs, 'time_exec.rds'))
}

# outcome are the models files for each currency pair written to the folder /_MODELS


# function to consolidate results and write that to the files
aml_consolidate_results(timeframe = timeframeHP,
                        used_symbols = Pairs,
                        path_model = path_best_model,
                        path_sbxm = path_sbxm,
                        path_sbxs = path_sbxs,
                        min_quality = 0.4)

# function to write log to the _LOG folder
aml_consolidate_results(timeframe = timeframeHP,
                        used_symbols = Pairs,
                        path_model = path_best_model,
                        path_sbxm = path_sbxm,
                        path_sbxs = path_sbxs,
                        min_quality = 0.4,
                        get_quantile = FALSE,
                        log_results = TRUE,
                        path_logs = path_logs)


#set delay to insure h2o unit closes properly
Sys.sleep(5)

