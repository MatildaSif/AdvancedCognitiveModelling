#!/bin/bash

# UCloud R-Studio Setup Script
# Purpose: Ensure correct virtual environment, GitHub sync, and Stan/brms setup

set -e  # Exit on error

echo "=================================="
echo "UCloud R-Studio Setup Script"
echo "=================================="

# Configuration Variables
REPO_URL="https://github.com/JSejrskild/Advanced_Cognitive_Modelling_2026.git"
REPO_DIR="/work/ACM_2026/Advanced_Cognitive_Modelling_2026"
VENV_NAME="r_analysis_env"  # Name for your virtual environment
GITHUB_USER="JSejrskild"
GITHUB_EMAIL="johannesejrskild.1@gmail.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# 1. VIRTUAL ENVIRONMENT SETUP
# ============================================

echo -e "\n${YELLOW}[1/4] Checking Virtual Environment...${NC}"

if [ -d "$HOME/$VENV_NAME" ]; then
    echo -e "${GREEN}✓ Virtual environment '$VENV_NAME' exists${NC}"
else
    echo -e "${YELLOW}Creating new virtual environment '$VENV_NAME'...${NC}"
    # For Python virtual environment (if needed)
    # python3 -m venv "$HOME/$VENV_NAME"
    mkdir -p "$HOME/$VENV_NAME"
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

# Activate virtual environment (if using Python venv)
# source "$HOME/$VENV_NAME/bin/activate"

# ============================================
# 2. GITHUB AUTHENTICATION & SETUP
# ============================================

echo -e "\n${YELLOW}[2/4] GitHub Authentication...${NC}"

# Check if git is configured
if git config --global user.name > /dev/null 2>&1; then
    GITHUB_USER=$(git config --global user.name)
    echo -e "${GREEN}✓ Already logged in as: $GITHUB_USER${NC}"
else
    echo -e "${YELLOW}Setting up Git configuration...${NC}"
    read -p "Enter your GitHub username: " git_username
    read -p "Enter your GitHub email: " git_email
    
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    
    echo -e "${GREEN}✓ Git configured for $git_username${NC}"
fi

# Check GitHub credential helper
if ! git config --global credential.helper > /dev/null 2>&1; then
    git config --global credential.helper store
    echo -e "${GREEN}✓ Credential helper configured${NC}"
fi

# ============================================
# 3. REPOSITORY MANAGEMENT
# ============================================

echo -e "\n${YELLOW}[3/4] Repository Management...${NC}"

if [ -d "$REPO_DIR" ]; then
    echo -e "${GREEN}✓ Repository directory exists${NC}"
    cd "$REPO_DIR"
    
    # Check if it's a valid git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        
        # Check if repository has any commits
        if git rev-parse HEAD > /dev/null 2>&1; then
            echo "Pulling latest changes..."
            
            # Stash any local changes
            if ! git diff-index --quiet HEAD --; then
                echo -e "${YELLOW}⚠ Local changes detected, stashing...${NC}"
                git stash
            fi
            
            # Pull from remote
            if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
                echo -e "${GREEN}✓ Repository updated${NC}"
            else
                echo -e "${RED}✗ Failed to pull. Check your connection and credentials.${NC}"
                exit 1
            fi
        else
            # Repository exists but has no commits yet
            echo -e "${YELLOW}⚠ Repository has no commits yet. Fetching from remote...${NC}"
            if git fetch origin && (git checkout main 2>/dev/null || git checkout master 2>/dev/null); then
                echo -e "${GREEN}✓ Repository initialized from remote${NC}"
            else
                echo -e "${YELLOW}⚠ Empty repository - will use as-is${NC}"
            fi
        fi
        
    else
        echo -e "${RED}✗ Directory exists but is not a git repository${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Cloning repository for the first time...${NC}"
    
    if git clone "$REPO_URL" "$REPO_DIR"; then
        echo -e "${GREEN}✓ Repository cloned successfully${NC}"
        cd "$REPO_DIR"
    else
        echo -e "${RED}✗ Failed to clone repository${NC}"
        echo -e "${YELLOW}Note: If authentication fails, you may need to use a Personal Access Token${NC}"
        echo -e "${YELLOW}Generate one at: https://github.com/settings/tokens${NC}"
        exit 1
    fi
fi

# ============================================
# 4. R PACKAGES & STAN/BRMS SETUP
# ============================================

echo -e "\n${YELLOW}[4/4] Setting up R packages, Stan, and brms...${NC}"

# Create R script for package installation
cat > /tmp/setup_r_packages.R <<'EOF'
# R Package Setup Script

cat("\n=== Installing R Packages ===\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Function to check and install packages
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste("Installing", pkg, "...\n"))
    install.packages(pkg)
    library(pkg, character.only = TRUE)
    cat(paste("✓", pkg, "installed successfully\n"))
  } else {
    cat(paste("✓", pkg, "already installed\n"))
  }
}

# Stan and brms setup (from your professor's code)
cat("\n--- Setting up Stan and brms ---\n")

# Set environment variable for V8
Sys.setenv(DOWNLOAD_STATIC_LIBV8 = 1)

# Install Rcpp from source
if (!require("Rcpp", quietly = TRUE)) {
  cat("Installing Rcpp from source...\n")
  install.packages("Rcpp", type = "source")
}

# Install cmdstanr
if (!require("cmdstanr", quietly = TRUE)) {
  cat("Installing cmdstanr...\n")
  install.packages("cmdstanr", 
                   repos = c("https://mc-stan.org/r-packages/", 
                            getOption("repos")))
}

library(cmdstanr)

# Check/Install CmdStan toolchain
cat("\nChecking CmdStan toolchain...\n")
check_cmdstan_toolchain()

# Check if CmdStan is installed
cmdstan_installed <- FALSE
tryCatch({
  path <- cmdstan_path()
  if (dir.exists(path)) {
    cmdstan_installed <- TRUE
    cat("✓ CmdStan already installed at:", path, "\n")
  }
}, error = function(e) {
  cmdstan_installed <- FALSE
})

# Install CmdStan if not installed
if (!cmdstan_installed) {
  cat("\nInstalling CmdStan (this may take several minutes)...\n")
  install_cmdstan(cores = parallel::detectCores())
  
  # Set the path after installation
  tryCatch({
    # Refresh the cmdstan path
    path_check <- cmdstan_path()
    cat("✓ CmdStan installed successfully at:", path_check, "\n")
  }, error = function(e) {
    # If path still not found, try to set it manually
    cat("Setting CmdStan path manually...\n")
    default_path <- file.path(Sys.getenv("HOME"), ".cmdstan")
    if (dir.exists(default_path)) {
      set_cmdstan_path(default_path)
      cat("✓ CmdStan path set to:", default_path, "\n")
    } else {
      cat("⚠ Warning: Could not automatically set CmdStan path\n")
      cat("You may need to run: set_cmdstan_path('your_path')\n")
    }
  })
}

# Install brms
install_if_missing("brms")

# Install tidyverse
install_if_missing("tidyverse")

# Additional useful packages (optional - comment out if not needed)
# install_if_missing("rstan")
# install_if_missing("ggplot2")
# install_if_missing("dplyr")

cat("\n=== R package setup complete! ===\n")

# Verify installation
cat("\n--- Verification ---\n")
cat("cmdstanr version:", as.character(packageVersion("cmdstanr")), "\n")
cat("CmdStan path:", cmdstan_path(), "\n")
cat("brms version:", as.character(packageVersion("brms")), "\n")
cat("tidyverse version:", as.character(packageVersion("tidyverse")), "\n")
EOF

# Run the R script
echo "Running R package installation (this may take a while on first run)..."
Rscript /tmp/setup_r_packages.R

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ R packages, Stan, and brms configured successfully${NC}"
else
    echo -e "${RED}✗ Error during R package setup${NC}"
    exit 1
fi

# Clean up
rm /tmp/setup_r_packages.R

# ============================================
# COMPLETION
# ============================================

echo -e "\n${GREEN}=================================="
echo "✓ Setup Complete!"
echo "==================================${NC}"
echo -e "Repository: ${GREEN}$REPO_DIR${NC}"
echo -e "GitHub User: ${GREEN}$GITHUB_USER${NC}"
echo -e "You can now start working in R-Studio"
echo ""

# Return to repo directory
cd "$REPO_DIR"