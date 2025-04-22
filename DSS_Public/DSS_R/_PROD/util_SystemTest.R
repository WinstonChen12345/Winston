# Script to test the system functionalities

library(testthat)
library(magrittr)
library(secret)
library(mailR)
library(readr)
library(lazytrade)
library(dplyr)

start_run <- Sys.time()
paste0(print('Test Executed on: '),print(start_run))
# Setup necessary paths
PCName <- Sys.getenv("COMPUTERNAME")
PCTempDir <- Sys.getenv("TEMP")
# terminal 1,3 paths
path_T1 <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_T3 <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
path_control_files = file.path(path_user, "_DATA/control")
who_user <-  normalizePath(Sys.getenv('USERPROFILE'), winslash = '/')
# create your private/public keys (e.g. in R Studio)
path_keys <- file.path(who_user, ".ssh")
email_SENDER <- Sys.getenv('UTIL_EMAIL_Sender')
email_RECEIVER <- Sys.getenv('UTIL_EMAIL_Reciever')

em_pass <- secret::get_secret("e_pass",
                              key = file.path(path_keys, 'id_rsa'),
                              vault = file.path(path_user, "vault"))

t_descr <- vector(mode = "character",length = 8)
t_results <- vector(mode = "logical",length = 8)
# =========================================================
# Test data writer is writing files hourly for aml
# =========================================================
t_descr[1] <- "aml files are written every hour"
t_results[1] <- test_that(t_descr[1], {
  
  csvfiles <- list.files(path_T1, pattern = "AI_RSIADX", full.names = TRUE) %>% sample(1)
  
  #how old is the file
  file_age <- file.info(csvfiles)
  
  # test that 
  expect_gte(file_age$mtime + 3600, start_run)
  
})
# =========================================================
# Test data writer is writing files hourly for mt
# =========================================================
t_descr[2] <- "mt files are written every hour"
t_results[2] <- test_that(t_descr[2], {
  
  csvfiles <- list.files(path_T1, pattern = "AI_CP60-300", full.names = TRUE) %>% sample(1)
  
  #how old is the file
  file_age <- file.info(csvfiles)
  
  # test that 
  expect_gte(file_age$mtime + 3600, start_run)
  
})

# =========================================================
# Test that aml predictions would work
# =========================================================
t_descr[3] <- "aml prediction files are written every hour T1"
t_results[3] <- test_that(t_descr[3], {
  
  csvfiles <- list.files(path_T1, pattern = "AI_M60_Change", full.names = TRUE) %>% sample(1)
  
  #how old is the file
  file_age <- file.info(csvfiles)
  
  # test that 
  expect_gte(file_age$mtime + 3600, start_run)
  
})


t_descr[4] <- "all aml prediction files are written"
t_results[4] <- test_that(t_descr[3], {
  
  csvfiles <- list.files(path_T1, pattern = "AI_M60_Change", full.names = TRUE) %>% length()
  
  # test that 
  expect_equal(csvfiles, 28)
  
})
# =========================================================
# Test that mt predictions would work
# =========================================================
t_descr[5] <- "mt prediction files are written every hour T1"
t_results[5] <- test_that(t_descr[5], {
  
  csvfiles <- list.files(path_T1, pattern = "AI_MarketType_", full.names = TRUE) %>% sample(1)
  
  #how old is the file
  file_age <- file.info(csvfiles)
  
  # test that 
  expect_gte(file_age$mtime + 3600, start_run)
  
})

t_descr[6] <- "all mt prediction files are written"
t_results[6] <- test_that(t_descr[6], {
  
  csvfiles <- list.files(path_T1, pattern = "AI_MarketType_", full.names = TRUE) %>% length()
  
  # test that 
  expect_equal(csvfiles, 28)
  
})
# =========================================================
# Test that rl adaptation would work
# =========================================================
t_descr[7] <- "rl adapt control algorithm works"
t_results[7] <- test_that(t_descr[7], {
  
  DFT1 <- try(import_data(path_T1, "OrdersResultsT1.csv"), silent = TRUE)
  DFT1_sum <- DFT1 %>% 
    group_by(MagicNumber) %>% 
    summarise(Num_Trades = n(),
              Mean_profit = sum(Profit)) %>% 
    arrange(desc(Num_Trades)) %>% 
    filter(Num_Trades > 15) %>% slice_sample(n = 1) %$% MagicNumber %>% as.character()
  
  #if there are systems with a lot of trades we should have 'control' files corresponding to those systems
  rdsfiles <- list.files(path_control_files, pattern = DFT1_sum, full.names = TRUE)
  file_age <- file.info(rdsfiles)
  
  # test that file was modified at least 1x every 24 hours as it should
  expect_gt(file_age$mtime + 240*3600, start_run)
  
  
})
# =========================================================
# Test that rl policy would work
# =========================================================
t_descr[8] <- "rl policy algorithm works"
t_results[8] <- test_that(t_descr[8], {
  
  DFT1 <- try(import_data(path_T1, "OrdersResultsT1.csv"), silent = TRUE)
  DFT1_sum <- DFT1 %>% 
    group_by(MagicNumber) %>% 
    summarise(Num_Trades = n(),
              Mean_profit = sum(Profit)) %>% 
    arrange(desc(Num_Trades)) %>% 
    filter(Num_Trades > 15) %>% slice_sample(n = 1) %$% MagicNumber+200
  
  MT_pattern <- paste0("SystemControlMT", DFT1_sum, ".csv")
  
  csvfiles <- list.files(path_T3, pattern = MT_pattern, full.names = TRUE)
  
  file_age <- file.info(csvfiles)
  
  # test that file was modified at least 1x every hour as it should
  expect_gt(file_age$mtime + 3600, start_run)
  
  
})

# =========================================================
# Test that aml simulations works
# =========================================================

# =========================================================
# Test that aml boost model works
# =========================================================

# =========================================================
# Output of all results
# =========================================================
email_body <- paste("One of the tests for the DSS is failing: ",
                    paste(t_results, collapse = ' '),
                    "Test description: ",
                    paste(t_descr, collapse = '|'),
                    " on: ", PCName,
                    " at: ", start_run)

# Evaluate and send email if necessary
#if(!all(t_results)){
#  
#  send.mail(from = email_SENDER,
#            to = email_RECEIVER,
#            subject = "DSS System Alert",
#            body = email_body,
#            smtp = list(host.name = "smtp.gmail.com", port = 465, 
#                        user.name = email_SENDER,            
#                        passwd = em_pass, ssl = TRUE), 
#            authenticate = TRUE,
#            send = TRUE)
#  

#}

end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run)
