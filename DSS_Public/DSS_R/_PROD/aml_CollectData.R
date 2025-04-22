# ----------------------------------------------------------------------------------------
# R Script to collect (aggregate) the asset indicator data and respective prices
# ----------------------------------------------------------------------------------------
# (C) 2021, 2022 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# Make sure to setup Environmental Variables, see script DSS_Setup/set_environment.R
#
start_run <- Sys.time()
# load libraries to use and custom functions
 library(dplyr)
 library(readr)
 library(lubridate)
 library(lazytrade)
 library(magrittr)


#### Read asset prices and indicators ==========================================
#absolute path with the data (choose MT4 directory where files are generated)
path_terminal <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
path_repo <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')

#path with the setup info
path_setup <- file.path(path_repo, 'DSS_Bot', 'DSS_Setup')

#path with the data
path_data <- file.path(path_user, "_DATA")

#absolute path to store model objects (useful when scheduling tasks)
path_model <- file.path(path_user, "_MODELS")

# check if the directory exists or create
if(!dir.exists(path_data)){dir.create(path_data)}

# check if the directory exists or create
if(!dir.exists(path_model)){dir.create(path_model)}

## copy files from sub-folders into the _DATA folder!
# vector containing paths to the sub-folders
path_sub <- list.dirs(path_terminal,recursive = FALSE)
# copy/paste these folders to _DATA folder
file.copy(from = path_sub, to = path_data, recursive = TRUE, overwrite = TRUE)

#time frames used
timeframeHP <- as.numeric(Sys.getenv('OPT_AML_PerMin'))

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

## For input currently in production
#copy file with tick size info
file.copy(from = file.path(path_terminal, "TickSize_AI_RSIADX.csv"),
          to = file.path(path_data, "TickSize_AI_RSIADX.csv"),
          overwrite = TRUE)


# Writing indicator and price change to the file
for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
  # performing data collection
  indHP = file.path(path_terminal, paste0("AI_RSIADX",PAIR,timeframeHP,".csv")) %>%
    read_csv(col_names = FALSE, col_types = readr::cols())
  
  indHP$X1 <- ymd_hms(indHP$X1)  
  
  # data transformation using the custom function for one symbol
  aml_collect_data(indicator_dataset = indHP,
                   symbol = PAIR,
                   timeframe = timeframeHP,
                   path_data = path_best_data,
                   max_nrows = 2400)
  
  #full_path <- file.path(path_data, 'AI_RSIADXEURUSD60.rds')
  
  #x1 <- read_rds(full_path)
  
}


## For every sub-folder
path_data_sub <- list.dirs(path_data, full.names = TRUE, recursive = FALSE) 
  #remove folders 'control' and 'data_initial'
  if(!all(stringr::str_detect(path_data_sub, pattern = "control"))){
     path_data_sub <- path_data_sub %>% stringr::str_subset("control",negate = TRUE) 
    }
  if(!all(stringr::str_detect(path_data_sub, pattern = "data_initial"))){
    path_data_sub <- path_data_sub %>% stringr::str_subset("data_initial",negate = TRUE)
  } 
if(!all(stringr::str_detect(path_data_sub, pattern = "best_folder"))){
  path_data_sub <- path_data_sub %>% stringr::str_subset("best_folder",negate = TRUE)
}  
  
  
for (FOLD in path_data_sub) {
  #FOLD <- path_data_sub[9]
  # Writing indicator and price change to the file
  #copy file with tick size info
  file.copy(from = file.path(path_terminal, "TickSize_AI_RSIADX.csv"),
            to = file.path(FOLD, "TickSize_AI_RSIADX.csv"),
            overwrite = TRUE)

  for (PAIR in Pairs) {
    # PAIR <- "EURUSD"
    # performing data collection
    indHP = file.path(FOLD, paste0("AI_RSIADX",PAIR,timeframeHP,".csv")) %>%
      read_csv(col_names = FALSE, col_types = readr::cols())
    
    indHP$X1 <- ymd_hms(indHP$X1)  
    
    # data transformation using the custom function for one symbol
    aml_collect_data(indicator_dataset = indHP,
                     symbol = PAIR,
                     timeframe = timeframeHP,
                     path_data = FOLD,
                     max_nrows = 2400)
    
    ##test result:
    #full_path <- file.path(FOLD, 'AI_RSIADXEURUSD60.rds')
    #x1 <- read_rds(full_path)
    
  } #end of for loop for PAIR
  

} #end of for loop for FOLD


# outcome is series of files written to the _DATA/6_xx folders of the repository

end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run) #Time difference of 17.91803 secs

