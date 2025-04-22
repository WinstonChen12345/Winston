rem Script to Deploy files from Version Control repository to Development Terminal
rem Use in case some content needs to be replaced (reverted from Version Control History)

@echo off
setlocal enabledelayedexpansion

set SOURCE_DIR="C:\Users\yunsi\Desktop\showcase\\Include"
set DEST_DIR="C:\Users\yunsi\AppData\Roaming\MetaQuotes\Terminal\0A89B723E9501DAD3F2D5CB4F27EBDAB\MQL4\Include"

ROBOCOPY %SOURCE_DIR% %DEST_DIR% *.mqh

pause