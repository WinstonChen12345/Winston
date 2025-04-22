# 20210324 Task Scheduling Automation from R
# https://cran.r-project.org/web/packages/taskscheduleR/readme/README.html
#
# =====================================
# Script to deploy lazytrading tasks automatically
library(taskscheduleR)
library(secret)
# =====================================
# secure password management
# =====================================
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
who_user <-  normalizePath(Sys.getenv('USERPROFILE'), winslash = '/')
path_keys <- file.path(who_user, ".ssh")

password <- secret::get_secret("pwrd",
                               key = file.path(path_keys, 'id_rsa'),
                               vault = file.path(path_user, "vault"))
usr <- secret::get_secret("user",
                          key = file.path(path_keys, 'id_rsa'),
                          vault = file.path(path_user, "vault"))

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
# Delete all tasks
# =====================================
taskscheduler_delete("dss_aml_collect")
taskscheduler_delete("dss_aml_new_build")
taskscheduler_delete("dss_aml_score")
taskscheduler_delete("dss_aml_boost")
taskscheduler_delete("dss_mt_score")
taskscheduler_delete("dss_news_check")
taskscheduler_delete("dss_news_read")
taskscheduler_delete("dss_rl_trigger")
taskscheduler_delete("dss_rl_adapt")
taskscheduler_delete("dss_drl_build_score")
taskscheduler_delete("dss_drl_exit")
taskscheduler_delete("dss_util_test")
# =====================================
# All tasks
# =====================================
taskscheduler_ls()

