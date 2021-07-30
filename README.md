# Introduction 
This package can be used to query the newest version (*e.g.* 5.1.3) of DrugBank database in R. It can transform the original DrugBank database in xml file format, which is available [here](http://www.drugbank.ca/releases/latest), into a dataframe and store the dataframe into a SQLite database. The generated DrugBank SQLite database in specific version can be queried by using `queryDB` function. We can

* Get the entire DrugBank dataframe

* Get all the DrugBank ids

* Determine whether the query drugs are FDA approved

* Get targets of the query drugs.

# Installation and load

The _`drugbankR`_ package can be directly installed from github

```r
# install.packages("devtools")
devtools::install_github("yduan004/drugbankR")
```

load the package into R
```r
library(drugbankR)
```

# Generate your own DrugBank SQLite database

Download and unzip the full DrugBank database (xml file) from [here](http://www.drugbank.ca/releases/latest) to your present
working directory of R session, rename the unziped xml file as `drugbank.xml`. The `dbxml2df` function will read in the xml
file and transform it into a data.frame object in R. This process may take about 20 minutes. Argument `version` is a character indicating the version of the downloaded DrugBank database. Since now, the newest version is `5.1.3`. Note, you 
need to creat a DrugBank account and log in to access the data.

```r
drugbank_dataframe <- dbxml2df(xmlfile="drugbank.xml", version="5.1.3") 
```

The `df2SQLite` function stores the drugbank dataframe into a SQLite database. The created SQLite database (drugbank_versionNumber.db) is under your present working direcotry of R, you could check your current R working directory by running `getwd()` in R.
```r
df2SQLite(dbdf=drugbank_dataframe, version="5.1.3")
```

# Query the DrugBank SQLite database generated above

```r
# get the entire drugbank data.frame
all <- queryDB(type = "getAll", db_path="drugbank_5.1.3.db") 
dim(all)

# retrieve all the valid drugbank ids
ids <- queryDB(type = "getIDs", db_path="drugbank_5.1.3.db") 
ids[1:4]

# given drugbank ids, determine whether they are FDA approved
queryDB(ids = c("DB00001","DB00002"),type = "whichFDA", db_path="drugbank_5.1.3.db") 

# given drugbank ids, get their target gene/protein IDs 
queryDB(ids = c("DB00001","DB00002"),type = "getTargets", db_path="drugbank_5.1.3.db") 
```
