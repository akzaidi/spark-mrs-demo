local({
  r <- getOption("repos");
  r["CRAN"] <- "https://cran.rstudio.com/"
  options(repos = r)
})

.First <- function() {
  
  .libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
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
