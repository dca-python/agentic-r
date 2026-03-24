#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# 📁 CREATE A NEW R PROJECT
# Sets up a clean folder structure for an R analysis project.
# No git, no complicated tooling — just organized folders.
# ──────────────────────────────────────────────

REPO_URL="https://raw.githubusercontent.com/dca-python/agentic-r/main"

# ── Helper: offer to run the next script ──
offer_next() {
    local prompt="$1"
    local script_url="$2"
    local answer
    read -rp "$prompt (y/n): " answer
    if [[ "$answer" =~ ^[Yy] ]]; then
        echo ""
        /bin/bash -c "$(curl -fsSL "$script_url")"
        exit 0
    fi
}

clear
echo "=========================================="
echo "📁 NEW R PROJECT SETUP"
echo "=========================================="
echo ""

# ── Ask for project name ──
read -rp "What should your project be called? (use kebab-case, e.g. housing-analysis): " PROJECT_NAME

# Clean the name: lowercase, replace spaces with dashes, remove special characters
PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

if [[ -z "$PROJECT_NAME" ]]; then
    echo "❌ No project name provided. Exiting."
    exit 1
fi

# Default location: user's home directory
PROJECT_DIR="$HOME/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
    echo "⚠️  A folder called '$PROJECT_NAME' already exists at $PROJECT_DIR."
    echo "   Pick a different name or delete the existing folder first."
    exit 1
fi

echo ""
echo "Creating project at: $PROJECT_DIR"
echo ""

# ── Create folder structure ──
mkdir -p "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR/data/raw"
mkdir -p "$PROJECT_DIR/data/processed"
mkdir -p "$PROJECT_DIR/output/figures"
mkdir -p "$PROJECT_DIR/output/tables"
mkdir -p "$PROJECT_DIR/src"

echo "  📂 data/raw/         ← put your original data files here (CSVs, Excel, etc.)"
echo "  📂 data/processed/   ← cleaned/transformed data goes here"
echo "  📂 output/figures/   ← plots and visualizations"
echo "  📂 output/tables/    ← exported tables and summaries"
echo "  📂 src/              ← your R scripts"

# ── Create starter R script ──
cat > "$PROJECT_DIR/src/01_load_data.R" << 'RSCRIPT'
# ──────────────────────────────────────────────
# 01_load_data.R
# Load and inspect raw data
# ──────────────────────────────────────────────

library(tidyverse)

# Load your data (edit the path below)
# df <- read_csv(here::here("data/raw/your_file.csv"))

# Quick inspection
# glimpse(df)
# summary(df)
RSCRIPT

cat > "$PROJECT_DIR/src/02_clean_data.R" << 'RSCRIPT'
# ──────────────────────────────────────────────
# 02_clean_data.R
# Clean and transform data
# ──────────────────────────────────────────────

library(tidyverse)

# Load the raw data
# source(here::here("src/01_load_data.R"))

# Cleaning steps
# df_clean <- df |>
#   filter(!is.na(key_variable)) |>
#   mutate(new_column = some_transformation)

# Save processed data
# write_csv(df_clean, here::here("data/processed/cleaned_data.csv"))
RSCRIPT

cat > "$PROJECT_DIR/src/03_analysis.R" << 'RSCRIPT'
# ──────────────────────────────────────────────
# 03_analysis.R
# Main analysis
# ──────────────────────────────────────────────

library(tidyverse)

# Load cleaned data
# df <- read_csv(here::here("data/processed/cleaned_data.csv"))

# Your analysis here

# Save plots
# ggsave(here::here("output/figures/my_plot.png"), width = 8, height = 6)
RSCRIPT

echo ""

# ── Create .Rprofile for the project ──
cat > "$PROJECT_DIR/.Rprofile" << 'RPROFILE'
# Project-level R configuration
# This file runs automatically when R starts in this folder.

if (interactive()) {
  message("📂 Working in: ", basename(getwd()))

  # Ensure 'here' package is available for consistent file paths
  if (!requireNamespace("here", quietly = TRUE)) {
    message("💡 Tip: install.packages('here') for easier file path management")
  }
}
RPROFILE

echo "  📄 .Rprofile          ← auto-runs when R starts in this folder"

# ── Create a README for the project ──
cat > "$PROJECT_DIR/README.md" << README
# $PROJECT_NAME

## What this project does

(Describe your research question or analysis goal here.)

## Data

Put raw data files in \`data/raw/\`. Processed data goes in \`data/processed/\`.

## Scripts

Run scripts in order:

1. \`src/01_load_data.R\` — Load and inspect raw data
2. \`src/02_clean_data.R\` — Clean and transform
3. \`src/03_analysis.R\` — Main analysis and plots

## Output

Figures are saved to \`output/figures/\`, tables to \`output/tables/\`.
README

echo "  📄 README.md           ← project description (edit this)"
echo ""

# ── Install 'here' package if not present ──
if command -v Rscript &> /dev/null; then
    echo "📦 Making sure the 'here' package is installed (for file path management)..."
    Rscript -e "if (!requireNamespace('here', quietly = TRUE)) install.packages('here', repos = 'https://cloud.r-project.org')" 2>/dev/null || {
        echo "⚠️  Could not install 'here'. Run install.packages('here') in R later."
    }
fi

echo ""
echo "=========================================="
echo "🎉 PROJECT CREATED!"
echo "=========================================="
echo ""
echo "To start working:"
echo "  1. Open VS Code"
echo "  2. Go to File → Open Folder → select '$PROJECT_NAME' in your home directory"
echo "  3. Open src/01_load_data.R and start editing"
echo ""
echo "💡 Tip: Put your data files (CSV, Excel, etc.) into the data/raw/ folder."
echo ""

# Open the project in VS Code
if command -v code &> /dev/null; then
    read -rp "Open this project in VS Code now? (y/n): " OPEN_VSCODE
    if [[ "$OPEN_VSCODE" =~ ^[Yy] ]]; then
        code "$PROJECT_DIR"
    fi
fi

echo ""
echo "------------------------------------------"
echo ""
echo "What's next?"
echo ""
offer_next "Make VS Code feel like RStudio?" "$REPO_URL/rstudio-feel.sh"
echo ""
offer_next "Run the full setup (Homebrew, R, VS Code, Node.js)?" "$REPO_URL/setup.sh"
echo ""
