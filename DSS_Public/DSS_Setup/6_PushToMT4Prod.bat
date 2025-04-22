rem Script to Deploy files from Version Control repository to All Terminals
rem Use when you need to publish all files to All Terminals

@echo off
setlocal enabledelayedexpansion

rem source code for mt4 robots
set SOURCE_DIR="%PATH_DSS_Repo%\DSS_Bot\DSS_Bots"
set DEST_DIR1="%PATH_T1_E%\DSS_Bot"
set DEST_DIR3="%PATH_T3_E%\DSS_Bot"

ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.mq4

rem source code for Include files
set SOURCE_DIR="%PATH_DSS_Repo%\Include"
set DEST_DIR1="%PATH_T1_I%"
set DEST_DIR3="%PATH_T3_I%"

ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.mqh
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.mqh

rem source code for Indicators
set SOURCE_DIR="%PATH_DSS_Repo%\Indicators"
set DEST_DIR1="%PATH_T1_T%\MQL4\Indicators"
set DEST_DIR3="%PATH_T3_T%\MQL4\Indicators"

ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.mq4

rem source code for mt4 robot WatchDog

set SOURCE_DIR="%USERPROFILE%\Documents\GitHub\WatchDog"
set DEST_DIR1="%PATH_T1_E%\WatchDog"
set DEST_DIR3="%PATH_T3_E%\WatchDog"

ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.mq4

rem write file with terminal code
echo 1 > "%PATH_T1%\terminal.csv"
echo 3 > "%PATH_T3%\terminal.csv"

rem copy cmd file to the Windows Startup Folder
rem run with admin privileges

set SOURCE_DIR="%USERPROFILE%\Documents\GitHub\AutoLaunchMT4"
set DEST_DIR="%PATH_STUP%"

ROBOCOPY %SOURCE_DIR% %DEST_DIR% *.cmd

