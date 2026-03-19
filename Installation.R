# Check if any existing Stan packages are installed
{
  ## Check for existing installations
  stan_packages <- installed.packages()[
    grepl("cmdstanr|rstan$|StanHeaders|brms$", 
          installed.packages()[, 1]), 1]
  
  ## Remove any existing Stan packages
  if (length(stan_packages) > 0) {
    remove.packages(c("StanHeaders", "rstan", "brms"))
  }
  
  ## Delete any pre-existing RData file
  if (file.exists(".RData")) {
    file.remove(".RData")
  }
}

# Check if packages necessary for later installation steps are installed
{
  ## Retrieve installed packages
  pkgs <- installed.packages()[, 1]
  
  ## Check if rstudioapi is installed
  if (isTRUE(all.equal(grep("rstudioapi", pkgs), integer(0)))) {
    print("Installing the {rstudioapi} package")
    install.packages("rstudioapi")
  }
  
  ## Check if remotes is installed
  if (isTRUE(all.equal(grep("remotes", pkgs), integer(0)))) {
    print("Installing the {remotes} package")
    install.packages("remotes")
  }
  
  ## Else print a message
  else {
    print("{remotes} and {rstudioapi} packages are already installed")
  }
}



# Install the latest development version of brms from github
remotes::install_github("paul-buerkner/brms")



# Install cmdstanr from github
remotes::install_github("stan-dev/cmdstanr")


# Check that the C++ Toolchain is Configured
cmdstanr::check_cmdstan_toolchain(fix = TRUE)


# Install cmdstan version 2.38
cmdstanr::install_cmdstan(
  cores = parallel::detectCores(logical = FALSE),
  overwrite = TRUE,
  cpp_options = list("STAN_THREADS" = TRUE),
  check_toolchain = TRUE
)


# Verify that cmdstan installed successfully
(cmdstan.version <- cmdstanr::cmdstan_version())

# Ensure cmdstan path is set properly
cmdstanr::set_cmdstan_path(
  path = paste(
    Sys.getenv("HOME"), 
    "/.cmdstan/cmdstan-", 
    cmdstan.version,
    sep = ""
  ))