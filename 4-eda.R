## loading data
## do this everytime the connection expires
.libPaths(c("/home/alizaidi/R/x86_64-pc-linux-gnu-library/3.2", 
            "/usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library", 
            "/usr/hdp/2.4.1.1-3/spark/R/lib"))

library(magrittr)
library(SparkR)

sparkEnvir <- list(spark.executor.instance = '10',
                   spark.yarn.executor.memoryOverhead = '8000')
sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)

sqlContext <- sparkRSQL.init(sc)

data_dir <- "/user/RevoShare/alizaidi"

airPath <- file.path(data_dir, "AirOnTimeCSV")
weatherPath <- file.path(data_dir, "delayDataLarge", "Weather") # pre-processed weather data

airDF <- read.df(sqlContext, airPath, source = "com.databricks.spark.csv",
                 header = "true", inferSchema = "true")

weatherDF <- read.df(sqlContext, weatherPath, source = "com.databricks.spark.csv",
                     header = "true", inferSchema = "true")



## EDA

airDF %<>% rename(airDF,
                  ArrDel15 = airDF$ARR_DEL15,
                  Year = airDF$YEAR,
                  Month = airDF$MONTH,
                  DayofMonth = airDF$DAY_OF_MONTH,
                  DayOfWeek = airDF$DAY_OF_WEEK,
                  Carrier = airDF$UNIQUE_CARRIER,
                  OriginAirportID = airDF$ORIGIN_AIRPORT_ID,
                  DestAirportID = airDF$DEST_AIRPORT_ID,
                  CRSDepTime = airDF$CRS_DEP_TIME,
                  CRSArrTime =  airDF$CRS_ARR_TIME,
                  Distance = airDF$DISTANCE,
                  DepDelay = airDF$DEP_DELAY,
                  ArrDelay = airDF$ARR_DELAY)

air_counts <- airDF %>% 
  SparkR::group_by(airDF$YEAR, airDF$UNIQUE_CARRIER) %>% 
  count() %>% collect()

air_delay_positive <- airDF %>% 
  SparkR::filter(airDF$ARR_DELAY > 0)

air_delay_positive %>% head

counts_by_var <- function(sparkDF = airDF) {
  
  sparkDF %>% 
    SparkR::group_by(sparkDF[["UNIQUE_CARRIER"]]) %>% 
    summariez
    SparkR::count() %>% 
    SparkR::collect() -> counts_df
  
  return(counts_df)
  
  
}


select_cols <- function(sparkDF = airDF) {
  
  library(magrittr)
  
  sparkDF %>% 
    SparkR::select(airDF$FL_DATE, airDF$DAY_OF_WEEK,
                   airDF$UNIQUE_CARRIER, airDF$ORIGIN,
                   airDF$DEST, airDF$ARR_DELAY) -> skinny_df
  
  skinny_df %<>% SparkR::rename(
    flight_date = skinny_df$FL_DATE,
    day_of_week = skinny_df$DAY_OF_WEEK,
    carrier = skinny_df$UNIQUE_CARRIER, 
    origin = skinny_df$ORIGIN,
    destination = skinny_df$DEST, 
    arrival_delay = skinny_df$ARR_DELAY
  )
  
  
  return(skinny_df)
  
} 

# air_df <- select_cols()

agg_delay <- function(airdf = air_df) {
  
  library(magrittr)
  
  airdf %>% SparkR::group_by(airdf$carrier,
                             airdf$origin,
                             airdf$destination) %>% 
    SparkR::summarize(counts = n(airdf$arrival_delay),
                      ave_delay = mean(airdf$arrival_delay)) -> summary_df
  
  return(summary_df)
  
}

# agg_df <- agg_delay()
# agg_df_local <- agg_df %>% collect() %>% dplyr::tbl_df

delays_routes <- function(delay_df = agg_df_local) {
  
  library(dplyr)
  
  delay_df %>%
    group_by(origin, destination) %>%
    summarise(total = sum(counts), 
              arrival_delay = weighted.mean(ave_delay, counts)) -> route_delays
  
  return(route_delays)
  
  
  
}

plot_route_delays <- function(min_routes = 10) {
  
  library(dplyr)
  library(ggplot2)
  
  gplot <- delays_routes() %>% filter(total > min_routes) %>% arrange(desc(total)) %>% 
    filter(origin %in% c("JFK", "LGA", "IAD", "DCA", "ATL", "DFW", "ORD", "IAH", "DEN", "CLT"),
           destination %in% c("ATL", "BDL", "BOS", "JFK", "IAD", "LGA", "DCA", "IAD",
                              "DFW", "ORD", "IAH", "DEN", "CLT")) %>% 
    ggplot(aes(x = origin, y = destination, fill = arrival_delay)) + 
    geom_tile(color = "white") + 
    scale_fill_gradient(low = "white", high = "steelblue")
  
  return(gplot)
  
}