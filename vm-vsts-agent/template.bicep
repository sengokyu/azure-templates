param location string = resourceGroup().location
param addressPrefix string = '10.0.0.0/16'
param subnetAddressPrefix string = '10.0.0.0/24'
param vmSize string = 'Standard_D2as_v4'
param username string = uniqueString(resourceGroup().id)
param password string = '${utcNow()}${uniqueString(resourceGroup().id, deployment().name)}'

@description('Number of Agents')
param count int = 1

@description('Name of Azure DevOps organization')
param orgName string

@metadata({ desciption: 'Name of Azure DevOps Pipelines Pool' })
param poolName string = 'Default'

@description('Personal Access Token')
@secure()
param token string

var names = {
  vnet: 'vnet-${uniqueString(resourceGroup().id)}'
  subnet: 'subnet-0'
  nic: 'nic-${uniqueString(resourceGroup().id)}'
  vm: 'vm-${uniqueString(resourceGroup().id)}'
}
var tag = {
  usage: 'vsts-agent'
}
var scriptUrl = 'https://raw.githubusercontent.com/sengokyu/azure-templates/main/vm-vsts-agent/setup-files/deploy-vsts-agent.sh'

// suitable for apt repository, specified at setup-files/microsoft-prod.list
var ubuntuSku = '18.04-LTS'

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: names.vnet
  location: location
  tags: tag
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: names.subnet
  parent: vnet
  properties: {
    addressPrefix: subnetAddressPrefix
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: names.nic
  location: location
  tags: tag
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: names.vm
  location: location
  tags: tag
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuSku
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: names.vm
      adminUsername: username
      adminPassword: password
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
  }
}

resource custom_script 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: 'setup-vsts-agent-script'
  location: location
  tags: tag
  parent: vm
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: 'COUNT=${count} TOKEN=${token} ORG=${orgName} POOL=${poolName} /bin/bash deploy-vsts-agent.sh'
    }
  }
}

output message string = '[variables(\'names\').vm] has deployed.'
