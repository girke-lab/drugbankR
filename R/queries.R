## Get the entire data frame
#' @import RSQLite
#' @importFrom utils download.file
getAll <- function(db_path){
    conn <- dbConnect(SQLite(), db_path)
	dbdf <- dbGetQuery(conn,'SELECT * FROM dbdf')
	dbDisconnect(conn)
	return(dbdf)
}

## Get all the DrugBank IDs
getIDs <- function(db_path){
	dbdf <- getAll(db_path)
	ids <- dbdf[,"drugbank-id"]
	names(ids) <- dbdf[,"name"]
	return(ids)
} 

## To check wether the drug is FDA approved
whichFDA <- function(ids, db_path){
	dbdf <- getAll(db_path)
	sub_dbdf <- dbdf[dbdf$"drugbank-id" %in% ids,]
	whichFDA <- grepl("approved",sub_dbdf$groups)
	res <- data.frame(drugbank_id = sub_dbdf$"drugbank-id", name=sub_dbdf$"name", whichFDA=whichFDA)
  return(res)
}

## Get the targets of drugs
#' @import org.Hs.eg.db 
#' @importFrom dplyr as_tibble
#' @importFrom dplyr left_join
#' @import AnnotationDbi
getTargets <- function(ids, db_path){
	len <- length(ids)
	dbdf <- getAll(db_path)
	tartxt <- dbdf[dbdf$"drugbank-id" %in% ids,"targets"]
	
	ext_path <- system.file("extdata", package="drugbankR")
	dt_path <- paste0(ext_path,"/drug_target_uniprot_links_5.1.2.csv")
	drug_target_uniprot <- read.csv(dt_path, stringsAsFactors = FALSE)

	tar_df <- as.data.frame(matrix(NA, nrow=len, ncol=5, dimnames=list(1:len,c("q_db_id", "t_db_id","t_Uni_id","t_Uni_name","t_gn_sym"))))
	for(i in 1:len){
		gregout <- gregexpr("BE[0-9]{7}",tartxt[i])
		DrugBank_id <- substring(tartxt[i],gregout[[1]],gregout[[1]]+attr(gregout[[1]],"match.length")-1)	
		DrugBank_id <- paste(DrugBank_id,collapse=';')
		tar_df[i,"t_db_id"] <- DrugBank_id
	}
	
	# add gn_sym column for drug_target_uniprot data_frame
	k <- keys(org.Hs.eg.db, keytype = "UNIPROT")
	uni_gnsym <- suppressMessages(AnnotationDbi::select(org.Hs.eg.db, keys=k, columns=c("UNIPROT", "SYMBOL"), keytype="UNIPROT"))
	drug_target_uniprot <- dplyr::as_tibble(drug_target_uniprot)
    uni_gnsym <- dplyr::as_tibble(uni_gnsym)
	dt_uni_sym <- dplyr::left_join(drug_target_uniprot, uni_gnsym, by = c("UniProt.ID"="UNIPROT"))
	for(i in 1:len){
		UniProt_id <- drug_target_uniprot[drug_target_uniprot$"DrugBank.ID"==ids[i],"UniProt.ID"][[1]]
		UniProt_id_clps <- paste(UniProt_id,collapse=';')
		if(UniProt_id_clps=='') UniProt_id_clps <- NA
		tar_df[i,"t_Uni_id"] <- UniProt_id_clps	

		# tar_df[i,4] <- tryCatch({
		# 	gene_symbol <- suppressMessages(select(Homo.sapiens, keys=UniProt_id, columns="SYMBOL", keytype="UNIPROT"))
		# 	gene_symbol_clps <- paste(gene_symbol[,2],collapse=";")
		# }, error = function(e){
		# 	gene_symbol_clps <- NA
		# }, finally = {gene_symbol_clps})
		
		UniProt_name <- drug_target_uniprot[drug_target_uniprot$"DrugBank.ID"==ids[i],"UniProt.Name"][[1]]
		UniProt_name_clps <- paste(UniProt_name,collapse=';')
		if(UniProt_name_clps=='') UniProt_name_clps <- NA
		tar_df[i,"t_Uni_name"] <- UniProt_name_clps		
		
		sym <- unique(dt_uni_sym[dt_uni_sym$"DrugBank.ID"==ids[i],"SYMBOL"][[1]])
		sym_clps <- paste(sym,collapse=';')
		if(sym_clps=='') sym_clps <- NA
		tar_df[i,"t_gn_sym"] <- sym_clps	
	}
	tar_df[,"q_db_id"] <- ids
	rownames(tar_df) <- ids
	return(tar_df)
}

#' @title Query DrugBank SQLite database.
#' @description
#' This function can be used to
#' 
#' 1. get the entire drugbank dataframe
#' 
#' 2. get all the drugbank ids
#' 
#' 3. given drugbank ids, determine whether the drugs are FDA approved
#' 
#' 4. given drugbank ids, get their targets ids (DrugBank_id, UniProt_id, symbol...).
#' @details 
#' Column description of the queryDB result when type is 'getTargets':
#' \itemize{
#'   \item q_db_id: DrugBank ids of the query drugs
#'   \item t_db_id: DrugBank ids of the targets of the query drugs
#'   \item t_Uni_id: Uniprot ids of the targets
#'   \item t_Uni_name: Uniprot names of the targets
#'   \item t_gn_sym: Gene SYMBOL of the target proteins
#' }
#' 
#' @param ids character vector, represents DrugBank IDs.
#' @param type one of "getAll","getIDs","whichFDA","getTargets" 
#' \itemize{
#'   \item getAll: get the entire drugbank dataframe, argument \code{ids} is ignored
#' 
#'   \item getIDs: get all the drugbank ids, argument \code{ids} is ignored
#' 
#'   \item whichFDA: given drugbank ids, determine whether they are FDA approved
#' 
#'   \item getTargets: given drugbank ids, get their targets ids (DrugBank_id, UniProt_id, symbol...).
#' }
#' 
#' @param db_path Character(1), path to the DrugBank SQLite database generated
#' from \code{\link{dbxml2df}} and \code{\link{df2SQLite}} function
#' @return \code{getAll}: drugbank dataframe
#' 
#' \code{getIDs}: character vector of all the drugbank ids
#' 
#' \code{whichFDA}: logical vector
#' 
#' \code{getTargets}: data.frame containing DrugBank_id, UniProt_id, UniProt_name 
#' and gene_symbol of the targets of the query drugs
#' @export
#' 
queryDB <- function(ids=NULL, type, db_path){
  ids <- unique(ids)
  ## Validity check of input ids
  val_ids <- suppressMessages(getIDs(db_path))
  ids_inval <- ids[! ids %in% val_ids]
  ids <- ids[ids %in% val_ids]
  if(length(ids_inval)>0) message("The following are not valid DrugBank ids: \n", 
                                  paste(ids_inval, collapse=" "))
  if(length(ids)==0 & !is.null(ids)) stop("Couldn't find targets in DrugBank for your input ids")
  ## Validity check of type
  if(type=="getAll") {
		if(!is.null(ids)) warning("Get the entire DrugBank database, argument 'ids' is ignored")			
		return(getAll(db_path))
	}
  if(type=="getIDs") {
		if(!is.null(ids)) warning("Get all the DrugBank IDs, argument 'ids' is ignored")
		return(getIDs(db_path))
	}
  if(type=="whichFDA"){
		if(is.null(ids)) stop("Argument 'ids' is not assigned")
		return(whichFDA(ids, db_path)) 
	}
  if(type=="getTargets"){
		if(is.null(ids)) stop("Argument 'ids' is not assigned")
		return(getTargets(ids, db_path))
	} else stop("Argument type can only be assigned one of: getAll, getIDs, whichFDA or getTargets.")
}

