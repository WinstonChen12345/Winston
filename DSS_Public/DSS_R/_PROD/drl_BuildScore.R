# ----------------------------------------------------------------------------------------
# R Script to train the Deep Learning Reinforcement model and Score data to derive decision
# ----------------------------------------------------------------------------------------
# Use initially generated data to start training process
# ----------------------------------------------------------------------------------------
#
start_run <- Sys.time()
# Supervised Deep Learning Classification Modelling with two classes
#
# load libraries to use and custom functions from package lazytrade
library(readr)
library(magrittr)
library(dplyr)
library(h2o)
library(lazytrade)


#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
path_repo <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')

#path with the setup info
path_setup <- file.path(path_repo, 'DSS_Public', 'DSS_Setup')
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
#path to 3rd terminal to write duplicate data output
path_sbxs <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')

# check if the directory exists or create
if(!dir.exists(path_model)){dir.create(path_model)}
if(!dir.exists(path_data)){dir.create(path_data)}

# Vector of currency pairs
Pairs <- readLines(file.path(path_setup, '5_pairs.txt')) %>% 
  stringr::str_split(pattern = ',') %>% unlist()

# start h2o virtual machine
h2o.init(nthreads = ncpu)


### Arrange into For loop for all symbols in use
for (SYMB in Pairs) {
  
  #SYMB = "USDJPY"
  #SYMB = "EURUSD"
  #SYMB = "ADAUSD"





#### Read the Initially Generated data... =================================================
#note: data should be generated by the mt4 robot DSS_DRL_Bot on Initialization


# data placed to the _DATA folder
drl_dataset_init <- readr::read_csv(file.path(path_terminal, "6_06", paste0("RLUnit",SYMB,".csv")), col_names = FALSE)
drl_dataset_init$X1 <- lubridate::ymd_hms(drl_dataset_init$X1)

# convert column X2 to Factor
drl_dataset_init$X2 <- as.factor(drl_dataset_init$X2)

# need to multiply column X3-X5 to value 'z' to make column abs.value min/max -100/100
symb_tick <- readr::read_csv(file.path(path_terminal, "TickSize_AI_RSIADX.csv"),col_names = FALSE) %>% 
  dplyr::filter(X1 == SYMB) %$% X2

drl_dataset_init$X3 <- drl_dataset_init$X3/symb_tick
drl_dataset_init$X4 <- drl_dataset_init$X4/symb_tick
drl_dataset_init$X5 <- drl_dataset_init$X5/symb_tick

# remove date / time column X1
drl_dataset_init$X1 <- NULL


# write this dataset only if rds dataset not existing yet
if(!file.exists(file.path(path_data, paste0("drl_init",SYMB,".rds")))){

  # store dataset to be able to retrain deep learning classification model
  readr::write_rds(drl_dataset_init, file.path(path_data, paste0("drl_init",SYMB,".rds")))
  #change the name of the dataset
  drl_dataset_comb <- drl_dataset_init
  drlPred <- head(drl_dataset_comb, 1)
} else {
  drl_dataset_init <- readr::read_rds(file.path(path_data, paste0("drl_init",SYMB,".rds")))
  
  # read more data from real-time module
  # read fresh data from the sandbox
  drl_dataset_act <- readr::read_csv(file.path(path_terminal, paste0("RLUnit",SYMB,".csv")), col_names = FALSE)
  drl_dataset_act$X1 <- lubridate::ymd_hms(drl_dataset_act$X1)
  
  # convert column X2 to Factor
  drl_dataset_act$X2 <- as.factor(drl_dataset_act$X2)
  
  drl_dataset_act$X3 <- drl_dataset_act$X3/symb_tick
  drl_dataset_act$X4 <- drl_dataset_act$X4/symb_tick
  drl_dataset_act$X5 <- drl_dataset_act$X5/symb_tick
  
  # remove date / time column X1
  drl_dataset_act$X1 <- NULL
  
  drlPred <- head(drl_dataset_act, 1)
  
  # read latest trade results
  
  # join and aggregate data to initial dataset
  drl_dataset_comb <- dplyr::bind_rows(drlPred,drl_dataset_init)
  
  # limit data to the last 500 records
  drl_dataset_comb <- head(drl_dataset_comb, 500)
  
  # store dataset to be able to retrain deep learning classification model
  readr::write_rds(drl_dataset_comb, file.path(path_data, paste0("drl_init",SYMB,".rds")))
  
}

# table(drl_dataset_init$X2)


#### Fitting Deep Learning Net =================================================
# get this data into h2o:
drl_dataset  <- h2o::as.h2o(x = drl_dataset_comb, destination_frame = "drl_dataset")
#' # performing Deep Learning Classification using the custom function auto clustered data
ModelDRLC <- h2o::h2o.deeplearning(
  model_id = paste0("DRL_Classification", "_", SYMB),
  x = names(drl_dataset[,2:40]),
  y = "X2",
  training_frame = drl_dataset,
  activation = "Tanh",
  overwrite_with_best_model = TRUE,
  autoencoder = FALSE,
  hidden = c(200, 200),
  loss = "Automatic",
  sparse = TRUE,
  l1 = 1e-4,
  distribution = "AUTO",
  stopping_metric = "AUTO",
  balance_classes = FALSE,
  epochs = 100)
#summary(ModelDRLC)
#h2o.performance(ModelDRLC)


#### Score new data using obtained Deep Learning Net ===========================

# load the dataset to h2o
test  <- h2o::as.h2o(x = drlPred, destination_frame = "test")

# retrieve the predicted value of the market type
e1 <- h2o::h2o.predict(ModelDRLC, test) %>% as.data.frame()

# predicted value to write
my_output <- e1  %>% select(predict)

# Join data to the predicted class
# get predicted confidence
my_output_conf <- e1 %>% select(-1) %>% select(which.max(.))


# Return the name of the output
names(my_output) <- SYMB
# Add prediction confidence for diagnostics / robot logic purposes
my_output <- my_output %>% bind_cols(my_output_conf)

# write the result to the file
readr::write_csv(my_output, file.path(path_terminal, paste0("RLUnitOut", SYMB, ".csv")))
readr::write_csv(my_output, file.path(path_sbxs, paste0("RLUnitOut", SYMB, ".csv")))



} #end of for loop for SYMB


# shutdown the virtual machine
h2o.shutdown(prompt = F)


end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run) #Time difference of  secs

#### End