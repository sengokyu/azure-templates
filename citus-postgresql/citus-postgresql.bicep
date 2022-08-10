@description('Name of server group')
param serverGroupName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

@description('PostgreSQL version')
@allowed([
  '14'
  '13'
  '12'
  '11'
])
param postgresqlVersion string = '14'

@description('PostgreSQL Server backup retention days')
param backupRetentionDays int = 1

param coordinatorVcores int = 2
param coordinatorStorageSizeMB int = 131072 // 128GB
param numWorkers int = 0
param workerVcores int = 2
param workerStorageSizeMB int = 131072 // 128GB
param enableHa bool = false
param enablePublicIpAccess bool = true
param enablePreviewFeatures bool = true
param enableMx bool = false
param enableZfs bool = false


resource serverGroup 'Microsoft.DBforPostgreSQL/serverGroupsv2@2020-10-05-privatepreview' = {
  name: serverGroupName
  location: location
  properties: {
    createMode: 'Default'
    administratorLogin: 'citus'
    administratorLoginPassword: administratorLoginPassword
    backupRetentionDays: backupRetentionDays
    enableMx: enableMx
    enableZfs: enableZfs
    previewFeatures: enablePreviewFeatures
    postgresqlVersion: postgresqlVersion
    serverRoleGroups: [
      {
        name: ''
        role: 'Coordinator'
        serverCount: 1
        serverEdition: 'GeneralPurpose'
        vCores: coordinatorVcores
        storageQuotaInMb: coordinatorStorageSizeMB
        enableHa: enableHa
      }
      {
        name: ''
        role: 'Worker'
        serverCount: numWorkers
        serverEdition: 'MemoryOptimized'
        vCores: workerVcores
        storageQuotaInMb: workerStorageSizeMB
        enableHa: enableHa
        enablePublicIpAccess: enablePublicIpAccess
      }
    ]
  }
}
