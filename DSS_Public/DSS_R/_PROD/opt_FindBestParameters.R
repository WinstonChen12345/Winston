# ----------------------------------------------------------------------------------------
# R Script to search optimal robot parameters
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
#' 8. R script joins both parametes and trading results
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
library(lubridate)

#record time when the script starts to run
time_start <- Sys.time()
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
# we modify path to have the file with the profiles
path_T1_pr <- sub("MQL4/Files$", "profiles", path_T1)
path_T1_pr <- file.path(path_T1_pr, "default")
# we modify path to have the file with the templates
path_T1_tmp <- sub("MQL4/Files$", "templates", path_T1)

# path to cmd startup to start MT4 terminals
path_cmd <- normalizePath(Sys.getenv('PATH_STUP'), winslash = '/')
path_cmd <- file.path(path_cmd, "MetaTraderAutoLaunch.cmd")

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')

#path to folder with bat script
path_dss <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')

# Find new parameters by optimization (launch the bat script from R)
# Specify the path to your batch script
batch_script_path <- file.path(path_dss, "FALCON_D/AUTO_BACKTEST", "FalconDKillOptimizeAndAutoLaunch.bat")

# Example: Temporarily disabling the firewall
#system("netsh advfirewall set allprofiles state off")

# Launch the batch script
system(batch_script_path, wait = TRUE)

# Re-enable the firewall
#system("netsh advfirewall set allprofiles state on")

# sleep 30 seconds to allow it to run ?
#Sys.sleep(30)

# Read order results
DFT1 <- try(import_data(path_T1_tf, "OrdersResultsT3.csv"), silent = TRUE)

# Read log with corresponding parameters
DF_Pars <- readr::read_csv(file.path(path_T1_tf, "ParameterLog9142301.csv"), 
                           col_names = c("MagicNumber",
                                         "TicketNumber",
                                         "OrderStartTime",
                                         "StartHour",
                                         "MinPipLimit",
                                         "UseMAFilter",
                                         "FastMAPeriod",
                                         "SlowMAPeriod",
                                         "RSI_NoBuyFilter",
                                         "RSI_NoSellFilter",
                                         "TimeMaxHold",
                                         "Buy_True",
                                         "Sell_True"))


DF_Pars$OrderStartTime <- lubridate::ymd_hms(DF_Pars$OrderStartTime)

# Combine columns from both datasets
matched_combined <- inner_join(DF_Pars, DFT1, by = c("OrderStartTime", "TicketNumber"))

# Group by StartHour and any other selected parameters, calculate summary statistics
summary <- matched_combined %>%
  group_by(StartHour, UseMAFilter) %>% # or group_by(StartHour, Par1) if more unique combinations of optimization
  summarize(
    MaxProfit = max(Profit),
    PnL = sum(Profit),
    NumRows = n(), # Calculate the number of rows in each StartHour group
    # Calculate profit factor with a check for zero sum of Profit
    ProfitFactor = util_profit_factor(Profit))  %>%
  arrange(desc(PnL)) # Sort by PnL column in descending order

# Find the best parameter StartHour
# Extract the StartHour value from the top row of the summary dataframe
#' test start_hour <- 7
start_hour <- summary$StartHour[1]
use_ma <- summary$UseMAFilter[1]


### ================ Update parameters in MT4
# Read parameters of the robot, 
# Robot settings are in C:\Program Files (x86)\FxPro - Terminal1\MQL4\Presets
# DF_presets <- read_lines(file.path(path_T1_P, 'Falcon_D.set'))

# A. In the .set file sandbox
file_i_need <- util_find_file_with_code(files = file.path(path_T1_P, 'Falcon_D.set'),
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "StartHour",
                                        v_values = start_hour)

file_i_need <- util_find_file_with_code(files = file.path(path_T1_P, 'Falcon_D.set'),
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "UseMAFilter",
                                        v_values = use_ma)



# B. In the .set file /tester (will be used for backtesting)
# DF_presets_tf <- read_lines(file.path(path_T1_te, 'Falcon_D.set'))
file_i_need <- util_find_file_with_code(files = file.path(path_T1_te, 'Falcon_D.set'),
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "StartHour",
                                        v_values = start_hour)

file_i_need <- util_find_file_with_code(files = file.path(path_T1_te, 'Falcon_D.set'),
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "UseMAFilter",
                                        v_values = as.integer(use_ma))


# D. In the .tpl file /templates (investigation)
#DF_presets_tp <- read_lines(file.path("C:/Program Files (x86)/FxPro - Terminal3/templates",
#                                      'Falcon_D_GBPUSD.tpl'))
file_i_need <- util_find_file_with_code(files = file.path(path_T1_tmp, 'Falcon_D_GBPUSD.tpl'),
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "StartHour",
                                        v_values = start_hour)

file_i_need <- util_find_file_with_code(files = file.path(path_T1_tmp, 'Falcon_D_GBPUSD.tpl'),
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "UseMAFilter",
                                        v_values = use_ma)

# E. In the .tpl file /profiles (investigation)

# there are several files each representing chart setup
# one file is the right one, we read all files and only use the one we identified

files_chr <- list.files(path = path_T1_pr, all.files = TRUE,
                        pattern = ".chr", full.names = TRUE)

file_i_need <- util_find_file_with_code(files = files_chr,
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "StartHour",
                                        v_values = start_hour)

file_i_need <- util_find_file_with_code(files = files_chr,
                                        code_to_find = 9142301,
                                        option_replace = TRUE,
                                        v_settings = "UseMAFilter",
                                        v_values = use_ma)



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

writeLines(result, file.path(path_user, "log.txt"))  # Log output for debugging

# alternative way:
# Starting terminals with parameters using *.ini files:
#  start "1" "%PATH_T1_T%\terminal.exe" /portable "%PATH_DSS_Repo%\AutoLaunchMT4\prod_T1.ini"

#start "3" "%PATH_T3_T%\terminal.exe" /portable "%PATH_DSS_Repo%\AutoLaunchMT4\prod_T3.ini"

# path_bat_script1 <- "C:\\Program Files (x86)\\FxPro - Terminal1\\terminal.exe /portable C:\\Users\\technik\\Documents\\GitHub\\AutoLaunchMT4\\prod_T1.ini"
# path_bat_script3 <- "C:\\Program Files (x86)\\FxPro - Terminal3\\terminal.exe /portable C:\\Users\\technik\\Documents\\GitHub\\AutoLaunchMT4\\prod_T3.ini"
# 
# system(sprintf('start "" "%s"', path_bat_script1), wait = FALSE, intern = TRUE)
# system(sprintf('start "" "%s"', path_bat_script3), wait = FALSE, intern = TRUE)



#calculate total time difference in seconds
time_end_M60 <- Sys.time()
time_M60 <- difftime(time_end_M60,time_start,units="sec")


