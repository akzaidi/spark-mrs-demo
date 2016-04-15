#copy local file to HDFS
rxHadoopMakeDir("/share")
rxHadoopCopyFromLocal("/usr/lib64/MRS-*/library/RevoScaleR/SampleData/AirlineDemoSmall.csv", "/share")

myNameNode <- "default"
myPort <- 0

# Location of the data
bigDataDirRoot <- "/share"

# define HDFS file system
hdfsFS <- RxHdfsFileSystem(hostName=myNameNode, port=myPort)

# specify the input file in HDFS to analyze
inputFile <-file.path(bigDataDirRoot,"AirlineDemoSmall.csv")

# create Factors for days of the week
colInfo <- list(DayOfWeek = list(type = "factor",
                                 levels = c("Monday", "Tuesday", "Wednesday", "Thursday",
                                            "Friday", "Saturday", "Sunday")))

# define the data source
airDS <- RxTextData(file = inputFile, missingValueString = "M",
                    colInfo = colInfo, fileSystem = hdfsFS)

# First test the "local" compute context
rxSetComputeContext("local")

# Run a linear regression
system.time(
  model <- rxLinMod(ArrDelay~CRSDepTime+DayOfWeek, data = airDS)
)

# Rows Read: 500000, Total Rows Processed: 500000, Total Chunk Time: 2.941 seconds
# Rows Read: 100000, Total Rows Processed: 600000, Total Chunk Time: 0.657 seconds 
# Computation time: 6.954 seconds.
# user  system elapsed 
# 0.084   0.028  10.150 

# display a summary of model
summary(model)

# define MapReduce compute context
myHadoopMRCluster <- RxHadoopMR(consoleOutput=TRUE,
                                nameNode=myNameNode,
                                port=myPort,
                                hadoopSwitches="-libjars /etc/hadoop/conf")

# set compute context
rxSetComputeContext(myHadoopMRCluster)

# Run a linear regression
system.time(
  model1 <- rxLinMod(ArrDelay~CRSDepTime+DayOfWeek, data = airDS)
)

# Computation time: 78.830 seconds. 
# user  system elapsed 
# 13.308   4.996 104.843 

# display a summary of model
summary(model1)

# define Spark compute context
mySparkCluster <- RxSpark(consoleOutput=TRUE)

# set compute context
rxSetComputeContext(mySparkCluster)

# Run a linear regression
system.time(
  model2 <- rxLinMod(ArrDelay~CRSDepTime+DayOfWeek, data = airDS)
)

# Computation time: 59.129 seconds. 
# user  system elapsed 
# 13.720   4.592  84.737 

# display a summary of model
summary(model2)

# Run 4 tasks via rxExec
rxExec( function() {Sys.info()["nodename"]}, timesToRun = 4 )