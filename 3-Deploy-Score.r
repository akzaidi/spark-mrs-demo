# Use the AzureML CRAN package to deploy the tree-based model as a scalable web service.
source("SetComputeContext.R")

# Load our rxDTree Decision Tree model

load("dTreeModel.RData") # loads dTreeModel

# Convert to open source R model

rpartModel <- as.rpart( dTreeModel )

# Define a scoring function to be published as a web service

scoringFn <- function(newdata){
  library(rpart)
  predict(rpartModel, newdata=newdata)
}

trainDS <- RxXdfData( file.path(dataDir, "finalDataTrain") )

exampleDF <- base::subset(head(trainDS), select = -ArrDel15)

testDS <- RxXdfData( file.path(dataDir, "finalDataTest") )

dataToBeScored <- base::subset(head(testDS), select = -ArrDel15)

# Test the scoring function locally

scoringFn(exampleDF)

################################################
# Publish the scoring function as a web service
################################################

library(AzureML)

workspace <- workspace(config = "azureml-settings.json")

endpoint <- publishWebService(workspace, scoringFn,
                              name="Delay Prediction Service",
                              inputSchema = exampleDF)

################################################
# Score new data via the web service
################################################

scores <- consume(endpoint, dataToBeScored)

head(scores)
