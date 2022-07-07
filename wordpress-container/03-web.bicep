param appName string = 'aciwp'
param location string = resourceGroup().location
param storageAccountName string
param vnetAddressPrefixes string = '10.0.0.0/16'
param containerSubnetAddressPrefix string = '10.0.1.0/24'
param applicationGatewaySubnetAddressPrefix string = '10.0.2.0/24'
param image string = 'wordpress:php8.1-apache'
param cpuCores int = 1
param memoryInGb int = 1
param applicationGatewaySkuName string = 'Standard_v2'
param applicationGatewayCapacity int = 1
param applicationGatewayTier string = 'Standard_V2'
param domainNameLabel string = '${appName}${uniqueString(resourceGroup().id)}'

var fileShareName = 'wp-content'
var vnetName = '${appName}VNet'
var containerSubnetName = 'container'
var applicationGatewaySubnetName = 'applicationGateway'
var volumeWpContent = 'wp-content'
var applicationGatewayName = '${appName}ApplicationGateway'
var applicationGatewayId = resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)

//
// File share for persist wp-content
//
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

//
// VNET
//
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefixes
      ]
    }
    subnets: [
      {
        name: containerSubnetName
        properties: {
          addressPrefix: containerSubnetAddressPrefix
          delegations: [
            {
              name: 'DelegationService'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: applicationGatewaySubnetName
        properties: {
          addressPrefix: applicationGatewaySubnetAddressPrefix
        }
      }
    ]
  }
}

//
// WordPress container
//
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: '${appName}ContainerGroup'
  location: location
  dependsOn: [
    storageAccount
  ]
  properties: {
    containers: [
      {
        name: appName
        properties: {
          image: image
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
          ports: [

            {
              port: 80
              protocol: 'TCP'
            }
          ]
          volumeMounts: [
            {
              mountPath: '/var/www/html'
              name: volumeWpContent
            }
          ]
        }

      }
    ]
    ipAddress: {
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
      type: 'Private'
    }
    osType: 'Linux'
    subnetIds: [
      {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, containerSubnetName)
      }
    ]
    volumes: [
      {
        name: volumeWpContent
        azureFile: {
          shareName: fileShareName
          storageAccountName: storageAccountName
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
  }
}

//
// Front IP address
//
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${appName}PublicIp'
  location: location
  sku: {
    name: 'Standard' // Application Gatewayに必要
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Application Gatewayに必要
    dnsSettings: {
      domainNameLabel: domainNameLabel
    }
  }
}

//
// Application Gateway
//
resource applicationGateway 'Microsoft.Network/applicationGateways@2022-01-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    enableHttp2: true
    sku: {
      name: applicationGatewaySkuName
      capacity: applicationGatewayCapacity
      tier: applicationGatewayTier
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${applicationGatewaySubnetName}'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'default'
        properties: {
          backendAddresses: [
            {
              ipAddress: reference(containerGroup.id).ipAddress.ip
              fqdn: null
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'default'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: 'default'
        properties: {
          protocol: 'Http'
          sslCertificate: null
          frontendIPConfiguration: {
            id: '${applicationGatewayId}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${applicationGatewayId}/frontendPorts/port_80'
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'default'
        properties: {
          priority: 1000
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayId}/httpListeners/default'
          }
          backendAddressPool: {
            id: '${applicationGatewayId}/backendAddressPools/default'
          }
          backendHttpSettings: {
            id: '${applicationGatewayId}/backendHttpSettingsCollection/default'
          }
        }
      }
    ]
  }
}

output FrontFQDN string = reference(publicIp.id).dnsSettings.fqdn
