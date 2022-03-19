targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

// Resource Group
@description('Required. The name of the resource group to deploy for a testing purposes')
@maxLength(90)
param resourceGroupName string

// Shared
@description('Optional. The location to deploy resources to')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. E.g. "aspar". Should be kept short to not run into resource-name length-constraints')
param serviceShort string = 'aspar'

// =========== //
// Deployments //
// =========== //

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module diagnosticDependencies './.bicep/diagnostic.dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-diagDep'
  params: {
    serviceShort: serviceShort
    location: location
  }
}

module resourceGroupResources '.bicep/resourceGroupResources.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-rgresources'
  params: {
    location: location
    serviceShort: serviceShort
  }
}

////////////////////
//   Test cases   //
////////////////////

// Test deployment MIN
module testMin '../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-testMin'
  params: {
    location: location
    name: '${serviceShort}>azasweumin001'
  }
}

// Test deployment MAX
module testMax '../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-testMax'
  params: {
    location: location
    name: '${serviceShort}azasweumax001'
    skuName: 'S0'
    skuCapacity: 1
    firewallSettings: {
      firewallRules: [
        {
          firewallRuleName: 'AllowFromAll'
          rangeStart: '0.0.0.0'
          rangeEnd: '255.255.255.255'
        }
      ]
      enablePowerBIService: true
    }
    diagnosticLogsRetentionInDays: 365
    diagnosticStorageAccountId: diagnosticDependencies.outputs.storageAccountResourceId
    diagnosticWorkspaceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
    diagnosticEventHubAuthorizationRuleId: diagnosticDependencies.outputs.eventHubNamespaceEventHubAuthorizationRuleResourceId
    diagnosticEventHubName: diagnosticDependencies.outputs.eventHubNamespaceEventHubName
    lock: 'NotSpecified'
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          resourceGroupResources.outputs.managedIdentityPrincipalId
        ]
      }
    ]
    logsToEnable: [
      'Engine'
      'Service'
    ]
    metricsToEnable: [
      'AllMetrics'
    ]
  }
}
