# ----------------------------------------------------------------------------------------
# Script to forcefully close and restart mt4 terminals
# ----------------------------------------------------------------------------------------
# (C) 2021 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4

library(magrittr)
library(tibble)
library(stringr)
library(dplyr)
library(lazytrade)

start_run <- Sys.time()

## Get PID of terminal.exe
# get tasks lists from OS:
tasks_running <- system("tasklist", intern = TRUE) 

#generate task kill command for this application
sys_command_kill <- util_find_pid(tasks_running = tasks_running,
                                  pid_pattern = 'terminal.exe')

## execute system calls on these tasks

# command should look like this:
# TASKKILL /PID [val] /PID [val] ... /F

## execute command...
#system(sys_command_kill)

Sys.sleep(10)

## Restart terminals
# path_startup <- normalizePath(Sys.getenv('PATH_STUP'), winslash = '/')
# shell.exec(file.path(path_startup, "MetaTraderAutoLaunch.cmd"))
# 
# cmd_command1 <- 'start "1" "C:\\Program Files (x86)\\FxPro - Terminal1\\terminal.exe" /portable "C:\\Users\\fxtrams\\Documents\\000_TradingRepo\\AutoLaunchMT4\\prod_T1.ini" '
# cmd_command2 <- 'start "2" "C:\\Program Files (x86)\\FxPro - Terminal2\\terminal.exe" /portable "C:\\Users\\fxtrams\\Documents\\000_TradingRepo\\AutoLaunchMT4\\prod_T2.ini" '
# cmd_command3 <- 'start "3" "C:\\Program Files (x86)\\FxPro - Terminal3\\terminal.exe" /portable "C:\\Users\\fxtrams\\Documents\\000_TradingRepo\\AutoLaunchMT4\\prod_T3.ini" '
# cmd_command4 <- 'start "4" "C:\\Program Files (x86)\\FxPro - Terminal4\\terminal.exe" /portable "C:\\Users\\fxtrams\\Documents\\000_TradingRepo\\AutoLaunchMT4\\prod_T4.ini" '
# 
# shell(cmd_command1) 
# Sys.sleep(20)
# shell(cmd_command2)
# Sys.sleep(10)
# shell(cmd_command3)
# Sys.sleep(10)
# shell(cmd_command4)
## Alternative way is to construct startup command inside R
#rem *************************************************
#  rem *** This starts the terminals after waiting 30 seconds ***
#  rem *************************************************

#  ping localhost -n 30
#start "1" "C:\Program Files (x86)\FxPro - Terminal1\terminal.exe" /portable "C:\Users\fxtrams\Documents\000_TradingRepo\AutoLaunchMT4\prod_T1.ini"
#start "2" "C:\Program Files (x86)\FxPro - Terminal2\terminal.exe" /portable "C:\Users\fxtrams\Documents\000_TradingRepo\AutoLaunchMT4\prod_T2.ini"
#start "3" "C:\Program Files (x86)\FxPro - Terminal3\terminal.exe" /portable "C:\Users\fxtrams\Documents\000_TradingRepo\AutoLaunchMT4\prod_T3.ini"
#start "4" "C:\Program Files (x86)\FxPro - Terminal4\terminal.exe" /portable "C:\Users\fxtrams\Documents\000_TradingRepo\AutoLaunchMT4\prod_T4.ini"
# 
# #exit
# cmd_T1_strt <- Sys.getenv('CMD_T1_STRT')
# 
# #this works
# system2("cmd", args = c("/c", "echo", "hello \"world\""))
# 
# #trying...
# dpath <- "C:\\Program Files (x86)\\FxPro - Terminal1\\terminal.exe"
# dport <- "/portable"
# dinit <- "C:\\Users\\fxtrams\\Documents\\000_TradingRepo\\AutoLaunchMT4\\prod_T1.ini"
# system2(command = "start", args = c("/k", "1", dpath, dport, dinit), wait = FALSE)
# 
# 
# test_cmd <- 'START "C:\\Program Files (x86)\\FxPro - Terminal1\\terminal.exe"'
# argument <- "C:\\Program Files (x86)\\FxPro - Terminal1\\terminal.exe"
# system2("start", args = argument,
#         wait = FALSE,
#         )

end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run)
