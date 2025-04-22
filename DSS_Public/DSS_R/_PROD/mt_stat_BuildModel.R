# ----------------------------------------------------------------------------------------
# R Script to train the Deep Learning model on Financial Asset Time Series Data
# ----------------------------------------------------------------------------------------
# ## Manually selected data is in the matrix with label of 6 classes
# ----------------------------------------------------------------------------------------
#
# Supervised Deep Learning Classification Modelling with random classes
#
# load libraries to use and custom functions from package lazytrade
library(readr)
library(magrittr)
library(dplyr)
library(h2o)
library(lazytrade)
library(stats)
library(moments)

#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')

#settings from options
ncpu <- as.numeric(Sys.getenv('OPT_AML_NCPU'))

#path with the data
path_data <- file.path(path_user, "_DATA")

chart_period <- as.numeric(Sys.getenv('OPT_MT_PerMin'))
#!!!Execute code below line by line

#absolute path to store model objects (useful when scheduling tasks)
path_model <- file.path(path_user, "_MODELS")
path_data <- file.path(path_user, "_DATA")

#absolute path with the data (choose MT4 directory where files are generated)
path_terminal <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

# check if the directory exists or create
if(!dir.exists(path_model)){dir.create(path_model)}
if(!dir.exists(path_data)){dir.create(path_data)}

#### Manually Selected data... =================================================
# data stored in the lazytrade package
#data(price_dataset_big)

# data placed to the _DATA folder
price_dataset_big <- readr::read_csv(file.path(path_terminal, "AI_CP60-1600.csv"), col_names = FALSE)
price_dataset_big$X1 <- lubridate::ymd_hms(price_dataset_big$X1)
# Market Periods
# 1. Bull normal, BUN
# 2. Bull volatile, BUV
# 3. Bear normal, BEN
# 4. Bear volatile, BEV
# 5. Sideways quiet, RAN
# 6. Sideways volatile, RAV

# automatically classify dataset only if rds dataset not existing yet
if(!file.exists(file.path(path_data, "ai_class_km.rds"))){
  ai_class_km <- mt_stat_transf(indicator_dataset = price_dataset_big,
                 num_bars = 24,
                 timeframe = 60,
                 path_data = path_data,
                 mt_classes = c('BUN', 'BEN'),
                 clust_method = 'kmeans',
                 rule_opt = TRUE)
  
  # store dataset to be able to retrain deep learning classification model
  write_rds(ai_class_km, file.path(path_data, "ai_class_km.rds"))
  
} else {
  ai_class_km <- read_rds(file.path(path_data, "ai_class_km.rds"))
}



# ai_class_hc <- mt_stat_transf(indicator_dataset = price_dataset_big,
#                            num_bars = 64,
#                            timeframe = 60,
#                            path_data = path_data,
#                            mt_classes = c('BUN', 'BEN', 'RAN','BUV', 'BEV', 'RAV'),
#                            clust_method = 'hclust')



# table(ai_class_km$M_T)
# table(ai_class_hc$M_T)
# plot(ai_class_km, col = ai_class_km$M_T)
# plot(ai_class_hc, col = ai_class_hc$M_T)
# library(ggplot2)
# ggplot(ai_class_km, aes(Q1, Q2, col = M_T, shape = M_T))+geom_point()
# ggplot(ai_class_km, aes(Q2, K1, col = M_T, shape = M_T))+geom_point()
# ggplot(ai_class_km, aes(Q3, K1, col = M_T, shape = M_T))+geom_point()
# 
# ggplot(ai_class_hc, aes(Q1, K1, col = M_T, shape = M_T))+geom_point()
# ggplot(ai_class_hc, aes(Q2, K1, col = M_T, shape = M_T))+geom_point()
# ggplot(ai_class_hc, aes(Q3, K1, col = M_T, shape = M_T))+geom_point()




#### Fitting Deep Learning Net =================================================
# start h2o virtual machine
h2o.init(nthreads = ncpu)

#' # performing Deep Learning Classification using the custom function auto clustered data
 mt_make_model(indicator_dataset = ai_class_km,
               num_bars = 24,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               num_epoch = 200,
               activate_balance = FALSE,
               num_nn_options = 24,
               is_cluster = TRUE)


# shutdown the virtual machine
h2o.shutdown(prompt = F)

#### End