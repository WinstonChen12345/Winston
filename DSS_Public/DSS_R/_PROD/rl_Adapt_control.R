# This is a dedicated script for the Lazy Trading 4/6th Course: Statistical Analysis and Control of Trades
# Copyright (C) 2018,2020 Vladimir Zhbanko
# Preferrably to be used only with the courses Lazy Trading see: https://vladdsm.github.io/myblog_attempt/index.html
# https://www.udemy.com/course/your-trading-control-reinforcement-learning/?referralCode=7AB82127FC5C2334AE8D
# PURPOSE: Adapt RL control parameters and write them to the file
# METHOD: Sums of outcomes for each sets of control parameters are calculated to generate best set of control parameters
start_run <- Sys.time()
# packages used *** make sure to install these packages
library(readr)
library(dplyr)
library(lubridate) #install.packages("lubridate") 
library(ReinforcementLearning) #install.packages("ReinforcementLearning")
library(magrittr)
library(lazytrade) #install.packages("lazytrade")

# ----------- Main Steps -----------------
# -- Read trading results from Terminal 1
# -- Use function find control parameters to write best RL control parameters for every trading robot


# ----------- TESTS -----------------
# -- Select entire content of the script and execute
# -- Pass: Data object DFT1 contains observations
# -- Pass: DFT1_sum contains trades summary
# -- Pass: Files XXXXXXX.rds are generated in the folder _RL_MT/control
# -- Pass: 
# -- Fail: DFT1 class 'try-error'
# -- Fail: xxx

# -------------------------
# Define terminals path addresses, from where we are going to read/write data
# -------------------------
# terminal 1 path *** make sure to customize this path
path_T1 <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')

# path with folder containing control parameters
path_control_files = file.path(path_user, "_DATA/control")
# create this directory if that is not existing yet
if(!dir.exists(path_control_files)){dir.create(path_control_files)}
# -------------------------
# read data from trades in terminal 1
# -------------------------
# # uncomment code below to test functionality without MT4 platform installed
# DFT1 <- try(import_data(trade_log_file = "_TEST_DATA/OrdersResultsT1.csv",
#                         demo_mode = T),
#             silent = TRUE)
DFT1 <- try(import_data(path_T1, "OrdersResultsT1.csv"), silent = TRUE)

# Vector with unique Trading Systems
vector_systems <- DFT1 %$% MagicNumber %>% unique() %>% sort()

# For debugging: summarise number of trades to see desired number of trades was achieved
DFT1_sum <- DFT1 %>% 
  group_by(MagicNumber) %>% 
  summarise(Num_Trades = n(),
            Mean_profit = sum(Profit)) %>% 
  arrange(desc(Num_Trades))

### ============== FOR EVERY TRADING SYSTEM ###
for (i in 1:length(vector_systems)) {
  # tryCatch() function will not abort the entire for loop in case of the error in one iteration
  tryCatch({
    # execute this code below for debugging:
    # i <- 25 
    # i <- 12
    
    # extract current magic number id
  trading_system <- vector_systems[i]
  # get trading summary data only for one system 
  trading_systemDF <- DFT1 %>% filter(MagicNumber == trading_system)
  # try to extract market type information for that system
  DFT1_MT <- try(mt_import_data(path_sbxm = path_T1, 
                                system_number =  trading_system),
                 silent = TRUE)
  # go to the next i if there is no data
  if(class(DFT1_MT)[1]=="try-error") { next }
  # joining the data with market type info
  trading_systemDF <- inner_join(trading_systemDF, DFT1_MT, by = "TicketNumber")
  
  ## -- Go to the next Loop iteration if there is too little trades! -- ##
  if(nrow(trading_systemDF) < 5) { next }
  
  ## -- trim the dataset to have just 100 latest trades?
  
  #==============================================================================
  # Define state and action sets for Reinforcement Learning
  states <- c("BUN", "BUV", "BEN", "BEV", "RAN", "RAV")
  actions <- c("ON", "OFF") # 'ON' and 'OFF' are referring to decision to trade with Slave system

  # Define reinforcement learning parameters (see explanation below or in vignette)
  # -----
  # alpha - learning rate      0.1 <- slow       | fast        -> 0.9
  # gamma - reward rate        0.1 <- short term | long term   -> 0.9
  # epsilon - sampling rate    0.1 <- high sample| low sample  -> 0.9
  # iter 
  # ----- 
  # to uncomment desired learning parameters:
  # NOTE: more research is required to find best parameters TDL TDL TDL
  #control <- list(alpha = 0.5, gamma = 0.5, epsilon = 0.5)
  #control <- list(alpha = 0.9, gamma = 0.9, epsilon = 0.9)
  #control <- list(alpha = 0.7, gamma = 0.5, epsilon = 0.9)
  #control <- list(alpha = 0.3, gamma = 0.6, epsilon = 0.1) 
  
  # or to use optimal control parameters found by auxiliary function
  rl_write_control_parameters_mt(x = trading_systemDF, path_control_files = path_control_files)
  #cntrl <- read_rds(paste0(path_control_files, "/", trading_system, ".rds"))
  #cntrl <- read_rds(paste0(path_control_files, "/", 8139106, ".rds"))
  
  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
  
  
}
### ============== END of FOR EVERY TRADING SYSTEM ###

end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run)