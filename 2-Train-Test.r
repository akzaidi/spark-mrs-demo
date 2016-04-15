#  source("SetComputeContext.R")

# finalData <- RxXdfData(file.path(dataDir, "joined5XDF"))
finalData <- destData

################################################
# Split out Training and Test Datasets
################################################

# split out the training data

trainDS <- RxXdfData( file.path(dataDir, "finalDataTrain" ),
                      fileSystem = hdfsFS)

rxDataStep( inData = finalData, outFile = trainDS,
            rowSelection = ( Year != 2012 ), overwrite = T )

# split out the testing data

testDS <- RxXdfData( file.path(dataDir, "finalDataTest" ),
                     fileSystem = hdfsFS)

rxDataStep( inData = finalData, outFile = testDS,
            rowSelection = ( Year == 2012 ), overwrite = T )


################################################
# Train and Test a Logistic Regression model
################################################

formula <- as.formula(ArrDel15 ~ Year + Month + DayofMonth + DayOfWeek + Carrier + OriginAirportID + 
                     DestAirportID + CRSDepTime + CRSArrTime + RelativeHumidityOrigin + 
                     AltimeterOrigin + DryBulbCelsiusOrigin + WindSpeedOrigin + 
                     VisibilityOrigin + DewPointCelsiusOrigin + RelativeHumidityDest + 
                     AltimeterDest + DryBulbCelsiusDest + WindSpeedDest + VisibilityDest + 
                     DewPointCelsiusDest
                   )

# Use the scalable rxLogit() function

logitModel <- rxLogit(formula, data = trainDS)

base::summary(logitModel)

# Predict over test data (Logistic Regression).

logitPredict <- RxXdfData(file.path(dataDir, "logitPredict"),
                          fileSystem = hdfsFS)

# Use the scalable rxPredict() function

rxPredict(logitModel, data = testDS, outData = logitPredict,
          extraVarsToWrite = c("ArrDel15"),
          type = 'response', overwrite = TRUE)

# Calculate ROC and Area Under the Curve (AUC).

logitRoc <- rxRoc("ArrDel15", "ArrDel15_Pred", logitPredict)
logitAuc <- rxAuc(logitRoc)

plot(logitRoc)


##############################################
# Train and Test a Decision Tree model
##############################################

# Train using the scalable rxDTree function

system.time(dTreeModel <- rxDTree(formula, data = trainDS,
                                  maxDepth = 6, pruneCp = "auto"))
# user   system  elapsed 
# 26.380   25.860 1244.448 

# Test using the scalable rxPredict function

treePredict <- RxXdfData(file.path(dataDir, "treePredict"),
                         fileSystem = hdfsFS)

system.time(rxPredict(dTreeModel, data = testDS, outData = treePredict, 
                      extraVarsToWrite = c("ArrDel15"), overwrite = TRUE))
# user  system elapsed 
# 13.436   3.616 142.326

# Calculate ROC and Area Under the Curve (AUC)

treeRoc <- rxRoc("ArrDel15", "ArrDel15_Pred", treePredict)
treeAuc <- rxAuc(treeRoc)

plot(treeRoc)

save(dTreeModel, file = "dTreeModel.RData")
