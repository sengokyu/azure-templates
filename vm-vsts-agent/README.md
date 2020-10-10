# VisualStudio TeamService Agent on Ubuntu 18.04

# What include ?

* Public IP address.
* Network Security Group.
* Virtual Network and Subnet
* Network Interface
* Virtual Machine (Ephemental OS disk)
* Custom Script Extension (Install VSTS Agent)

# Parameters

* dnsName
* addressPrefixes (optional)
* subnetAddressPrefix (optional)
* vmSize
* username
* sshPublicKey
* sshSourceAddress
* count (optional) - Number of Agents
* orgName - Name of Azure Devops Organization
* poolName - Name of Azure Devops Pipelines Agent Pool
* token - Personal Access Token of Azure Devops
