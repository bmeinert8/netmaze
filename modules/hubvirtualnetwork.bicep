
@description('The location of where the resources are deployed.')
param location string

@description('The name of the administrator account.')
@secure()
param adminUsername string

@description('The password of the administrator account.')
@secure()
param adminPassword string

@description('The name of the application gateway backend address pool.')
param hubAppGatewayBEName string

@description('The name of the application gateway frontend IP configuration.')
param hubAppGatewayFEName string

@description('The name of the application gateway.')
param hubAppGatewayName string

@description('The name of the application gateway HTTP listener.')
param hubAppGwHttpListenerName string

@description ('A list of the names of the network security groups.')
param NsgNames array

@description ('A list of the names of the public IP addresses.')
param publicIPAddressNames array

@description('The name of the virtual network.')
param hubVnetName string

@description('The name of the network interface for the first virtual machine.')
param vm1NICName string

@description('The name of the Network Interface for the second virtual machine.')
param vm2NICName string

@description('A list of required and optional subnet properties')
param subnets array

@description('The address prefix of the virtual network.')
param vnetAddressPrefix string

@description('The name of the first virtual machine.')
param virtualMachine1Name string

@description('The name of the second virtual machine.')
param virtualMachine2Name string

@description('The size of the virtual machine.')
param vmSize string

@description('The name of the first virtual machine OS disk name.')
param virtualMachine1DiskName string

@description('The name of the second virtual machine OS disk name.')
param virtualMachine2DiskName string

@description('The name of the load balancer.')
param loadBalancerName string

@description('The name of the load balancer frontend IP configuration.')
param loadBalancerFEName string

@description('The name of the load balancer backend pool.')
param loadBalancerBEPoolName string


var lbRule1 = {
  name: 'lbRule1-eus2-001'
  properties: {
    frontendIPConfiguration: {
      id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFEName)
    } 
    backendAddressPool: {
      id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBEPoolName)
    }
    frontendPort: 80
    backendPort: 80
    enableFloatingIP: false
    idleTimeoutInMinutes: 4
    protocol: 'Tcp'
    enableTcpReset: false
    loadDistribution: 'Default'
    disableOutboundSnat: true
    probe: {
      id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, lbProbe.name)
    }
  }
}

var lbProbe = {
  name: 'lbProbe-eus2-001'
  properties: {
    protocol: 'Tcp'
    port: 80
    intervalInSeconds: 5
    numberOfProbes: 1
    probeThreshold: 1
  }
}

var virtualMachineImageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

resource hubAppGateway 'Microsoft.Network/applicationGateways@2023-06-01' = {
  name: hubAppGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: hubVirtualNetwork.properties.subnets[4].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: hubAppGatewayFEName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: hubPublicIPAddresses[1].id
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
        name: hubAppGatewayBEName
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: '${hubAppGatewayName}-http1'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: hubAppGwHttpListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', hubAppGatewayName,hubAppGatewayFEName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendports', hubAppGatewayName,'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule1'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', hubAppGatewayName, hubAppGwHttpListenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', hubAppGatewayName, hubAppGatewayBEName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', hubAppGatewayName,'${hubAppGatewayName}-http1')
          }
        }
      }
    ]
    enableHttp2: false
  }
}

resource hubLoadBalancer 'Microsoft.Network/loadBalancers@2023-06-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerFEName
        properties: {
          publicIPAddress: {
            id: hubPublicIPAddresses[3].id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: loadBalancerBEPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: lbRule1.name
        properties: lbRule1.properties
      }
    ]
    probes: [
      {
        name: lbProbe.name
        properties: lbProbe.properties
      }
    ]
  }
}
    
resource hubVM1NIC 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: vm1NICName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: hubVirtualNetwork.properties.subnets[2].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource hubNetworkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2021-02-01' = [for nsgName in NsgNames: {
  name: nsgName
  location: location
}]

resource hubVM2NIC 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: vm2NICName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: hubVirtualNetwork.properties.subnets[3].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource hubPublicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-02-01' = [for publicIPAddressName in publicIPAddressNames: {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}]

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [ for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }
    ]
  }
}

resource hubWebServerVM1 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine1Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: virtualMachine1DiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: virtualMachine1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: hubVM1NIC.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine1IIS 'extensions' = {
    name: '${virtualMachine1Name}-IIS'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.7'
      settings: {
        commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
      }
    }
  }

  resource virtualMachine1networkWatcherAgent 'extensions' = {
    name: '${virtualMachine1Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

resource hubWebServerVM2 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine1Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: virtualMachine2DiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: virtualMachine1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: hubVM2NIC.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine2IIS 'extensions' = {
    name: '${virtualMachine2Name}-IIS'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.7'
      settings: {
        commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
      }
    }
  }

  resource virtualMachine2networkWatcherAgent 'extensions' = {
    name: '${virtualMachine2Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

output hubVirtualNetworkId string = hubVirtualNetwork.id

output deployedNSGs array = [for (name, i) in NsgNames: {
  orgName: name
  nsgName: NsgNames[i].name
  resourceId: NsgNames[i].id
}]

output deployedPublicIPAddresses array = [for (name, i) in publicIPAddressNames: {
  orgName: name
  publicIPAddressName: hubPublicIPAddresses[i].name
  resourceId: hubPublicIPAddresses[i].id
}]

output deployedSubnets array = [for (subnet, i) in subnets: {
  orgName: subnet.name
  subnetName: hubVirtualNetwork.properties.subnets[i].name
  resourceId: hubVirtualNetwork.properties.subnets[i].id
}]
