# 20210324 Task Scheduling Automation from R
# https://cran.r-project.org/web/packages/taskscheduleR/readme/README.html
#
# =====================================
# Script to encrypt passwords
library(secret)
# =====================================
# Common setup & secure password management
# create your private/public keys
# e.g. using R Studio: Tools -> Global Options -> Git -> Create RSA Key
# note that this password is used for windows task scheduling
# =====================================
#settings from options
path_user <- normalizePath(Sys.getenv('PATH_DSS'), winslash = '/')
who_user <-  normalizePath(Sys.getenv('USERPROFILE'), winslash = '/')
path_keys <- file.path(who_user, ".ssh")
user <- stringr::str_remove(who_user,pattern = 'C:/Users/')
# add system password
pswrd <- ""

## UNCOMMENT lines BELOW only for the initial setup!!!
## == RISK OF ERAZING PASSWORDS ==
secret::create_vault(file.path(path_user, "vault"))
secret::add_user(email = user,
                 public_key = file.path(path_keys, 'id_rsa.pub'),
                 vault = file.path(path_user, "vault"))
secret::add_secret("pwrd", pswrd, user,
                    vault = file.path(path_user, "vault"))
secret::add_secret("user", user, user,
                    vault = file.path(path_user, "vault"))
## UNCOMMENT lines ABOVE only for the initial setup!!!

# test it:
password <- secret::get_secret("pwrd",
                               key = file.path(path_keys, 'id_rsa'),
                               vault = file.path(path_user, "vault"))
usr <- secret::get_secret("user",
                          key = file.path(path_keys, 'id_rsa'),
                          vault = file.path(path_user, "vault"))

