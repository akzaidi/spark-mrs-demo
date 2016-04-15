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

# display a summary of model
summary(model1)

# Run 4 tasks via rxExec
rxExec( function() {Sys.info()["nodename"]}, timesToRun = 4 )