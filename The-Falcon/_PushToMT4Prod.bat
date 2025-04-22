rem Script to Deploy files from Version Control repository to All Terminals
rem Use when you need to publish all files to All Terminals

@echo off
setlocal enabledelayedexpansion

set SOURCE_DIR="C:\Users\yunsi\Desktop\showcase\The-Falcon"
set DEST_DIR1="%PATH_T1_E%\The-Falcon"
set DEST_DIR2="%PATH_T2_E%\The-Falcon"
set DEST_DIR3="%PATH_T3_E%\The-Falcon"
set DEST_DIR4="%PATH_T4_E%\The-Falcon"

ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR2% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR4% *.mq4



