test.queryDB <- function(){
	require(RSQLite)
	source("queries.R")
	conn <- dbConnect(SQLite(),"data/drugbank.db")
	drug_target_uniprot <- dbGetQuery(conn,'SELECT * FROM drug_target_uniprot')
	dbDisconnect(conn)

	checkEquals(queryDB(ids="DB00002",type="getTargets")$"t_Uni_id",paste(drug_target_uniprot[2:13,"UniProt.ID"],collapse=";"))
	checkTrue(is.data.frame(queryDB(ids=c("DB00001","DB00002"),type="getTargets")))
	checkException(queryDB(ids="abc",type="getTargets"))
	checkException(queryDB(type="getTargets"))
	
	checkException(queryDB(ids="DB00001",type="whatever"))

	checkEquals(queryDB(ids=c("DB00001","DB00002","DB00003","DB00004","DB00005"),type="whichFDA"),c(TRUE,TRUE,TRUE,TRUE,FALSE))
	checkException(queryDB(ids="abc",type="getTargets"))

	checkEquals(length(queryDB(type="getIDs")),8226)
	checkEquals(dim(queryDB(type="getAll")),c(8226,56))
}
