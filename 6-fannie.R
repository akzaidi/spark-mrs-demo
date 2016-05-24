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

performance_import <- function() {
  
  performance <- file.path(data_dir, "Performance")
  perf_df <- read.df(sqlContext, performance,
                     source = "com.databricks.spark.csv",
                     header = "false", inferSchema = "true", delimiter = "|")
  
  return(perf_df)
  
}



acquisition_import <- function() {
  
  library(magrittr)
  
  acquisition <- file.path(data_dir, "Acquisition")
  
  originations <- read.df(sqlContext, acquisition,
                          source = "com.databricks.spark.csv",
                          header = "false", inferSchema = "true", delimiter = "|")
  
  
  originations %<>% SparkR::rename(loan_id  = originations$C0,
                                   orig_chn = originations$C1,
                                   seller_name = originations$C2,
                                   orig_rt = originations$C3,
                                   orig_amt = originations$C4,
                                   orig_trm = originations$C5,
                                   orig_dte = originations$C6,
                                   frst_dte = originations$C7,
                                   oltv = originations$C8,
                                   ocltv = originations$C9,
                                   num_bo = originations$C10,
                                   dti = originations$C11,
                                   cscore_b = originations$C12,
                                   fthb_flg = originations$C13,
                                   purpose = originations$C14,
                                   prop_typ = originations$C15,
                                   num_unit  = originations$C16,
                                   occ_stat  = originations$C17,
                                   state  = originations$C18,
                                   zip_3 = originations$C19,
                                   mi_pct  = originations$C20,
                                   product_type = originations$C21,
                                   cscore_co  = originations$C22)
  return(originations)
  
  
}

originations <- acquisition_import()

originations %>% count
# [1] 21706905

perf_df %<>% rename(LOAN_ID = perf_df$C0,
                    Monthly.Rpt.Prd  = perf_df$C1,
                    Servicer.Name  = perf_df$C2,
                    LAST_RT  = perf_df$C3,
                    LAST_UPB  = perf_df$C4,
                    Loan.Age  = perf_df$C5,
                    Months.To.Legal.Mat = perf_df$C6,
                    Adj.Month.To.Mat  = perf_df$C7,
                    Maturity.Date  = perf_df$C8,
                    MSA  = perf_df$C9,
                    Delq.Status  = perf_df$C10,
                    MOD_FLAG  = perf_df$C11,
                    Zero.Bal.Code = perf_df$C12,
                    ZB_DTE  = perf_df$C13,
                    LPI_DTE  = perf_df$C14,
                    FCC_DTE = perf_df$C15,
                    DISP_DT  = perf_df$C16,
                    FCC_COST  = perf_df$C17,
                    PP_COST  = perf_df$C18,
                    AR_COST  = perf_df$C19,
                    IE_COST  = perf_df$C20,
                    TAX_COST  = perf_df$C21,
                    NS_PROCS = perf_df$C22,
                    CE_PROCS  = perf_df$C23,
                    RMW_PROCS  = perf_df$C24,
                    O_PROCS  = perf_df$C25,
                    NON_INT_UPB  = perf_df$C26,
                    PRIN_FORG_UPB  = perf_df$C27
                    
  
)

perf_df %>% count
# [1] 886220591



originations_dates <- function(orig_df = originations) {
  
  orig_df <- orig_df %>% SparkR::mutate(month = substr(orig_df$orig_dte, 1, 2),
                                year = substr(orig_df$orig_dte, 5, 8))
  
  return(orig_df)
  
}


originations_state <- function(orig_df = originations_dates(originations)) {
  
  orig_df %>% SparkR::group_by(orig_df$state, orig_df$year) %>% 
    SparkR::summarize(ave_dti = mean(orig_df$dti),
              ave_ltv = mean(orig_df$oltv),
              ave_cltv = mean(orig_df$ocltv), 
              ave_fico = mean(orig_df$cscore_b)) -> orig_df
  
  return(orig_df)
  
} 


orig_summary <- originations_state() %>% SparkR::collect

library(rMaps)
# orig_summary %>% 
#   dplyr::mutate(year = as.numeric(year)) %>% 
#   rMaps::ichoropleth(ave_fico ~ state, data = ., 
#                      animate = "year",
#                      geographyConfig = list(popupTemplate = "#!function(geo, data) {
#                                          return '<div class=\"hoverinfo\"><strong>'+
#                                          data.state + '<br>' + 'Average FICO Score in  '+ data.year + ': ' +
#                                          data.ave_fico.toFixed(2)+ 
#                                          '</strong></div>';}!#")) -> state_fico

orig_df %>% 
  dplyr::mutate(year = as.numeric(year)) %>% 
  rMaps::ichoropleth(ave_fico ~ state, data = ., 
                     animate = "year",
                     geographyConfig = list(popupTemplate = "#!function(geo, data) {
                                         return '<div class=\"hoverinfo\"><strong>'+
                                         data.state+ '<br>' + 'Average Credit Score for Loans Originated in '+ data.year + ': ' +
                                         data.ave_fico.toFixed(0) +
                                         '</strong></div>';}!#")) -> state_fico

state_fico$save("StateMapSlider.html", cdn = T)




library(ggplot2)
m <- ggplot(orig_summary, aes(x = ave_ltv, y = ave_fico)) +
  geom_point() + geom_density2d() + stat_density2d(aes(fill = ..level..), geom = "polygon", alpha =0.5) +
  theme_bw()


plot_bin <- function(data = originations) {
  library(ggplot2.SparkR)
  
  plot_data <- data %>% select(data$cscore_b, data$oltv)
  g_plot <- ggplot(plot_data, aes(x = cscore_b, y = oltv)) + geom_bin2d()
  
  return(g_plot)
  
}




## rMaps help

# crime2010 = subset(violent_crime, Year == 2010)
# https://gist.github.com/ramnathv/8936426
choro = ichoropleth(Crime ~ State, data = violent_crime, animate = "Year")
choro$set(geographyConfig = list(
  popupTemplate = "#! function(geography, data){
     return '<div class=hoverinfo><strong>' + geography.properties.name + 
       ': ' + data.Crime + '</strong></div>';
   } !#" 
))