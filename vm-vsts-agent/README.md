# VisualStudio TeamService Agent on Ubuntu 18.04

# What include ?

* Virtual Network and Subnet
* Network Interface
* Virtual Machine (Ephemental OS disk)
* Custom Script Extension (Install VSTS Agent)

# Parameters

* addressPrefixes (optional)
* subnetAddressPrefix (optional)
* vmSize
* username (optional)
* password (optional)
* count (optional) - Number of Agents
* orgName - Name of Azure Devops Organization
* poolName - Name of Azure Devops Pipelines Agent Pool
* token - Personal Access Token of Azure Devops


# Getting Started

Create a resource group.

```bash:
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
```

Edit a parameters.json.

```bash:
cp parameters.sample.json parameters.json
vi parameters.json
```

Validate a template.

```bash:
RG=$RESOURCE_GROUP_NAME make validate
```

Deploy a template.

```bash:
RG=$RESOURCE_GROUP_NAME make deploy
```


# Delete all resources in the resource group

```bash:
RG=$RESOURCE_GROUP_NAME make clean
```
