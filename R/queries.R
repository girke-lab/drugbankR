## Get the entire data frame
#' @import RSQLite
#' @importFrom utils download.file
getAll <- function(version="5.0.10"){
  ext_path <- system.file("extdata", package="drugbankR")
  db_path <- paste0(ext_path,"/drugbank_",version,".db")
  if(file.exists(db_path)){
    conn <- dbConnect(SQLite(), db_path)
  } else {
    tryCatch(download.file(paste0("http://biocluster.ucr.edu/~yduan004/drugbankR/drugbank_", version,".db"), db_path, quiet = TRUE), 
             error = function(e){
               stop("we currently don't have requested version of drugbank SQLite database. You could try version 5.0.10 or 5.0.6. If your version is more update, you could generate drugbank SQLite database by yourself by following the vignette of this package and then run this function")
               })
    conn <- dbConnect(SQLite(), db_path)
  }
	dbdf <- dbGetQuery(conn,'SELECT * FROM dbdf')
	dbDisconnect(conn)
	return(dbdf)
}

## Get all the DrugBank IDs
getIDs <- function(version="5.0.10"){
	dbdf <- getAll(version)
	ids <- dbdf[,"drugbank-id"]
	names(ids) <- dbdf[,"name"]
	return(ids)
} 

## To check wether the drug is FDA approved
whichFDA <- function(ids, version="5.0.10"){
	dbdf <- getAll(version)
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
getTargets <- function(ids, version="5.0.10"){
	len <- length(ids)
	dbdf <- getAll(version)
	tartxt <- dbdf[dbdf$"drugbank-id" %in% ids,"targets"]
	
	ext_path <- system.file("extdata", package="drugbankR")
	db_path <- paste0(ext_path,"/drugbank_",version,".db")
	conn <- dbConnect(SQLite(), db_path)
	
	dt_path <- paste0(ext_path,"/drug_target_uniprot_links_",version,".csv")
	if(file.exists(dt_path)){
	  drug_target_uniprot <- read.csv(dt_path, stringsAsFactors = FALSE)
	} else {
	  vv <- unlist(strsplit(version,split="\\."))
	  v2 <- paste0(vv, collapse = "-")
	  system(paste0("curl -Lfv -o ",paste0(ext_path,"/tmp.zip")," -u yduan004@ucr.edu:dbpass123 https://www.drugbank.ca/releases/", v2,"/downloads/target-all-uniprot-links > /dev/null 2>&1"))
	  utils::unzip(paste0(ext_path,"/tmp.zip"), exdir = ext_path)
	  file.rename(paste0(ext_path,"/uniprot links.csv"), dt_path)
	  unlink(paste0(ext_path,"/tmp.zip"))
	  drug_target_uniprot <- read.csv(dt_path, stringsAsFactors = FALSE)
	}
	dbDisconnect(conn)
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

## Meta function
#' @export
#' @title Query drugbank SQLite database.
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
#' 
#' @param ids A character vector, represent DrugBank IDs.
#' @param type Type can only be assigned to "getAll","getIDs","whichFDA","getTargets" 
#' 
#' getAll: get the entire drugbank dataframe, argument \code{ids} is ignored
#' 
#' getIDs: get all the drugbank ids, argument \code{ids} is ignored
#' 
#' whichFDA: given drugbank ids, determine whether they are FDA approved
#' 
#' getTargets: given drugbank ids, get their targets ids (DrugBank_id, UniProt_id, symbol...).
#' 
#' @param version Character, version of the requested drugbank database
#' @return \code{getAll}: drugbank dataframe
#' 
#' \code{getIDs}: vector of all the drugbank ids
#' 
#' \code{whichFDA}: logical vector
#' 
#' \code{getTargets}: dataframe containing targets' DrugBank_id, UniProt_id, UniProt_name and gene_symbol
#' 
queryDB <- function(ids=NULL, type, version="5.0.10"){
  ids <- unique(ids)
	## Validity check of input ids
  val_ids <- suppressMessages(getIDs(version))
  ids_inval <- ids[! ids %in% val_ids]
  ids <- ids[ids %in% val_ids]
	if(length(ids_inval)>0) message("No targets in DrugBank for", ids_inval)
  if(length(ids)==0 & !is.null(ids)) stop("Couldn't find targets in DrugBank for your input ids")
  ## Validity check of type
  if(type=="getAll") {
		if(!is.null(ids)) warning("Get the entire DrugBank database, argument ids is ignored")			
		return(getAll(version))
	}
  if(type=="getIDs") {
		if(!is.null(ids)) warning("Get all the DrugBank IDs, argument ids is ignored")
		return(getIDs(version))
	}
  if(type=="whichFDA"){
		if(is.null(ids)) stop("Argument ids is not assigned")
		return(whichFDA(ids, version)) 
	}
  if(type=="getTargets"){
		if(is.null(ids)) stop("Argument ids is not assigned")
		return(getTargets(ids, version))
	} else stop("Argument type can only be assigned one of: getAll, getIDs, whichFDA or getTargets.")
}

