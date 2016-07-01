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