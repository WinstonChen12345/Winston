# Script to clean files and folders in the Temporary directory
library(magrittr)
library(stringr)
library(secret)
library(mailR)
start_run <- Sys.time()

#https://stackoverflow.com/questions/45894133/deleting-tmp-files

path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
who_user <-  normalizePath(Sys.getenv('USERPROFILE'), winslash = '/')
# create your private/public keys (e.g. in R Studio)
path_keys <- file.path(who_user, ".ssh")
email_SENDER <- Sys.getenv('UTIL_EMAIL_Sender')
email_RECEIVER <- Sys.getenv('UTIL_EMAIL_Reciever')
email_HOST <- Sys.getenv('UTIL_EMAIL_Host')
email_PORT <- Sys.getenv('UTIL_EMAIL_Port')
opt_test  <- as.logical(Sys.getenv('OPT_UTIL_Test'))
opt_drl <- as.logical(Sys.getenv('OPT_DRL_BuScDe'))


if (opt_test) {
  em_pass <- secret::get_secret("e_pass",
                                key = file.path(path_keys, 'id_rsa'),
                                vault = file.path(path_user, "vault"))
  
}

PCTempDir <- Sys.getenv("TEMP")
PCName <- Sys.getenv("COMPUTERNAME")
# =========================================================
# Files in TEMP directory
# =========================================================
#detect and delete folders with pattern "Rtmp"
folders <- dir(PCTempDir, pattern = "Rtmp", full.names = TRUE)
unlink(folders, recursive = TRUE, force = TRUE, expand = TRUE)

#detect and delete folders with pattern ".tmp"
tmpfold <- dir(PCTempDir, pattern = ".tmp", full.names = TRUE)
unlink(tmpfold, recursive = TRUE, force = TRUE, expand = TRUE)

# Also clean log files from _PROD folder
#path to user repo:
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
#path with log files
path_prod <- file.path(path_user, "_PROD")

#detect files with pattern ".log"
logfiles <- list.files(path_prod, pattern = ".log", full.names = TRUE)
try(file.remove(logfiles),silent = TRUE)

# =========================================================
# Files in MQL4/Files directory
# =========================================================
# delete files collected by the DataWriter
path_terminal <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')

if (!opt_drl) {

  #detect files with pattern "AI_RSIADX"
  csvfiles <- list.files(path_terminal, pattern = "AI_RSIADX", full.names = TRUE) %>% 
    #except file TickSize_....
    stringr::str_subset("TickSize_",negate = TRUE)
  
  file.remove(csvfiles)
  
  # delete files collected by the script aml_collect_data
  path_data <- file.path(path_user, "_DATA")
  #detect files with pattern "AI_RSIADX"
  rdsfiles <- list.files(path_data, pattern = "AI_RSIADX", full.names = TRUE) %>% 
    #except file TickSize_....
    stringr::str_subset("TickSize_",negate = TRUE)
  
  try(file.remove(rdsfiles),silent = TRUE)
  
    
}


if (opt_test) {
  # =========================================================
  # Do send weekly email as a watchdog that everything works fine
  # =========================================================
  email_message <- paste0("This is just to tell that all is ok with Lazytrade System on: ", PCName,
                          " at: ", start_run)
  
  
  send.mail(from = email_SENDER,
            to = email_RECEIVER,
            subject = "DSS System Watchdog",
            body = email_message,
            smtp = list(host.name = email_HOST, port = email_PORT,
                        user.name = email_SENDER,            
                        passwd = em_pass, ssl = TRUE), 
            authenticate = TRUE,
            send = TRUE)
  
  
}



end_run <- Sys.time()
tot_run <- end_run - start_run
print(tot_run)
