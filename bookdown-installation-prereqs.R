# SparkR-example ----------------------------------------------------------

install.packages("nycflights13")

library(SparkR)
sc <- SparkR::sparkR.init(master = "yarn-client") 
sqlContext <-sparkRHive.init(sc)

cardf <- createDataFrame(sqlContext, cars)

flightsdf <- createDataFrame(sqlContext, nycflights13::flights)
jfk_flights <- filter(flightsdf, flightsdf$origin == "JFK")
# Group the flights by destination and aggregate by the number of flights
dest_flights <- summarize(
  group_by(jfk_flights, jfk_flights$dest), 
  count = n(jfk_flights$dest)
)
# Now sort by the `count` column and print the first few rows
head(arrange(dest_flights, desc(dest_flights$count)))


# bookdown installation ---------------------------------------------------


install.packags('servr')
devtools::install_github("rstudio/bookdown")
devtools::install_github('rstudio/shiny')
devtools::install_github("timelyportfolio/rcdimple")
devtools::install_github("ramnathv/rCharts")
devtools::install_github("ramnathv/rMaps")