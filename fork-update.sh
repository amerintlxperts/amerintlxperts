#!/bin/bash

# Function to get the GitHub username from 'gh auth status'
get_github_username() {
    local output=$(gh auth status 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Error retrieving GitHub status."
        return 1
    fi
    echo "$output" | grep -oP "(?<=account )[a-zA-Z0-9_\-]+"
}

# Retrieve the GitHub username
USER=$(get_github_username)

# Prompt for personal GitHub account name with default value
read -e -p "Enter your personal GitHub account name [${USER:-no user found}]: " -i "$USER" USER

# Check if USER is empty after prompt
if [[ -z "$USER" ]]; then
    echo "No GitHub username provided. Exiting."
    exit 1
fi

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
  "landing-page"
  "mkdocs"
  "references"
)

# GitHub organization name
ORG="amerintlxperts"

# Function to check if repo is a fork
is_repo_fork() {
    local repo_owner="$1"
    local repo_name="$2"
    local parent_name="$ORG/$repo_name"
    
    local repo_info=$(gh repo view "$repo_owner/$repo_name" --json parent 2>&1)
    local exit_status=$?

    if [ $exit_status -ne 0 ]; then
        echo "Error fetching repo info for $repo_owner/$repo_name: $repo_info" >&2
        return 1
    fi

    echo "Repo info: $repo_info" >&2
    
    local parent=$(echo "$repo_info" | jq -r '.parent | if type == "object" then (.owner.login + "/" + .name) else "" end')
    
    [ "$parent" = "$parent_name" ]
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