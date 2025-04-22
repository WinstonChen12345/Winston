# ----------------------------------------------------------------------------------------
# R Script to build or update Deep Learning model for every Currency Pair
# ----------------------------------------------------------------------------------------
# (C) 2019, 2022  Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# load libraries to use and custom functions
library(dplyr)
library(magrittr)
library(readr)
library(h2o)
library(lazytrade)

#path to user repo:
#!!!Change this path!!! 
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
path_repo <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')

#path with the setup info
path_setup <- file.path(path_repo, 'DSS_Bot', 'DSS_Setup')

#settings from options
ncpu <- as.numeric(Sys.getenv('OPT_AML_NCPU'))

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

# Vector of currency pairs used
Pairs <- readLines(file.path(path_setup, '5_pairs.txt')) %>% 
  stringr::str_split(pattern = ',') %>% unlist()

#time frames used
timeframeHP <- as.numeric(Sys.getenv('OPT_AML_PerMin'))

#record time when the script starts to run
time_start <- Sys.time()

h2o.init(nthreads = ncpu)

# Writing indicator and price change to the file
for (PAIR in Pairs) {
  ## PAIR <- "EURUSD"
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

}  

time_end_M60 <- Sys.time()


# stop h2o engine
h2o.shutdown(prompt = F)


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

