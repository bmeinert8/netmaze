param location string = resourceGroup().location
param onPremVnetName string = 'onPrem-Vnet-eastus2'
param hubVnetName string = 'Vnet-eastus2-001'
param spokeVnet1Name string = 'Vnet-eastus2-002'
param spokeVnet2Name string = 'Vnet-eastus2-003'
param sqlVnetName string = 'Vnet-sql-eastus2'

var onPremiseVnetConfig = {
  onPremAddressPrefix: '10.0.0.0/16'
  onPremsubnetName: 'onPremSubnet'
  onPremsubnetPrefix: '10.0.0.0/24'
}

var hubVnetConfig = {
  hubAddressPrefix: '10.60.0.0/16'
  hubSubnet1Name: 'AzureBastionSubnet'
  hubSubnet1Prefix: '10.60.0.0/26'
  hubSubnet2Name: 'GatewaySubnet'
  hubSubnet2Prefix: '10.60.1.0/27'
  hubSubnet3Name: 'Vmapp-Subnet-001'
  hubSubnet3Prefix: '10.60.2.0/24'
  hubSubnet4Name: 'Vmapp-Subnet-002'
  hubSubnet4Prefix: '10.60.3.0/24'
  hubSubnet5Name: 'Appgw-Subnet'
  hubSubnet5Prefix: '10.60.4.0/24'
}

var spokeVnet1Config = {
  spoke1AddressPrefix: '10.70.0.0/16'
  spoke1Subnet1Name: 'Spoke1-vmapp-subnet'
  spoke1Subnet1Prefix: '10.70.0.0/24'
}

var spokenVnet2Config = {
  spoke2AddressPrefix: '10.80.0.0/16'
  spoke2Subnet1Name: 'Spoke2-vmapp-subnet'
  spoke2Subnet1Prefix: '10.80.0.0/24'
}

var sqlVnetConfig = {
  sqlAddressPrefix: '10.90.0.0/16'
  sqlSubnet1Name: 'databasesubnet'
  sqlSubnet1Prefix: '10.90.0.0/24'
}

resource onPremVirtualNetworks 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: onPremVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        onPremiseVnetConfig.onPremAddressPrefix
      ]
    }
    subnets: [
      {
        name: onPremiseVnetConfig.onPremsubnetName
        properties: {
          addressPrefix: onPremiseVnetConfig.onPremsubnetPrefix
        }
      }
    ]
  }
  resource onPremSubnet 'subnets' existing = {
    name: onPremiseVnetConfig.onPremsubnetName
  }
}

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetConfig.hubAddressPrefix
      ]
    }
    subnets: [
      {
        name: hubVnetConfig.hubSubnet1Name
        properties: {
          addressPrefix: hubVnetConfig.hubSubnet1Prefix
        }
      }
      {
        name: hubVnetConfig.hubSubnet2Name
        properties: {
          addressPrefix: hubVnetConfig.hubSubnet2Prefix
        }
      }
      {
        name: hubVnetConfig.hubSubnet3Name
        properties: {
          addressPrefix: hubVnetConfig.hubSubnet3Prefix
        }
      }
      {
        name: hubVnetConfig.hubSubnet4Name
        properties: {
          addressPrefix: hubVnetConfig.hubSubnet4Prefix
        }
      }
      {
        name: hubVnetConfig.hubSubnet5Name
        properties: {
          addressPrefix: hubVnetConfig.hubSubnet5Prefix
        }
      }
    ]
  }
  resource bastionSubnet 'subnets' existing = {
    name: hubVnetConfig.hubSubnet1Name
  }

  resource gatewaySubnet 'subnets' existing = {
    name: hubVnetConfig.hubSubnet2Name
  }

  resource vmappSubnet1 'subnets' existing = {
    name: hubVnetConfig.hubSubnet3Name
  }

  resource vmappSubnet2 'subnets' existing = {
    name: hubVnetConfig.hubSubnet4Name
  }

  resource appGwSubnet 'subnets' existing = {
    name: hubVnetConfig.hubSubnet5Name
  }

  resource vnet0peering1 'virtualNetworkPeerings' = {
    name: '${hubVnetName}-${spokeVnet1Name}'
    properties:{
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      allowGatewayTransit: false
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
      remoteVirtualNetwork: {
        id: spoke1VirtualNetwork.id
      }
    }
  }

  resource vnet0peering2 'virtualNetworkPeerings' = {
    name: '${hubVnetName}-${spokeVnet2Name}'
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      allowGatewayTransit: false
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
      remoteVirtualNetwork:{
        id: spoke2VirtualNetwork.id
      }
    }
  }
}

resource spoke1VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: spokeVnet1Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnet1Config.spoke1AddressPrefix
      ]
    }
    subnets: [
      {
        name: spokeVnet1Config.spoke1Subnet1Name
        properties: {
          addressPrefix: spokeVnet1Config.spoke1Subnet1Prefix
        }
      }
    ]
  }
  resource spoke1VmappSubnet 'subnets' existing = {
    name: spokeVnet1Config.spoke1Subnet1Name
  }

  resource vnet0peering2 'virtualNetworkPeerings' = {
    name: '${spokeVnet1Name}-${hubVnetName}'
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      allowGatewayTransit: false
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
      remoteVirtualNetwork:{
        id: hubVirtualNetwork.id
      }
    }
  }
}

resource spoke2VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: spokeVnet2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokenVnet2Config.spoke2AddressPrefix
      ]
    }
    subnets: [
      {
        name: spokenVnet2Config.spoke2Subnet1Name
        properties: {
          addressPrefix: spokenVnet2Config.spoke2Subnet1Prefix
        }
      }
    ]
  }

  resource spoke2VmappSubnet 'subnets' existing = {
    name: spokenVnet2Config.spoke2Subnet1Name
  }
  
  resource vnet0peering1 'virtualNetworkPeerings' = {
    name: '${spokeVnet2Name}-${hubVnetName}'
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      allowGatewayTransit: false
      useRemoteGateways: false
      doNotVerifyRemoteGateways: false
      remoteVirtualNetwork:{
        id: hubVirtualNetwork.id
      }
    }
  }
}

resource sqlVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: sqlVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        sqlVnetConfig.sqlAddressPrefix
      ]
    }
    subnets: [
      {
        name: sqlVnetConfig.sqlSubnet1Name
        properties: {
          addressPrefix: sqlVnetConfig.sqlSubnet1Prefix
        }
      }
    ]
  }
  resource sqlDbSubnet 'subnets' existing = {
    name: sqlVnetConfig.sqlSubnet1Name
  }
}

output onPremVnetId string = onPremVirtualNetworks.id
output hubVnetId string = hubVirtualNetwork.id
output spokeVnet1Id string = spoke1VirtualNetwork.id
output spokeVnet2Id string = spoke2VirtualNetwork.id
output sqlVnetId string = sqlVirtualNetwork.id
output OnPremSubnetId string = onPremVirtualNetworks::onPremSubnet.id
output BastionSubnetId string = hubVirtualNetwork::bastionSubnet.id
output GatewaySubnetId string = hubVirtualNetwork::gatewaySubnet.id
output VmappSubnet1Id string = hubVirtualNetwork::vmappSubnet1.id
output VmappSubnet2Id string = hubVirtualNetwork::vmappSubnet1.id
output AppGwSubnetId string = hubVirtualNetwork::appGwSubnet.id
output Spoke1VmappSubnetId string = spoke1VirtualNetwork::spoke1VmappSubnet.id
output Spoke2VmappSubnetId string = spoke2VirtualNetwork::spoke2VmappSubnet.id
output SqlDbSubnetId string = sqlVirtualNetwork::sqlDbSubnet.id



