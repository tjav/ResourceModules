targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

// Shared
@description('Optional. The location to deploy resources to')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. E.g. "aspar". Should be kept short to not run into resource-name length-constraints')
param serviceShort string = 'rg'

// ========== //
// Test Setup //
// ========== //

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${serviceShort}-microsoft-resources-resource-rg'
  location: location
}

// Resource Group resources
module resourceGroupResources '.bicep/resourceGroupResources.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-rgresources'
  params: {
    location: location
    serviceShort: serviceShort
  }
}

// ============== //
// Test Execution //
// ============== //

// TEST 1 - MIN
module rg '../main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-rg'
  params: {
    name: '${serviceShort}-az-rg-x-01'
    location: location
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          resourceGroupResources.outputs.managedIdentityPrincipalId
        ]
      }
    ]
  }
}
