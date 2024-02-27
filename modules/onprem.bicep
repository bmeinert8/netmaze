@description('The location of where the resources will be deployed.')
param location string = resourceGroup().location

@description('The username of the administrator of the virtual machine.')
@secure()
param adminUsername string

@description('The password of the administrator of the virtual machine.')
@secure()
param adminPassword string

@description('The name of the virtual network.')
param onPremVNetName string

@description('The name of the network security group.')
param onPremNSGName string

@description('The name of the network interface card.')
param onPremNICName string

@description('The name of the virtual machine.')
param onPremVMName string

@description('The size of the virtual machine.')
param onPremVMSize string 

var onPremVnetConfig = {
  addressPrefix: '10.0.0.0/16'
  subnetName: 'defaultSubnet'
  subnetPrefix: '10.0.0.0/24'
}

var rdpRuleConfig = {
  name: 'default-allow-rdp'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
  }
}

var onPremVMImageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

resource onPremVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: onPremVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        onPremVnetConfig.addressPrefix
      ]
    }
    subnets: [
      {
        name: onPremVnetConfig.subnetName
        properties: {
          addressPrefix: onPremVnetConfig.subnetPrefix
        }
      }
    ]
  }
  resource onPremSubnet 'subnets' existing = {
    name: onPremVnetConfig.subnetName
  }
}

resource onPremNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: onPremNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: rdpRuleConfig.name
        properties: rdpRuleConfig.properties
      }
    ]
  }
}

resource onPremNetworkInterfaceCard 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: onPremNICName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'myIPConfig'
        properties: {
          subnet: {
            id: onPremVirtualNetwork::onPremSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: onPremNetworkSecurityGroup.id
    }
  }
}

resource onPremVirtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: onPremVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: onPremVMSize
    }
    storageProfile: {
      imageReference: onPremVMImageReference
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: onPremVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: onPremNetworkInterfaceCard.id
        }
      ]
    }
  }
}

output onPremVnetID string = onPremVirtualNetwork.id
