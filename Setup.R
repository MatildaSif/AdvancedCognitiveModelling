# Set Session Options
options(
  digits = 6, # Significant figures output
  scipen = 999, # Disable scientific notation
  repos = getOption("repos")["CRAN"] # Install packages from CRAN
)

# Set the makeflags to use multiple cores for faster compilation
Sys.setenv(
  MAKEFLAGS = paste0(
    "-j", 
    parallel::detectCores(logical = FALSE)
  ))


