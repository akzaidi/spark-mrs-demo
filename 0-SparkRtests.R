
# add spark/r/lib to libPaths ---------------------------------------------

.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
library(SparkR)

# specify memory environment variables
sparkEnvir <- list(spark.executor.instance = '10',
                   spark.yarn.executor.memoryOverhead = '8000')

sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)


# to work with DataFrames (not to be confused with R data.frames), need
# a SQLContext

# reading csvs requires using spark-csv package
# Sys.setenv('SPARKR_SUBMIT_ARGS'='"--packages" "com.databricks:spark-csv_2.10:1.4.0" "sparkr-shell"')
sqlContext <- sparkRSQL.init(sc)

airPath <- file.path(bigDataDirRoot, "AirlineDemoSmall.csv")


df <- read.df(sqlContext, inputFile,
              source = "com.databricks.spark.csv", 
              inferSchema = "true")


# Fit a gaussian GLM model over the dataset.
sparkr_time <- system.time(model.glm <- glm(ArrDelay ~ CRSDepTime + DayOfWeek, data = df, family = "gaussian"))

# compare to rxGlm

scaler_time <- system.time(model.rxglm <- rxGlm(ArrDelay ~ CRSDepTime + DayOfWeek, data = airDS, family = "gaussian"))