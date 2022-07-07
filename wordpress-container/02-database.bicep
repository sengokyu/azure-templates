param location string = resourceGroup().location
param mariaDbServerName string = 'aciwp${uniqueString(resourceGroup().id)}'
param mariaDbDatabaseName string = 'aciwp'
param mariaDbLogin string = 'dbroot'
param mariaDbPassword string

resource mariaDbServer 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: mariaDbServerName
  location: location
  sku: {
    name: 'B_Gen5_1'
  }
  properties: {
    createMode: 'Default'
    administratorLogin: mariaDbLogin
    administratorLoginPassword: mariaDbPassword
  }
}

resource mariaDbDatabase 'Microsoft.DBforMariaDB/servers/databases@2018-06-01' = {
  name: mariaDbDatabaseName
  parent: mariaDbServer
  properties: {
    charset: 'utf-8'
  }
}
