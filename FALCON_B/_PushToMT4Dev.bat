rem Script to Deploy files from Version Control repository to Development Terminal
rem Use in case some content needs to be replaced (reverted from Version Control History)

@echo off
setlocal enabledelayedexpansion

:: Source Directory where Version Control Repository is located
set SOURCE_DIR="C:\Users\yunsi\Desktop\showcase\FALCON_B"
:: Destination Directory where Expert Advisor is located
set DEST_DIR="C:\Users\yunsi\AppData\Roaming\MetaQuotes\Terminal\0A89B723E9501DAD3F2D5CB4F27EBDAB\MQL4\Experts\04_FALCON_B"

ROBOCOPY %SOURCE_DIR% %DEST_DIR% *.mq4

