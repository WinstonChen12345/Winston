# ----------------------------------------------------------------------------------------
# R Script to score current period of each currency based on the newly entered data
# ----------------------------------------------------------------------------------------
start_run <- Sys.time()
# Expected output: Table containing market type number for every of the currency pairs written as files to the sandboxes of terminals
library(dplyr)
library(magrittr)
library(lubridate)
library(readr)
library(h2o)
library(lazytrade)
library(stats)

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
path_repo <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')

#path with the setup info
path_setup <- file.path(path_repo, 'DSS_Bot', 'DSS_Setup')

# Defining variables to be re-used in the code
path_sbxm <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_sbxs <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')

# Define variables for the functions to work
chart_period <- as.numeric(Sys.getenv('OPT_MT_PerMin')) #this variable will define market type period
num_cols <- 24

#absolute path to store model objects (useful when scheduling tasks)
path_model <- file.path(path_user, "_MODELS")
path_data <- file.path(path_user, "_DATA")

# check if the directory exists or create
if(!dir.exists(path_model)){dir.create(path_model)}
if(!dir.exists(path_data)){dir.create(path_data)}


# Vector of currency pairs
Pairs <- readLines(file.path(path_setup, '5_pairs.txt')) %>% 
  stringr::str_split(pattern = ',') %>% unlist()

# Reading the data from the Sandbox of Terminal 2 --> !!!Make sure that DataWriter robot is attached and working in Terminal 2!!!
sbx_price <- file.path(path_sbxm, paste0("AI_CP",chart_period,"-300.csv"))

price <- read_csv(sbx_price, col_names = F)

price$X1 <- ymd_hms(price$X1)

# Prepare data frame with last 64 observations of all 28 pairs and remove date/time column (16 hours)
# macd_100 <- macd %>% select(c(X2:X29)) %>% head(num_cols)
# Prepare data frame with last 64 observations of all 28 pairs and remove date/time column (16 hours)
macd_100 <- price %>% select(-X1) %>% head(num_cols)

# Rename the columns
names(macd_100) <- Pairs

# initialize the virtual machine
h2o.init(nthreads = 1)

# test for all columns
for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
  # PAIR <- "GBPUSD"
  # PAIR <- "EURGBP"
  # Extract one column with Indicator data for 1 pair (e.g. "EURUSD")
  df <- macd_100 %>% select(PAIR)

  # Use function to score the data to the model
  my_market_prediction <- mt_stat_evaluate(x = df,
                                      path_model = path_model,
                                      num_bars = num_cols,
                                      timeframe = 60) 
  # predicted value to write
  my_market <- my_market_prediction  %>% select(predict)
  
  # Join data to the predicted class
  # get predicted confidence
  my_market_conf <- my_market_prediction %>% select(-1) %>% select(which.max(.))
  
  
  # Return the name of the output
  names(my_market) <- PAIR
  # Add prediction confidence for diagnostics / robot logic purposes
  my_market <- my_market %>% bind_cols(my_market_conf)
  # Write obtained result to the sandboxes
  write_csv(my_market, file.path(path_sbxm, paste0("AI_MarketType_", PAIR, chart_period, ".csv")))
  write_csv(my_market, file.path(path_sbxs,  paste0("AI_MarketType_", PAIR, chart_period, ".csv")))

}



# shutdown  the virtual machine
h2o.shutdown(prompt = F)

end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run)
