@description('The location of where the resources will be deployed.')
param location string = resourceGroup().location

@description('The name of the administrator account.')
@secure()
param adminUsername string

@description('The password of the administrator account.')
@secure()
param adminPassword string

@description ('The name of the virtual network.')
param spoke1VnetName string

@description('The name of the subnet.')
param spoke1SubnetName string

@description('The address prefix for the virtual network.')
param spoke1AddressPrefix string

@description('The address prefix for the subnet.')
param spoke1SubnetPrefix string

@description('The name of the network security group.')
param spoke1NsgName string

@description('The name of the network interface card.')
param spoke1NicName string

@description('The name of the virtual machine.')
param spoke1VmName string

@description('The size of the virtual machine.')
param vmSize string

@description('The name of the virtual machine disk.')
param spoke1VMDiskName string

var virtualMachineImageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}


resource spoke1Nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: spoke1NsgName
  location: location
  properties: {
    securityRules: [
    ]
  }
}

resource spoke1Nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: spoke1NicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: spoke1VirtualNetwork::spoke1VmappSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'myPublicIp')
          }
        }
      }
    ]
  }
}

resource spoke1VM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: spoke1VmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: spoke1VMDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: spoke1VmName
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
          id: spoke1Nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine1IIS 'extensions' = {
    name: '${spoke1VmName}-IIS'
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
    name: '${spoke1VmName}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}


resource spoke1VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: spoke1VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke1AddressPrefix
      ]
    }
    subnets: [
      {
        name: spoke1SubnetName
        properties: {
          addressPrefix: spoke1SubnetPrefix
        }
      }
    ]
  }
  resource spoke1VmappSubnet 'subnets' existing = {
    name: spoke1SubnetName
  }
}

output spoke1VmId string = spoke1VM.id
