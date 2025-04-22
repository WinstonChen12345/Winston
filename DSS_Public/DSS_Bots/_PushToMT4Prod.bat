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

rem source code for include files
set SOURCE_DIR="%PATH_DSS_Repo%\Include"
set DEST_DIR1="%PATH_T1_I%"
set DEST_DIR3="%PATH_T3_I%"

ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.mqh
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.mqh



