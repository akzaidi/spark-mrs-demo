sparkEnvir <- list(spark.executor.instance = '10',
                   spark.yarn.executor.memoryOverhead = '8000')

sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)

sqlContext <- sparkRHive.init(sc)


dataframe_import <- function(path = "/") {
  
  library(SparkR)
  path <- file.path(path)
  path_df <- read.df(sqlContext, path,
                     source = "com.databricks.spark.csv",
                     header = "true", inferSchema = "true", delimiter = ",")
  
  return(path_df)
  
}

taxi_trip <- dataframe_import(path = "wasb://nyctaxidata@alizaidi.blob.core.windows.net/trips")
taxi_fares <- dataframe_import(path = "wasb://nyctaxidata@alizaidi.blob.core.windows.net/fares")

taxi_fare_names <- names(taxi_fares)
taxi_fare_names <- ifelse(substr(taxi_fare_names, 1, 1) == " ", 
                          substr(taxi_fare_names, 2, 
                                 nchar(taxi_fare_names)), 
                          taxi_fare_names)
names(taxi_fares) <- taxi_fare_names

merge_taxi <- function(trips = taxi_trip,
                       fares = taxi_fares) {
  
  library(SparkRext)
  
  trips <- trips %>% mutate(mergeid = concat_ws("-", medallion, hack_license,
                                              vendor_id, pickup_datetime))
  
  fares <- fares %>% mutate(mergeid = concat_ws("-", medallion, hack_license,
                                                 vendor_id, pickup_datetime))
  
  fares <- select(fares, mergeid, payment_type, fare_amount, surcharge, 
                  mta_tax, tip_amount, tolls_amount, total_amount)
  
  taxi <- merge(trips, fares, by.x = "mergeid", by.y = "mergeid")
  
  return(taxi)
  
}

download.file("http://www.zillow.com/static/shp/ZillowNeighborhoods-NY.zip",
              destfile = "../ZillowNeighborhoods-NY.zip")
unzip("../ZillowNeighborhoods-NY.zip", exdir = "../ZillowNeighborhoods-NY")
install.packages('maptools')
library(maptools)

nyc_shapefile <- readShapePoly('../ZillowNeighborhoods-NY/ZillowNeighborhoods-NY.shp')

library(ggplot2)
nyc_shapefile@data$id <- as.character(nyc_shapefile@data$NAME)

library(rgeos)
library(gpclib)
nyc_points <- fortify(gBuffer(nyc_shapefile, byid = TRUE, width = 0), region = "NAME") # fortify neighborhood boundaries

data_coords <- data.frame(
  long = ifelse(is.na(nyc_taxi$pickup_longitude), 0, nyc_taxi$pickup_longitude), 
  lat = ifelse(is.na(nyc_taxi$pickup_latitude), 0, nyc_taxi$pickup_latitude)
)
coordinates(data_coords) <- c('long', 'lat') # we specify the columns that correspond to the coordinates
# we replace NAs with zeroes, becuase NAs won't work with the `over` function
nhoods <- over(data_coords, nyc_shapefile) # returns the neighborhoods based on coordinates
nyc_taxi$pickup_nhood <- nhoods$NAME # we attach the neighborhoods to the original data and call it `pickup_nhood`





devtools::install_github("akzaidi/SparkRext")

taxi_hood_sum <- function(taxi_data = taxi_df, ...) {
  
  taxi_data %>% 
    filter(taxi_data$pickup_nhood %in% manhattan_hoods) %>%
    filter(taxi_data$dropoff_nhood %in% manhattan_hoods) %>% 
    group_by(taxi_data$dropoff_nhood, taxi_data$pickup_nhood) %>% 
    summarize(ave_tip = mean(taxi_data$tip_pct), 
              ave_dist = mean(taxi_data$trip_distance)) %>% 
    filter("ave_tip > 0.05") %>% 
    filter("ave_dist > 3") -> sum_df
  
  return(sum_df)
  
}


tile_plot_hood <- function(df = taxi_hood_sum()) {
  
  library(ggplot2)
  
  ggplot(data = df, aes(x = pickup_nhood, y = dropoff_nhood)) + 
    geom_tile(aes(fill = ave_tip), colour = "white") + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = 'bottom') +
    scale_fill_gradient(low = "white", high = "steelblue") -> gplot
  
  return(gplot)
}


taxi_hood_sum <- function(taxi_data = taxi_df, ...) {
  
  taxi_data %>% 
    filter(pickup_nhood %in% manhattan_hoods,
           dropoff_nhood %in% manhattan_hoods, ...) %>% 
    group_by(dropoff_nhood, pickup_nhood) %>% 
    summarize(ave_tip = mean(tip_pct), 
              ave_dist = mean(trip_distance)) %>% 
    filter(ave_dist > 3, ave_tip > 0.05) -> sum_df
  
  return(sum_df)
  
}


tile_plot_hood <- function(df = taxi_hood_sum()) {
  
  library(ggplot2)
  
  ggplot(data = df, aes(x = pickup_nhood, y = dropoff_nhood)) + 
    geom_tile(aes(fill = ave_tip), colour = "white") + 
    theme_bw() + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = 'bottom') + 
    scale_fill_gradient(low = "white", high = "steelblue") -> gplot
  
  return(gplot)
}