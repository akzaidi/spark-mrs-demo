sparkEnvir <- list(spark.executor.instance = '10',
                   spark.yarn.executor.memoryOverhead = '8000')

sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)

sqlContext <- sparkRSQL.init(sc)


dataframe_import <- function(path = "/") {
  
  library(SparkR)
  path <- file.path(path)
  path_df <- read.df(sqlContext, path,
                     source = "com.databricks.spark.csv",
                     header = "true", inferSchema = "true", delimiter = ",")
  
  return(path_df)
  
}

# full_taxi <- dataframe_import()
