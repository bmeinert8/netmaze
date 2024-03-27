@description('The location of where the resources will be deployed.')
param location string = resourceGroup().location

@description('The name of the administrator account.')
@secure()
param adminUsername string

@description('The password of the administrator account.')
@secure()
param adminPassword string

@description ('The name of the virtual network.')
param spoke2VnetName string

@description('The name of the subnet.')
param spoke2SubnetName string

@description('The address prefix for the virtual network.')
param spoke2AddressPrefix string

@description('The address prefix for the subnet.')
param spoke2SubnetPrefix string

@description('The name of the network security group.')
param spoke2NsgName string

@description('The name of the network interface card.')
param spoke2NicName string

@description('The name of the virtual machine.')
param spoke2VmName string

@description('The size of the virtual machine.')
param vmSize string

@description('The name of the virtual machine disk.')
param spoke2VMDiskName string

var virtualMachineImageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}


resource spoke2Nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: spoke2NsgName
  location: location
  properties: {
    securityRules: [
    ]
  }
}

resource spoke2Nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: spoke2NicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: spoke2VirtualNetwork::spoke1VmappSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource spoke2VM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: spoke2VmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Windows'
        name: spoke2VMDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: spoke2VmName
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
          id: spoke2Nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }

  resource virtualMachine1IIS 'extensions' = {
    name: '${spoke2VmName}-IIS'
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
    name: '${spoke2VmName}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}


resource spoke2VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: spoke2VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke2AddressPrefix
      ]
    }
    subnets: [
      {
        name: spoke2SubnetName
        properties: {
          addressPrefix: spoke2SubnetPrefix
        }
      }
    ]
  }
  resource spoke1VmappSubnet 'subnets' existing = {
    name: spoke2SubnetName
  }
}


output spoke2VMId string = spoke2VM.id
output spoke2VMName string = spoke2VM.name
output spoke2VMReference string = spoke2VM.properties.hardwareProfile.vmSize
