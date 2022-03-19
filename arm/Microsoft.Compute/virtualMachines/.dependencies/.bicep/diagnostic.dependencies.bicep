// ========== //
// Parameters //
// ========== //

@description('Required. The identifier to inject into each resource name. Should only contain lowercase letters.')
param serviceShort string

@description('Optional. The location to deploy to')
param location string = resourceGroup().location

// =========== //
// Deployments //
// =========== //

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'adpsxxazsa${serviceShort}01'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  location: location
  properties: {
    allowBlobPublicAccess: false
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: 'adp-sxx-law-${serviceShort}-01'
  location: location
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: 'adp-sxx-evhns-${serviceShort}-01'

  resource eventHub 'eventhubs@2021-11-01' = {
    name: 'adp-sxx-evh-${serviceShort}-01'

    resource authorizationRule 'authorizationRules@2021-06-01-preview' = {
      name: 'RootManageSharedAccessKey'
      properties: {
        rights: [
          'Listen'
          'Manage'
          'Send'
        ]
      }
    }
  }
}

// ======= //
// Outputs //
// ======= //

output storageAccountResourceId string = storageAccount.id
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id
output eventHubNamespaceEventHubName string = eventHubNamespace::eventHub.name
output eventHubNamespaceEventHubAuthorizationRuleResourceId string = eventHubNamespace::eventHub::authorizationRule.id
