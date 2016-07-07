
# install-pkgs ------------------------------------------------------------


devtools::install_github("rstudio/sparkapi", build_vignettes = TRUE)
devtools::install_github("rstudio/sparklyr", build_vignettes = TRUE)

library(sparklyr)
library(dplyr)


# add-spark-location ------------------------------------------------------



if (nchar(Sys.getenv("SPARK_HOME")) < 1) {
  spark_path <- strsplit(system("brew info apache-spark",intern=T)[4],' ')[[1]][1]
  Sys.setenv(SPARK_HOME = spark_path)
  .libPaths(c(file.path(spark_path,"libexec", "R", "lib"), .libPaths())) # Navigate to SparkR folder
}



# install-spark -----------------------------------------------------------

library(sparklyr)
spark_install(version = "1.6.1")



# create-spark-context ----------------------------------------------------


sc <- spark_connect(master = "local")



# load-data-tbls ----------------------------------------------------------


library(dplyr)
iris_tbl <- copy_to(sc, iris)
flights_tbl <- copy_to(sc, nycflights13::flights, "flights")
batting_tbl <- copy_to(sc, Lahman::Batting, "batting")
src_tbls(sc)



# using-dplyr-verbs -------------------------------------------------------
library(ggplot2)

flights_tbl %>% filter(dep_delay == 2)

flights_tbl %>% 
  group_by(tailnum) %>%
  summarise(count = n(), dist = mean(distance), delay = mean(arr_delay)) %>%
  filter(count > 20, dist < 2000, !is.na(delay)) %>%
  collect %>% 
  ggplot(aes(dist, delay)) +
  geom_point(aes(size = count), alpha = 1/2) +
  geom_smooth() +
  scale_size_area(max_size = 2)

