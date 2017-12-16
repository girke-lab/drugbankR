#' @name drugbankR
#' @title R package for querying drugbank database
#' @aliases drugbankR-package
#' @docType package
#' @description The drugbankR package is used for querying drugbank database in R.
#' @details Transform drugbank database (xml file) into dataframe and store in SQLite database. 
#' 
#' Query drugbank SQLite database to get
#' 
#' 1. the entire dataframe.
#' 
#' 2. all the drugbank ids.
#' 
#' 3. given drugbank ids, determine whether the drugs are FDA approved. 
#' 
#' 4. given drugbank ids, get their targets ids (DrugBank_id, UniProt_id, symbol...).
#' 
#' @author Yuzhu Duan (yduan004@ucr.edu)
#' @references \url{http://www.drugbank.ca/releases/latest}
#' @examples 
#' # devtools::install_github("yduan004/drugbankR")
#' 
#' # library(drugbankR)
#' 
#' ## download the original drugbank database (http://www.drugbank.ca/releases/latest) (xml file) 
#' 
#' ## into your current directory and rename as drugbank.xml
#' 
#' ## convert drugbank dabase (xml file) into dataframe: 
#' \dontrun{
#' drugbank_dataframe <- dbxml2df(xmlfile="drugbank.xml")
#' } 
#' 
#' ## store the converted drugbank dataframe into SQLite database. 
#' 
#' ## The generated SQLite database (drugbank.db) is under your current directory
#' 
#' \dontrun{
#' df2SQLite(dbdf=drugbank_dataframe) 
#' }
#' df <- queryDB(type = "getAll")
#' 
#' ids <- queryDB(type = "getIDs")
#' 
#' queryDB(ids = c("DB00001","DB00002"),type = "whichFDA")
#' 
#' queryDB(ids = c("DB00001","DB00002"),type = "getTargets")
#' 
NULL