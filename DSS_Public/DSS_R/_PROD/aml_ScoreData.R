# ----------------------------------------------------------------------------------------
# R Script to score the latest asset indicator data against Deep Learning model
# ----------------------------------------------------------------------------------------
# (C) 2019, 2021 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# Make sure to setup Environmental Variables, see script set_environment.R
#
#
start_run <- Sys.time()
# load libraries to use and custom functions
library(dplyr)
library(readr)
library(lubridate)
library(h2o)
library(magrittr)
library(lazytrade)

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
path_repo <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')
#path with the setup info
path_setup <- file.path(path_repo, 'DSS_Bot', 'DSS_Setup')

#### definition of paths and variables ==========================================
path_new_data <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_hist_data <- file.path(path_user, "_DATA")

#absolute path to store model objects (useful when scheduling tasks)
path_model <- file.path(path_user, "_MODELS")


#absolute path with the data (choose MT4 directory where files are generated)
path_terminal <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

##find which input is used?
#find character name of the input
best_input <- readr::read_csv(file.path(path_terminal, "AccountBestInput.csv")) %$% value 

#create sub-folder for best model
path_best_model <- file.path(path_model, best_input)
if(!dir.exists(path_best_model)){dir.create(path_best_model)}

# load prices of 28 currencies
path_sbxm <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_sbxs <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')

#time frames used
timeframeHP <- as.numeric(Sys.getenv('OPT_AML_PerMin'))

# Vector of currency pairs used
Pairs <- readLines(file.path(path_setup, '5_pairs.txt')) %>% 
  stringr::str_split(pattern = ',') %>% unlist()


# initialize the virtual machine
h2o.init(nthreads = 1)

for (PAIR in Pairs) {
  ## PAIR <- "EURUSD"
  
aml_score_data(symbol = PAIR,
               timeframe = timeframeHP,
               path_model = path_best_model,
               path_data = path_new_data,
               path_sbxm = path_sbxm,
               path_sbxs = path_sbxs)


}

# shutdown h2o
h2o.shutdown(prompt = F)

# outcome is series of files written to the sandboxes of each terminals


end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run) #Time difference of 27.05229 secs

