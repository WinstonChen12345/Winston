# ----------------------------------------------------------------------------------------
# R Script to 'hot update' worse performing Deep Learning model for one Asset
# ----------------------------------------------------------------------------------------
# (C) 2019,2021 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# Main idea: find the least performing model and update that model
# 
# 1. Read StrTest files
# 2. Combine all files and find symbol with least performing model
# 3. Update model
# 4. Test that model again
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

#time frames used
timeframeHP <- as.numeric(Sys.getenv('OPT_AML_PerMin'))
#### Read asset prices and indicators ==========================================
# Vector of currency pairs used
Pairs <- readLines(file.path(path_setup, '5_pairs.txt')) %>% 
  stringr::str_split(pattern = ',') %>% unlist()

#absolute path with the data
path_data <- file.path(path_user, "_DATA")

#absolute path to store model objects 
path_model <- file.path(path_user, "_MODELS")

#path to store logs data (e.g. duration of machine learning steps)
path_logs <- file.path(path_user, "_LOGS")

#absolute path with the data (choose MT4 directory where files are generated)
path_terminal <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

##find which input is used?
#find character name of the input
best_input <- readr::read_csv(file.path(path_terminal, "AccountBestInput.csv")) %$% value 

#create sub-folder for best model
path_best_model <- file.path(path_model, best_input)

#create sub-folder for best data
path_best_data <- file.path(path_data, best_input)

## Analysis of model quality records
# file names
filesToAnalyse1 <-list.files(path = path_best_model,
                             pattern = paste0("M",timeframeHP,".csv"),
                             full.names=TRUE)

# aggregate all files into one
for (VAR in filesToAnalyse1) {
  # VAR <- filesToAnalyse1[1]
  if(!exists("dfres1")){dfres1 <- readr::read_csv(VAR)}  else {
    dfres1 <- readr::read_csv(VAR) %>% dplyr::bind_rows(dfres1)
  }
  
}

# find which symbol has the lowest performance
symb_low <- dfres1 %>% slice(which.min(MaxPerf)) %$% Symbol 

print(symb_low)
perf_low <- dfres1 %>% slice(which.min(MaxPerf)) %$% MaxPerf

print(perf_low)
#time frames used
timeframeHP <- as.numeric(Sys.getenv('OPT_AML_PerMin'))

path_sbxm <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_sbxs <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')

#copy file with tick size info
file.copy(from = file.path(path_sbxm, "TickSize_AI_RSIADX.csv"),
          to = file.path(path_data, "TickSize_AI_RSIADX.csv"),
          overwrite = TRUE)

#record time when the script starts to run
time_start <- Sys.time()

h2o.init(nthreads = ncpu)

# test model for that symbol
PAIR <- symb_low
File_perf <- file.path(path_best_model, paste0("StrTest-", PAIR, "M",timeframeHP, ".csv"))

# do training/testing until the condition met
perf_updated <- -10000
time_max <- 500 #max 500 seconds approx 8 min
count_max <- 3 #max number of times to update model
count_init <- 0
# run until better model is created or training lasts longer than set time
while ((perf_updated < perf_low) && (count_init <= count_max)) {

  
  #train model
  aml_make_model(symbol = PAIR,
                 timeframe = timeframeHP,
                 path_model = path_best_model,
                 path_data = path_best_data,
                 force_update=FALSE,
                 objective_test = TRUE,
                 num_epoch = 100,
                 num_nn_options = 24,
                 num_bars_test = 600,
                 num_bars_ahead = 34,
                 num_cols_used = 0,
                 min_perf = 100000)
  #test model
  aml_test_model(symbol = PAIR,
                 num_bars = 600,
                 timeframe = timeframeHP,
                 path_model = path_best_model,
                 path_data = path_best_data,
                 path_sbxm = path_sbxm,
                 path_sbxs = path_sbxs)  
  #read results
  perf_updated <- readr::read_csv(File_perf) %$% MaxPerf
  print(perf_updated)
  time_act <- Sys.time()
  time_run <- difftime(time_act,time_start,units="sec") %>% as.numeric()
  print(time_run)
  count_init <- count_init + 1
  print(count_init)
  
}
  
  


for (PAIR in Pairs) {
  ## PAIR <- "EURUSD"
  
  # repeat testing and training several times  
  
  aml_test_model(symbol = PAIR,
                 num_bars = 600,
                 timeframe = 60,
                 path_model = path_best_model,
                 path_data = path_best_data,
                 path_sbxm = path_sbxm,
                 path_sbxs = path_sbxs)  

}

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
                        min_quality = 0.75)

# function to write log to the _LOG folder
aml_consolidate_results(timeframe = timeframeHP,
                        used_symbols = Pairs,
                        path_model = path_best_model,
                        path_sbxm = path_sbxm,
                        path_sbxs = path_sbxs,
                        min_quality = 0.75,
                        get_quantile = FALSE,
                        log_results = TRUE,
                        path_logs = path_logs)


#set delay to insure h2o unit closes properly
Sys.sleep(5)

