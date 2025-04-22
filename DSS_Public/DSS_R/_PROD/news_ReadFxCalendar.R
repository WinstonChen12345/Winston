# ----------------------------------------------------------------------------------------
# Forex News Reading from ff website. Storing results.
# ----------------------------------------------------------------------------------------
# Lazy Trading Course: Read news and Sentiment Analysis
# (C) 2018,2021 Vladimir Zhbanko
# https://www.udemy.com/course/forex-news-and-sentiment-analysis/?referralCode=2B76F54F1D33CF06B79C

# ---------------
# Run this script on Sunday, Tue, Thu
# ---------------

# load libraries
library(dplyr)
library(readr)
library(magrittr)
library(rvest)
library(xml2)

####---------------
# summary of actions:
# import fx calendar of this week
# store this calendar in the folder _DATA

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')

#get the link to the calendar
path_fxf <- "https://www.forexfactory.com/calendar?week=this"
fxf <- path_fxf %>% read_html() %>% html_nodes(".sidebar__panel--calendarexports")
path_calendar <- xml2::xml_attrs(xml_child(xml_child(fxf[[1]], 2), 1))

# import calendar for this week
cal_df <- readr::read_csv(path_calendar)

# clean this data frame
cl_df <- cal_df %>% 
  mutate(DateTime = paste(Date, Time)) %>% 
  mutate(across('DateTime', ~ as.POSIXct(.x, format = "%m-%d-%Y %H:%M:%S"))) %>% 
  select(-c(Date, Time))

# ## reproducible example
# DF <- data.frame(Date = c("10/03/2014", "11/03/2014", "12/03/2014"),
#                  Time = c("12.00.00", "13.00.00", "14.00.00"))
# 
# DF_DT <- DF %>% 
#   mutate(DateTime = paste(Date, Time)) %>% 
#   mutate(across('DateTime', ~ as.POSIXct(.x, format = "%d/%m/%Y %H.%M.%S")))

# store this calendar in the folder _DATA
write_rds(cl_df, file.path(path_user, "_DATA/ff_calendar_thisweek.rds"))

