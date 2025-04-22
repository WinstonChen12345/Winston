# ----------------------------------------------------------------------------------------
# Forex News Reading from ff website. Interpretation of the results.
# ----------------------------------------------------------------------------------------
# Lazy Trading Course: Read news and Sentiment Analysis
# (C) 2018,2021 Vladimir Zhbanko
# https://www.udemy.com/course/forex-news-and-sentiment-analysis/?referralCode=2B76F54F1D33CF06B79C

# ---------------
# Run this script on Weekdays, Every 2 hours
# ---------------

# load libraries
library(dplyr)
library(readr)
library(magrittr)

####---------------
# read this week calendar in the folder _DATA

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')

#path trading terminals
path_sbxm <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_sbxs <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')

# read the table with pre-defined events
restrictedEvents <- read_csv(file.path(path_user, "_DATA/RestrictedEvents.csv"),
                             col_names = FALSE,col_types = 'c')


# read this calendar from the folder _DATA
cl_df <- read_rds(file.path(path_user, "_DATA/ff_calendar_thisweek.rds")) %>% 
  #convert to the fx server time
  mutate(DateTime = DateTime + 7200) %>% 
  #filter to remove too old events
  dplyr::filter(DateTime > Sys.time() - 3600) %>% 
  #arrange to keep next events on top
  arrange(DateTime) %>% 
  #keep just information about the next 3 hours
  filter(DateTime < Sys.time() + 3*3600) %>% 
  #detect if there are events with 'high' priority
  filter(Impact == 'High') %>% 
  #join with a pre-defined list
  inner_join(restrictedEvents, by = c("Title" = "X1"))
  

## write 'decision'
if (nrow(cl_df) != 0) {
  events <- data.frame(x = '1')
  write_csv(events, file.path(path_sbxm, '01_MacroeconomicEvent.csv'))
  write_csv(events, file.path(path_sbxs, '01_MacroeconomicEvent.csv'))

} else {
  events <- data.frame(x = '0')
  write_csv(events, file.path(path_sbxm, '01_MacroeconomicEvent.csv'))
  write_csv(events, file.path(path_sbxs, '01_MacroeconomicEvent.csv'))
}

