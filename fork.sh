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

is_repo_fork() {
    local repo_owner="$1"
    local repo_name="$2"
    local parent_name="$ORG/$repo_name"
    
    # Fetch repo information, capturing any error output
    local repo_info=$(gh repo view "$repo_owner/$repo_name" --json parent 2>&1)
    local exit_status=$?
    
    # Check if there was an error with the gh command
    if [ $exit_status -ne 0 ]; then
        echo "Error fetching repo info for $repo_owner/$repo_name: $repo_info" >&2
        return 1
    fi
    
    # Debug: Print the raw JSON response
    echo "Repo info: $repo_info" >&2
    
    # Use jq to parse JSON, extracting the parent repo's full name
    local parent=$(echo "$repo_info" | jq -r '.parent | if type == "object" then (.owner.login + "/" + .name) else "" end')
    
    # Check if the parent repo matches
    if [ "$parent" = "$parent_name" ]; then
        return 0 # It is a fork
    else
        echo "Parent repo mismatch: Expected $parent_name, got $parent" >&2
        return 1 # It is not a fork
    fi
}

# Function to sync repo
sync_repo() {
    local repo_owner="$1"
    local repo_name="$2"
    echo "Syncing $repo_name with upstream..."
    if gh repo sync "$repo_owner/$repo_name" --force; then
        echo "Successfully synced $repo_name."
    else
        echo "Failed to sync $repo_name. Please check for errors."
    fi
}

# Loop through each repository
for REPO in "${REPOS[@]}"; do
    echo "Checking $REPO..."

    # Check if the repository exists in the personal account
    if gh repo view "$USER/$REPO" &> /dev/null; then
        # If exists, check if it's a fork of the organization repo
        if is_repo_fork "$USER" "$REPO"; then
            sync_repo "$USER" "$REPO"
        else
            echo "Repository $REPO exists but is not a fork of $ORG/$REPO. Skipping."
        fi
    else
        # If repo doesn't exist, fork it
        echo "Forking $ORG/$REPO to your personal GitHub account..."
        if gh repo fork "$ORG/$REPO" --clone=false; then
            echo "Successfully forked $ORG/$REPO."
        else
            echo "Failed to fork $ORG/$REPO. Please check for errors."
        fi
    fi
done

echo "All operations completed."