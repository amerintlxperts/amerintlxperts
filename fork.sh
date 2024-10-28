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
)

# GitHub organization name
ORG="amerintlxperts"

# Loop through each repository and fork it to your personal GitHub account
for REPO in "${REPOS[@]}"
do
  echo "Checking if repository $REPO already exists in your personal GitHub account..."
  if gh repo view "$USER/$REPO" &>/dev/null; then
    echo "Error: Repository $REPO already exists in your personal GitHub account. Exiting."
    exit 1
  fi

  echo "Forking $ORG/$REPO to your personal GitHub account..."
  gh repo fork "$ORG/$REPO" --clone=false
  if [ $? -eq 0 ]; then
    echo "Successfully forked $ORG/$REPO."
  else
    echo "Failed to fork $ORG/$REPO. Please check for errors."
  fi
done

echo "All operations completed."

