# Control Repository

This repository has scripts that hydrate the project

## Sync Forks to your personal Github account

Run the script fork-update.sh to create your local copies and to also sync with the parents.

```
./fork-update.sh
```

## Deploy Environment

1. The mkdocs base container is a dependency for building the documentation. The first task is to make sure the mkdocs workflow has successfully completed.

```
gh workflow run "Build and Push Docker Image" --repo ${GITHUB_ORG}/mkdocs
```

## Get KubeConfig

```
z aks get-credentials --resource-group amerintlxperts --name amerintlxperts_k8s-cluster_eastus --overwrite-existing
```

2. Provision the Azure Resources

```
gh secret set DEPLOYED -b "[true|false]" --repo ${GITHUB_ORG}/infrastructure
gh workflow run infrastructure --repo ${GITHUB_ORG}/infrastructure
```

## Contributing

After changes are commited and pushed to a local fork, create a pull request to the parent using the Github UI or the following cli commands.

```
git remote add upstream https://github.com/amerintlxperts/amerintlxperts.git
gh repo set-default amerintlxperts/amerintlxperts

