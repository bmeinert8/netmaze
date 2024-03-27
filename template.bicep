@description('The location of whhere the resources are being deployed')
param location string = resourceGroup().location

@description('The name of the logic app')
param logicAppName string 
param azureAdConnection string 
param keyVaultConnection string 
param outlookConnection string 

@description('The access tier of the storage account')
param accessTier string

@description('The name of the storage account')
param OnBoardStorageAccountName string

resource workflows_AutoOnBoarder_name_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName 
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Suspended'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              '$schema': 'http://json-schema.org/draft-04/schema#'
              properties: {
                department: {
                  type: 'string'
                }
                firstname: {
                  type: 'string'
                }
                jobtitle: {
                  type: 'string'
                }
                lastname: {
                  type: 'string'
                }
                phonenumber: {
                  type: 'string'
                }
              }
              required: [
                'firstname'
                'lastname'
                'department'
                'jobtitle'
                'phonenumber'
              ]
              type: 'object'
            }
          }
        }
      }
      actions: {
        Add_user_to_group: {
          runAfter: {
            Create_user: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              '@@odata.id': '@body(\'Create_user\')?[\'id\']'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuread\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v1.0/groups/@{encodeURIComponent(\'8ff55fbc-a525-40b5-ac3b-f4156106a187\')}/members/$ref'
          }
        }
        Create_user: {
          runAfter: {
            Get_secret: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              accountEnabled: false
              department: '@triggerBody()[\'department\']'
              displayName: '@{concat(triggerBody()[\'firstname\'], \' \', triggerBody()[\'lastname\'])}'
              jobTitle: '@triggerBody()[\'jobtitle\']'
              mailNickname: '@triggerBody()[\'firstname\']'
              mobilePhone: '@triggerBody()[\'phonenumber\']'
              passwordProfile: {
                password: '@body(\'Get_secret\')?[\'value\']'
              }
              userPrincipalName: '@{concat(triggerBody()[\'firstname\'], \'.\', triggerBody()[\'lastname\'], \'@\', \'brianmeinert1gmail.onmicrosoft.com\')}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuread\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v1.0/users'
          }
        }
        Get_secret: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'newuserpw\')}/value'
          }
        }
        'Send_an_email_(V2)': {
          runAfter: {
            Add_user_to_group: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              Body: '<p>@{body(\'Create_user\')?[\'displayName\']} has been created. Please review the accont, grant any other premissions needed, and enable the account.&nbsp;</p>'
              Importance: 'Normal'
              Subject: 'New User:'
              To: 'brian.meinert1@gmail.com'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'outlook\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/Mail'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuread: {
            connectionId: azureAdConnection
            connectionName: 'azuread'
            id: '/subscriptions/db727eda-5f15-499f-b5ee-1f1d46d99f23/providers/Microsoft.Web/locations/eastus2/managedApis/azuread'
          }
          keyvault: {
            connectionId: keyVaultConnection
            connectionName: 'keyvault-2'
            id: '/subscriptions/db727eda-5f15-499f-b5ee-1f1d46d99f23/providers/Microsoft.Web/locations/eastus2/managedApis/keyvault'
          }
          outlook: {
            connectionId: outlookConnection
            connectionName: 'outlook'
            id: '/subscriptions/db727eda-5f15-499f-b5ee-1f1d46d99f23/providers/Microsoft.Web/locations/eastus2/managedApis/outlook'
          }
        }
      }
    }
  }

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: OnBoardStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: accessTier
  }
}
