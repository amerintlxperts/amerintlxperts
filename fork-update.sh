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

# Function to prompt for GitHub username with a default value
prompt_github_username() {
    local default_user=$(get_github_username)
    read -e -p "Enter your personal GitHub account name [${default_user:-no user found}]: " -i "$default_user" USER
    if [[ -z "$USER" ]]; then
        echo "No GitHub username provided. Exiting."
        exit 1
    fi
}

# Function to check if repo is a fork
is_repo_fork() {
    local repo_owner="$1"
    local repo_name="$2"
    local parent_name="$ORG/$repo_name"
    
    local repo_info=$(gh repo view "$repo_owner/$repo_name" --json parent --no-pager 2>&1)
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
        return 0
    else
        echo "Failed to sync $repo_name. Please check for errors."
        return 1
    fi
}

# Function to enable workflows in repository
enable_workflows() {
    local repo_owner="$1"
    local repo_name="$2"
    if gh api -H "Accept: application/vnd.github.v3+json" -X PUT "/repos/$repo_owner/$repo_name/actions/permissions/workflow" -f enabled=true --silent; then
        echo "Successfully enabled workflows for $repo_name."
        return 0
    else
        local error=$(gh api -H "Accept: application/vnd.github.v3+json" -X PUT "/repos/$repo_owner/$repo_name/actions/permissions/workflow" -f enabled=true -F error=true 2>&1)
        echo "Failed to enable workflows for $repo_name. Error details: $error" >&2
        return 1
    fi
}

# Main execution
prompt_github_username

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

# Loop through each repository
for REPO in "${REPOS[@]}"; do
    echo "Checking $REPO..."

    # Check if the repository exists in the personal account
    if gh repo view "$USER/$REPO" --no-pager &> /dev/null; then
        if is_repo_fork "$USER" "$REPO"; then
            echo "Repository $REPO is a fork. Syncing..."
            sync_repo "$USER" "$REPO" && enable_workflows "$USER" "$REPO"
        else
            echo "Repository $REPO exists but is not a fork of $ORG/$REPO. Skipping."
        fi
    else
        # If repo doesn't exist, fork it
        echo "Forking $ORG/$REPO to your personal GitHub account..."
        if gh repo fork "$ORG/$REPO" --clone=false; then
            echo "Successfully forked $ORG/$REPO."
            # Sync immediately after forking
            sync_repo "$USER" "$REPO" && enable_workflows "$USER" "$REPO"
        else
            echo "Failed to fork $ORG/$REPO. Please check for errors."
        fi
    fi
done

echo "All operations completed."