# 20210324 Task Scheduling Automation from R
# https://cran.r-project.org/web/packages/taskscheduleR/readme/README.html
# 
# Task Scheduling on Demand
# =====================================
# with secure password management
# =====================================
#
# =====================================
# Script to deploy lazytrading tasks automatically
library(taskscheduleR)
library(secret)


#settings from options
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
who_user <-  normalizePath(Sys.getenv('USERPROFILE'), winslash = '/')
ncpu <- as.numeric(Sys.getenv('OPT_AML_NCPU'))
aml_score <- as.numeric(Sys.getenv('OPT_AML_PerMin'))
mt_score <-  as.numeric(Sys.getenv('OPT_MT_PerMin'))

opt_collect <- as.logical(Sys.getenv('OPT_AML_Collect'))
opt_change <- as.logical(Sys.getenv('OPT_AML_Change'))
opt_boost <- as.logical(Sys.getenv('OPT_AML_Boost'))
opt_simul  <- as.logical(Sys.getenv('OPT_AML_Simul'))
opt_rebuild  <- as.logical(Sys.getenv('OPT_AML_Rebuild'))

opt_mt_score <- as.logical(Sys.getenv('OPT_MT_Score'))

opt_test  <- as.logical(Sys.getenv('OPT_UTIL_Test'))
opt_news <-  as.logical(Sys.getenv('OPT_NEWS_UseNews'))
opt_restart <- as.logical(Sys.getenv('OPT_UTIL_Restart'))
opt_clean <- as.logical(Sys.getenv('OPT_UTIL_Clean'))

opt_rladapt  <- as.logical(Sys.getenv('OPT_RL_Adapt'))
opt_rlcontrol <-  as.logical(Sys.getenv('OPT_RL_Control'))

opt_drl <- as.logical(Sys.getenv('OPT_DRL_BuScDe'))
opt_drlexit <- as.logical(Sys.getenv('OPT_DRL_Exit'))


#keys management
path_keys <- file.path(who_user, ".ssh")

password <- secret::get_secret("pwrd",
                               key = file.path(path_keys, 'id_rsa'),
                               vault = file.path(path_user, "vault"))
usr <- secret::get_secret("user",
                          key = file.path(path_keys, 'id_rsa'),
                          vault = file.path(path_user, "vault"))

extra_parameters <- paste0("/RU ", usr, " ", "/RP ",password)
# =====================================
# Task: automate script collect data
# =====================================
script_name <- Sys.getenv('SCR_AML_Collect')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_collect")

if (opt_collect) {
  
  ## Setup task
  taskscheduler_create(taskname = "dss_aml_collect", rscript = path_script,
                       schedule = "HOURLY",
                       starttime = "00:05",
                       days = c("MON", "TUE", "WED", "THU", "FRI"),
                       schtasks_extra = extra_parameters)
}

# =====================================
# Task: automate script ai model build test
# =====================================
script_name <- Sys.getenv('SCR_AML_TestBuild')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_test_build")

if (opt_rebuild) {
  ## Setup task
  taskscheduler_create(taskname = "dss_aml_test_build", rscript = path_script,
                       schedule = "WEEKLY",
                       starttime = "05:01",
                       days = "SAT",
                       schtasks_extra = extra_parameters)
  
}

# =====================================
# Task: automate script ai SCR_AML_Score
# =====================================
script_name <- Sys.getenv('SCR_AML_Score')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_score")

if (opt_change) {
  ## Setup task
  taskscheduler_create(taskname = "dss_aml_score", rscript = path_script,
                       schedule = "MINUTE",
                       starttime = "00:01",
                       modifier = aml_score,
                       days = c("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"),
                       schtasks_extra = extra_parameters)
  
}

# =====================================
# Task: automate script ai SCR_AML_Boost
# =====================================
script_name <- Sys.getenv('SCR_AML_Boost')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_boost")

## Setup task
if(opt_boost){
taskscheduler_create(taskname = "dss_aml_boost", rscript = path_script,
                     schedule = "HOURLY",
                     starttime = "00:40",
                     days = c("MON", "TUE", "WED", "THU", "FRI"),
                     schtasks_extra = extra_parameters) }
# =====================================
# Task: automate script ai mt_stat_score
# =====================================
script_name <- Sys.getenv('SCR_MT_Score')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_mt_score")

if (opt_mt_score) {
  ## Setup task
  taskscheduler_create(taskname = "dss_mt_score", rscript = path_script,
                       schedule = "MINUTE",
                       starttime = "00:05",
                       modifier = mt_score,
                       days = c("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"),
                       schtasks_extra = extra_parameters) 
}


# =====================================
# Task: automate script SCR_DRL_BuildScore
# =====================================
script_name <- Sys.getenv('SCR_DRL_BuildScore')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_drl_build_score")

if (opt_drl) {
  ## Setup task
  taskscheduler_create(taskname = "dss_drl_build_score", rscript = path_script,
                       schedule = "MINUTE",
                       starttime = "00:01",
                       modifier = aml_score,
                       days = c("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"),
                       schtasks_extra = extra_parameters)
  
}

# =====================================
# Task: automate script SCR_DRL_Exit
# =====================================
script_name <- Sys.getenv('SCR_DRL_Exit')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_drl_exit")

if (opt_drlexit) {
  ## Setup task
  taskscheduler_create(taskname = "dss_drl_exit", rscript = path_script,
                       schedule = "MINUTE",
                       starttime = "00:06",
                       modifier = aml_score,
                       days = c("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"),
                       schtasks_extra = extra_parameters)
  
}


# =====================================
# Task: automate script news check events
# =====================================
script_name <- Sys.getenv('SCR_NEWS_Check')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_news_check")

## Setup task
if(opt_news){
taskscheduler_create(taskname = "dss_news_check", rscript = path_script,
                     schedule = "HOURLY",
                     starttime = "00:20",
                     days = c("MON", "TUE", "WED", "THU", "FRI"),
                     schtasks_extra = extra_parameters) }

# =====================================
# Task: automate script news read events
# =====================================
script_name <- Sys.getenv('SCR_NEWS_Read')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_news_read")

## Setup task
if(opt_news){
taskscheduler_create(taskname = "dss_news_read", rscript = path_script,
                     schedule = "DAILY",
                     starttime = "00:25",
                     days = c("MON", "WED", "FRI"),
                     schtasks_extra = extra_parameters) }

# =====================================
# Task: automate script rl trade trigger
# =====================================
script_name <- Sys.getenv('SCR_RL_Trigger')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_rl_trigger")

if (opt_rlcontrol) {
  ## Setup task
  taskscheduler_create(taskname = "dss_rl_trigger", rscript = path_script,
                       schedule = "HOURLY",
                       starttime = "00:30",
                       days = c("MON", "TUE", "WED", "THU", "FRI"),
                       schtasks_extra = extra_parameters)
}


# =====================================
# Task: automate script rl adapt control
# =====================================
script_name <- Sys.getenv('SCR_RL_Adapt')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_rl_adapt")

if (opt_rladapt) {
  ## Setup task
  taskscheduler_create(taskname = "dss_rl_adapt", rscript = path_script,
                       schedule = "DAILY",
                       starttime = "08:35",
                       days = c("MON", "TUE", "WED", "THU", "FRI"),
                       schtasks_extra = extra_parameters)
}



# =====================================
# Task: automate script util cleaning
# =====================================
script_name <- Sys.getenv('SCR_UTIL_Clean')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_util_clean")

if (opt_clean) {
## Setup task
taskscheduler_create(taskname = "dss_util_clean", rscript = path_script,
                     schedule = "WEEKLY",
                     starttime = "22:20",
                     days = "SAT",
                     schtasks_extra = extra_parameters)
}

# =====================================
# Task: automate script aml simulation
# =====================================
script_name <- Sys.getenv('SCR_AML_Simulate')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_simulate")

if (opt_simul) {
  

## Setup task
taskscheduler_create(taskname = "dss_aml_simulate", rscript = path_script,
                     schedule = "WEEKLY",
                     starttime = "00:05",
                     days = "SAT",
                     schtasks_extra = extra_parameters)
}
# =====================================
# Task: automate script Util System Test
# =====================================
script_name <- Sys.getenv('SCR_SYSTEM_Test')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_util_test")

if (opt_test) {
  ## Setup task
  taskscheduler_create(taskname = "dss_util_test", rscript = path_script,
                       schedule = "HOURLY",
                       starttime = "00:36",
                       days = c("MON", "TUE", "WED", "THU", "FRI"),
                       schtasks_extra = extra_parameters)
  
}

# =====================================
# Task: automate script Util Restart Terminal
# =====================================
script_name <- Sys.getenv('SCR_TERMINAL_Restart')
path_script <- file.path(path_user, "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_util_restart")

if (opt_restart) {
  ## Setup task
  taskscheduler_create(taskname = "dss_util_restart", rscript = path_script,
                       schedule = "WEEKLY",
                       starttime = "05:36",
                       days = "SUN",
                       schtasks_extra = extra_parameters)
  
}
# 
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



# =====================================
# All tasks
# =====================================
taskscheduler_ls()

