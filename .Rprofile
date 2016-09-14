local({
  r <- getOption("repos");
  r["CRAN"] <- "https://mran.revolutionanalytics.com/snapshot/2016-07-05/"
  options(repos = r)
})

.First <- function() {
  
  .libPaths(c(.libPaths(), file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
  pkgs_to_load <- c(getOption("defaultPackages"), "SparkR")
  options(defaultPackages = pkgs_to_load,
          continue = " ",
          stringsAsFactors = FALSE,
          warnPartialMatchAttr = TRUE,
          warnPartialMatchDollar = TRUE,
          max.print = 1000)
  
}

.Last <- function() {
  if (interactive()) {
    hist_file <- Sys.getenv("R_HISTFILE")
    if (hist_file == "")
      hist_file <- "~/.RHistory"
    savehistory(hist_file)
  }
}
