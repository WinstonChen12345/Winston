# 20210324 Task Scheduling Automation from R
# https://cran.r-project.org/web/packages/taskscheduleR/readme/README.html
#
# =====================================
# Script to deploy lazytrading tasks automatically
library(taskscheduleR)
library(secret)
# =====================================
# Common setup & secure password management
# =====================================
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
who_user <-  normalizePath(Sys.getenv('USERPROFILE'), winslash = '/')
# create your private/public keys (e.g. in R Studio)
path_keys <- file.path(who_user, ".ssh")
# decrypt credentials
password <- secret::get_secret("pwrd",
                               key = file.path(path_keys, 'id_rsa'),
                               vault = file.path(path_user, "vault"))
usr <- secret::get_secret("user",
                          key = file.path(path_keys, 'id_rsa'),
                          vault = file.path(path_user, "vault"))
## don't like to bother with security?
# usr <- ""
# password <- ""
extra_parameters <- paste0("/RU ", usr, " ", "/RP ",password)

# =====================================
# Task: automate script 
# =====================================
script_name <- Sys.getenv('SCR_TSK_Delete')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_tsk_delete")

## Setup task
taskscheduler_create(taskname = "dss_tsk_delete", rscript = path_script,
                     schedule = "WEEKLY",
                     starttime = "00:02",
                     days = "SAT",
                     schtasks_extra = extra_parameters)


# =====================================
# Task: automate script task_schedule
# =====================================
script_name <- Sys.getenv('SCR_TSK_Schedule')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_tsk_schedule")

## Setup task
taskscheduler_create(taskname = "dss_tsk_schedule", rscript = path_script,
                     schedule = "WEEKLY",
                     starttime = "22:20",
                     days = "SUN",
                     schtasks_extra = extra_parameters)

