@description('The location of where teh resources are being deployed.')
param location string = resourceGroup().location

@description('The admin user name.')
@secure()
param adminUsername string

@description ('The admin user password.')
@secure()
param adminPassword string

@description('The sql managed instance sku name.')
@allowed([
  'GP_Gen5'
  'BC_Gen5'
])
param skuName string

@description('The number of vCores.')
@allowed([
  4
  8
  16
  24
  32
  40
  64
  80
])
param vCores int

@description('The storage size in GB.')
@minValue(32)
@maxValue(8192)
param storageSizeGB int

param managedInstanceName string = 'mySqlManagedInstance'

resource sqlManagedInstance 'Microsoft.Sql/managedInstances@2021-02-01-preview' = {
  name: 'mySqlManagedInstance'
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    
  sku: {
      name: skuName
      tier: 'GeneralPurpose'
      family: 'Gen5'
      capacity: vCores
    }
  storage: {
      storageSizeGB: storageSizeGB
    }
  }
}

resource sqlMI2019 'Microsoft.Sql/managedInstances@2021-02-01-preview' = {
  name: managedInstanceName
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    sku: {
      name: skuName
      tier: 'BusinessCritical'
      family: 'Gen5'
      capacity: vCores
    }
    storage: {
      storageSizeGB: storageSizeGB
    }
  }
}
