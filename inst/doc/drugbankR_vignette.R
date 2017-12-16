## ----install, eval=FALSE-------------------------------------------------
#  # install.packages("devtools")
#  devtools::install_github("yduan004/drugbankR")
#  library(drugbankR)

## ----transform_database, eval=FALSE--------------------------------------
#  ## download the original drugbank database (http://www.drugbank.ca/releases/latest) (xml file) into your current directory and rename as drugbank.xml
#  
#  # transform drugbank database (xml file) into dataframe, this may take about 20 minutes. Argument version is the version of downloaded xml file. We currently have version 5.0.10
#  drugbank_dataframe <- dbxml2df(xmlfile="drugbank.xml", version)
#  
#  # store drugbank dataframe in SQLite database, the created SQLite database (drugbank_version.db) is under "extdata" directory of "drugbankR" package.
#  df2SQLite(dbdf=drugbank_dataframe, version)
#  
#  # You can see the path of "drugbank_version.db" by running
#  system.file("extdata", package="drugbankR")

## ----queryDB, eval=FALSE-------------------------------------------------
#  all <- queryDB(type = "getAll", version="5.0.10") # get the entire drugbank dataframe
#  dim(all)
#  ids <- queryDB(type = "getIDs", version="5.0.10") # get all the drugbank ids
#  ids[1:4]
#  
#  queryDB(ids = c("DB00001","DB00002"),type = "whichFDA", version="5.0.10")
#  # given drugbank ids, determine whether they are FDA approved
#  
#  queryDB(ids = c("DB00001","DB00002"),type = "getTargets", version="5.0.10")
#  # given drugbank ids, get their targets ids (DrugBank and UniProt)

## ----sessionInfo---------------------------------------------------------
sessionInfo()

