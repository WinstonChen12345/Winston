# ----------------------------------------------------------------------------------------
# R Script to test results found during backtest
# ----------------------------------------------------------------------------------------
# (C) 2024 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# Make sure to setup Environmental Variables, see script set_environment.R
#
# Main idea to implement:
#' 1. MT4 robot writes key parameters during optimization passes 
#' 2. MT4 robot also writes order trade results
#' 3. The optimization is started from the Windows Task Scheduler (Weekly)
#' 4. R script is started soon after the optimization completed (Weekly)
#' 5. R script reads Settings file from the robot
#' 6. R script reads parameters logged during optimization
#' 7. R script reads trading results during optimization
#' 8. R script joins both parameters and trading results
#' 9. R script calculates best optimization result
#' 10.R script finds the best parameter
#' 11.R script overwrites the new setting
#' 12.R script writes new settings file to the MT4 folder
#' 13.R script deletes the files recorded during optimization
#' 14.Process repeats during another week
#' 15.Robots awaits the result of the backtest found in the procedure opt_PerformBacktesting.R
#' 16.Trades will only resume should the result of backtest indicates positive outcome
#'
# 
# load libraries to use and custom functions
library(dplyr)
library(readr)
library(magrittr)
library(lazytrade)


# -------------------------
# Define terminals path addresses, from where we are going to read/write data
# -------------------------
# terminal 1 path *** make sure to customize this path
path_T1 <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')
path_T1_E <- normalizePath(Sys.getenv('PATH_T3_E'), winslash = '/')
path_T1_I <- normalizePath(Sys.getenv('PATH_T3_I'), winslash = '/')
path_T1_P <- normalizePath(Sys.getenv('PATH_T3_P'), winslash = '/')
path_T1_te <- normalizePath(Sys.getenv('PATH_T3_te'), winslash = '/')
path_T1_tf <- normalizePath(Sys.getenv('PATH_T3_tf'), winslash = '/')

# path to cmd startup to start MT4 terminals
path_cmd <- normalizePath(Sys.getenv('PATH_STUP'), winslash = '/')
path_cmd <- file.path(path_cmd, "MetaTraderAutoLaunch.cmd")

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')

#path to folder with bat script
path_dss <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')


# Find backtest results (launch the bat script from R)
# Specify the path to your batch script
batch_script_path <- file.path(path_dss, "FALCON_D/AUTO_BACKTEST", "FalconDKillBacktestAndAutoLaunch.bat")

# Launch the batch script
system(batch_script_path, wait = TRUE)

# sleep 30 seconds to allow it to run ?
#Sys.sleep(30)

# Read order results
DFT1 <- try(import_data(path_T1_tf, "OrdersResultsT3.csv"), silent = TRUE)

# calculate profit factor
PrFactRes <- DFT1 %>%
  summarise(PnL = sum(Profit),
            NumTrades = n(),
            PrFact = util_profit_factor(Profit)) %>% 
  mutate(MagicNumber = DFT1$MagicNumber[1]) %>% 
#### DECIDE IF TRADING ON THE EA #### -----------------------------
# Last 10 orders on DEMO && pr.fact >= 1.6 start trade 
  mutate(IsEnabled = if_else(PrFact < 1.6, 0, 1)) %>% 
  select(MagicNumber, IsEnabled) %>% 
  # Write command "allow"
  write_command_via_csv(path_T1)


# Write decision to trade, e.g. if profit factor is greater than 1.6


# Erase files from the tester\files folder which was eventually used earlier
# Specify the paths to the files you want to remove
file1 <- file.path(path_T1_tf, "OrdersResultsT3.csv")
file2 <- file.path(path_T1_tf, "ParameterLog9142301.csv")
file3 <- file.path(path_T1_te, "history", "GBPUSD60_2.fxt")

# If any of the files exist, remove them
if (file.exists(file1)) { file.remove(file1)}
if (file.exists(file2)) { file.remove(file2)}
if (file.exists(file3)) { file.remove(file3)}

# Start up terminals using cmd file in startup folder
# Use shell() to run the script through CMD with explicit quoting
result <- shell(paste("cmd.exe /c", shQuote(path_cmd)), intern = TRUE)

print(result)
