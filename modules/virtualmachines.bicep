param location string = resourceGroup().location
@secure()
param adminUsername string
@secure()
param adminPassword string
param vm1Name string = 'vmapp-eus2-001'
param vm2Name string = 'vmapp-eus2-002'
param vm3Name string = 'vmapp-eus2-003'
param vm4Name string = 'vmapp-eus2-004'
param vmSize string = 'Standard_DS2_v2'

var VMImageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

module vm1subnet 'vnets.bicep' = {
  name: 'vm1subnet'
  params: {
    location: location
    id: outputs.hubVirtualNetwork::vmappSubnet1.id
  }
}

resource networkInterface1 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: 'nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet1', 'subnet1')
          }
        }
      }
    ]
  }
}

resource virtualMachine1 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vm1Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: VMImageReference
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vm1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic1')
        }
      ]
    }
  }

  resource virtualMachine1IIS 'extensions' = {
    name: '${vm1Name}-IIS'
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
    name: '${vm1Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

resource virtualMachine2 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vm2Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: VMImageReference
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vm2Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic2')
        }
      ]
    }
  }

  resource virtualMachine1IIS 'extensions' = {
    name: '${vm2Name}-IIS'
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
    name: '${vm2Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}   

resource virtualMachine3 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vm3Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: VMImageReference
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vm3Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic3')
        }
      ]
    }
  }

  resource virtualMachine1IIS 'extensions' = {
    name: '${vm3Name}-IIS'
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
    name: '${vm3Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

resource virtualMachine4 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vm4Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: VMImageReference
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vm4Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic4')
        }
      ]
    }
  }
  
  resource virtualMachine1IIS 'extensions' = {
    name: '${vm4Name}-IIS'
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
    name: '${vm4Name}-NWA'
    location: location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.NetworkWatcher'
      type: 'NetworkWatcherAgentWindows'
      typeHandlerVersion: '1.4'
    }
  }
}

output vm1ResourceId string = resourceId('Microsoft.Compute/virtualMachines', 'vm1')
output vm2ResourceId string = resourceId('Microsoft.Compute/virtualMachines', 'vm2')
output vm3ResourceId string = resourceId('Microsoft.Compute/virtualMachines', 'vm3')
output vm4ResourceId string = resourceId('Microsoft.Compute/virtualMachines', 'vm4')

