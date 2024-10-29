#!/bin/bash

# Prompt for personal GitHub account name
read -p "Enter your personal GitHub account name: " USER

# List of repositories to be forked
REPOS=(
  "infrastructure"
  "amerintlxperts"
  "cloud"
  "ot"
  "sase"
  "secops"
  "theme"
  "docs-builder"
  "mkdocs"
  "references"
)

# GitHub organization name
ORG="amerintlxperts"

# Loop through each repository and fork it to your personal GitHub account
for REPO in "${REPOS[@]}"; do
  echo "Checking if repository $REPO already exists in your personal GitHub account..."
  
  # Check if the repository already exists
  if gh repo view "$USER/$REPO" --json parent -q ".parent.name" &>/dev/null; then
    PARENT_REPO=$(gh repo view "$USER/$REPO" --json parent -q ".parent.fullName")
    
    # Check if the existing repo is a fork of the specified org repo
    if [ "$PARENT_REPO" == "$ORG/$REPO" ]; then
      echo "Repository $REPO is already a fork of $ORG/$REPO. Skipping."
      continue
    else
      echo "Repository $REPO exists in your account but is not a fork of $ORG/$REPO. Skipping."
      continue
    fi
  fi

  # Fork the repository if it doesn't exist or is not a fork
  echo "Forking $ORG/$REPO to your personal GitHub account..."
  gh repo fork "$ORG/$REPO" --clone=false
  
  # Check if the forking was successful
  if [ $? -eq 0 ]; then
    echo "Successfully forked $ORG/$REPO."
  else
    echo "Failed to fork $ORG/$REPO. Please check for errors."
  fi
done

echo "All operations completed."
