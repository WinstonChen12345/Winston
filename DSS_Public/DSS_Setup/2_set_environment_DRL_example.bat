::# ----------------------------------------------------------------------------------------
::# Environmental Variables for Lazytrade System
::# ----------------------------------------------------------------------------------------
::# User Environmental Variables
::# Check in: Computer Properties -> Advanced System Settings -> Environmental Variables -> User Variables

:: Defined Options
setx OPT_AML_NCPU 2
setx OPT_AML_PerMin 15
setx OPT_AML_TrainTimeHrs 8
setx OPT_AML_RetrainIntervTimeDays 14
setx OPT_MT_PerMin 60

setx OPT_AML_Collect FALSE
setx OPT_AML_Change FALSE
setx OPT_AML_Boost FALSE
setx OPT_AML_Simul FALSE
setx OPT_AML_Rebuild FALSE

setx OPT_MT_Score FALSE

setx OPT_RL_Adapt FALSE
setx OPT_RL_Control FALSE

:: DRL Options 
setx OPT_DRL_BuScDe TRUE
setx OPT_DRL_Exit TRUE

setx OPT_DRL_Tokyo TRUE
setx OPT_DRL_London TRUE
setx OPT_DRL_NewYork TRUE

setx OPT_UTIL_Test FALSE
setx OPT_NEWS_UseNews FALSE
setx OPT_UTIL_Restart FALSE
setx OPT_UTIL_Email FALSE
setx OPT_UTIL_Clean TRUE

:: User Paths
setx PATH_DSS_Repo "%USERPROFILE%\Documents\GitHub"
setx PATH_DSS "%PATH_DSS_Repo%\DSS_Bot\DSS_R"
setx PATH_DSS_Bot "%PATH_DSS_Repo%\DSS_Bot\DSS_Bots\ACTIVE"
setx PATH_DSS_AutoLaunch %PATH_DSS_Repo%\AutoLaunchMT4

setx PATH_REXE "C:\Program Files\R\R-4.2.0\bin\Rscript.exe"
setx PATH_STUP "%USERPROFILE%"\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

setx PATH_T1_T "C:\Program Files (x86)\FxPro - Terminal1"
setx PATH_T1 "%PATH_T1_T%\MQL4\Files"
setx PATH_T1_E "%PATH_T1_T%\MQL4\Experts"
setx PATH_T1_I "%PATH_T1_T%\MQL4\Include"
setx PATH_T1_P "%PATH_T1_T%\MQL4\Presets"
setx PATH_T1_te "%PATH_T1_T%\tester"
setx PATH_T1_tf "%PATH_T1_T%\tester\files"

setx PATH_T3_T "C:\Program Files (x86)\FxPro - Terminal3"
setx PATH_T3 "%PATH_T3_T%\MQL4\Files"
setx PATH_T3_E "%PATH_T3_T%\MQL4\Experts"
setx PATH_T3_I "%PATH_T3_T%\MQL4\Include"
setx PATH_T3_P "%PATH_T3_T%\MQL4\Presets"
setx PATH_T3_te "%PATH_T3_T%\tester"
setx PATH_T3_tf "%PATH_T3_T%\tester\files"

setx SCR_AML_Collect "aml_CollectData.R"
setx SCR_AML_Simulate "aml_Simulation.R"
setx SCR_AML_Score "aml_ScoreData.R"
setx SCR_AML_Boost "aml_BoostModel.R"
setx SCR_AML_NewBuild "aml_ForceModelUpdate.R"
setx SCR_AML_TestBuild "aml_TestBuildTestModel.R"
setx SCR_MT_BuildModel "mt_stat_BuildModel.R"
setx SCR_MT_Score "mt_stat_Score_Data.R"
setx SCR_NEWS_Check "news_CheckMacroEvents.R"
setx SCR_NEWS_Read "news_ReadFxCalendar.R"
setx SCR_RL_Adapt "rl_Adapt_control.R"
setx SCR_RL_Trigger "rl_TradeTrigger.R"
setx SCR_DRL_BuildScore "drl_BuildScore.R"
setx SCR_DRL_Exit "drl_Exit.R"
setx SCR_TSK_Schedule "task_schedule.R"
setx SCR_TSK_Delete "task_delete.R"
setx SCR_UTIL_Clean "util_CleanTemp.R"
setx SCR_SYSTEM_Test "util_SystemTest.R"
setx SCR_TERMINAL_Restart "util_RestTerm.R"

setx UTIL_EMAIL_Sender "vz.home.experiments@gmail.com"
setx UTIL_EMAIL_Reciever "vladimir.zhbanko@gmail.com"
setx UTIL_EMAIL_Host "smtp.gmail.com"
setx UTIL_EMAIL_Port "465"

:: Terminal Account Numbers and Passwords as Environmental Variables
setx USR_T1 "888475107"
setx PS_T1 "!gWg2pG6SC"

setx USR_T2 "123457"
setx PS_T2 "2asdfojqioefj!"

setx USR_T3 "888475109"
setx PS_T3 "!RO1jjN1nH"

setx USR_T4 "123459"
setx PS_T4 "4asdfojqioefj!"

REM # Usage Example in the code
REM myHomeDir <- Sys.getenv("HOME")
REM Sys.getenv("PATH_T1")
REM Sys.getenv("PATH_REXE")
REM Sys.getenv("SCR_AML_Collect")
REM #======== Set Terminals Path
REM # NB: Don't use quotes, windows style
REM #' PATH_T1 - Path to the sandbox of Trading Terminal 1 
REM #' PATH_T2 - Path to the sandbox of Trading Terminal 2
REM #' PATH_T3 - Path to the sandbox of Trading Terminal 3
REM #' PATH_T4 - Path to the sandbox of Trading Terminal 4
REM #' PATH_T5 - Path to the sandbox of Trading Terminal 5
REM #'  
REM #' PATH_T1_E - Path to the Experts Folder of Trading Terminal 1 
REM #' PATH_T2_E - Path to the Experts Folder of Trading Terminal 2
REM #' PATH_T3_E - Path to the Experts Folder of Trading Terminal 3
REM #' PATH_T4_E - Path to the Experts Folder of Trading Terminal 4
REM #' PATH_T5_E - Path to the Experts Folder of Trading Terminal 5
REM #' 
REM #' PATH_T1_I - Path to the Include Folder of Trading Terminal 1 
REM #' PATH_T2_I - Path to the Include Folder of Trading Terminal 2
REM #' PATH_T3_I - Path to the Include Folder of Trading Terminal 3
REM #' PATH_T4_I - Path to the Include Folder of Trading Terminal 4
REM #' PATH_T5_I - Path to the Include Folder of Trading Terminal 5

REM #======== User Repository and folders
REM # NB: Don't use quotes, windows style
REM #' PATH_DSS - Path to the DSS_R Folder
REM #' PATH_DSS_Bot - Path to the DSS Bot setup files see script rl_TradeTrigger.R
REM #' PATH_DSS_Repo - Path to the users Version Control Folder

REM #======== Program Path
REM # NB: Use quotes, windows style
REM #' PATH_REXE - Path to Rscript.exe program 

REM #======== Script Names
REM #' SCR_AML_Collect - 'aml_CollectData.R'
REM #' SCR_AML_Score - 'aml_ScoreData.R'
REM #' SCR_AML_TestBuild - 'aml_TestBuildTestModel.R'
REM #' SCR_MT_BuildModel - 'mt_stat_BuildModel.R'
REM #' SCR_MT_Score - 'mt_stat_Score_Data.R'
REM #' SCR_NEWS_Read - 'news_CheckMacroEvents.R'
REM #' SCR_NEWS_Check - 'news_ReadFxCalendar.R'
REM #' SCR_RL_Adapt - 'rl_Adapt_control.R'
REM #' SCR_RL_Trigger - 'rl_TradeTrigger.R'
REM #' SCR_UTIL_Clean - 'util_CleanTemp.R'

