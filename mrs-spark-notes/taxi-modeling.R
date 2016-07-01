download.file("https://alizaidi.blob.core.windows.net/training/manhattan.RData", "../../../alizaidi/manhattan.RData")
download.file("https://alizaidi.blob.core.windows.net/training/sample_taxi.csv", "../../../alizaidi/sample_taxi.csv")
wasb_taxi <- "/NYCTaxi/sample"
rxHadoopListFiles("/")
rxHadoopMakeDir(wasb_taxi)
rxHadoopCopyFromLocal("../../../alizaidi/sample_taxi.csv", wasb_taxi)
rxHadoopCommand("fs -cat /NYCTaxi/sample/sample_taxi.csv | head")


library(SparkR)

# create sql context to create Spark DataFrames
sparkEnvir <- list(spark.executor.instance = '10',
                   spark.yarn.executor.memoryOverhead = '8000')

sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)

sqlContext <- sparkRHive.init(sc)

dataframe_import <- function(path) {
  
  library(SparkR)
  path <- file.path(path)
  path_df <- read.df(sqlContext, path,
                     source = "com.databricks.spark.csv",
                     header = "true", inferSchema = "true", delimiter = ",")
  
  return(path_df)
  
}

sample_taxi <- dataframe_import("/NYCTaxi/sample/sample_taxi.csv")



rxHadoopListFiles("/user/RevoShare/")
data_path <- "/user/RevoShare/alizaidi"

write.df(sample_taxi, 
         file.path(data_path, "sampleTaxi"), 
         "com.databricks.spark.csv", 
         "overwrite", 
         header = "true")

sparkR.stop()

rxHadoopListFiles(file.path(data_path, "sampleTaxi"))
file_to_delete <- file.path(data_path, 
                            "sampleTaxi", "_SUCCESS")
delete_command <- paste("fs -rm", file_to_delete)
rxHadoopCommand(delete_command)


myNameNode <- "default"
myPort <- 0
hdfsFS <- RxHdfsFileSystem(hostName = myNameNode, 
                           port = myPort)

taxi_text <- RxTextData(file.path(data_path,
                                  "sampleTaxi"),
                        fileSystem = hdfsFS)

taxi_xdf <- RxXdfData(file.path(data_path, "taxiXdf"),
                      fileSystem = hdfsFS)


rxImport(inData = taxi_text, taxi_xdf, overwrite = TRUE)
rxGetInfo(taxi_xdf)

# create RxSpark compute context
computeContext <- RxSpark(consoleOutput=TRUE,
                          nameNode=myNameNode,
                          port=myPort,
                          executorCores=13, 
                          executorMem = "20g", 
                          executorOverheadMem = "20g", 
                          persistentRun = TRUE, 
                          extraSparkConfig = "--conf spark.speculation=true")

rxSetComputeContext(computeContext)

taxi_Fxdf <- RxXdfData(file.path(data_path, "taxiXdfFactors"),
                       fileSystem = hdfsFS)


rxFactors(inData = taxi_xdf, outFile = taxi_Fxdf, 
          factorInfo = c("pickup_hour", "pickup_nhood")
)

system.time(linmod <- rxLinMod(tip_pct ~ trip_distance, 
                               data = taxi_xdf, blocksPerRead = 2))