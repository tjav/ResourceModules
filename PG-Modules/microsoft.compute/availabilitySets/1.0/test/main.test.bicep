targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

// Shared
@description('Optional. The location to deploy resources to')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints')
param serviceShort string = 'avs'

// ========== //
// Test Setup //
// ========== //

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${serviceShort}-microsoft-compute-availabilityset-rg'
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
module minavs '../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-minavs'
  params: {
    name: '${serviceShort}-az-avs-min-01'
    location: location
  }
}

// TEST 2 - GENERAL
module genavs '../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-genavs'
  params: {
    name: '${serviceShort}-az-avs-gen-01'
    proximityPlacementGroupId: resourceGroupResources.outputs.proximityPlacementGroupResourceId
    availabilitySetSku: 'aligned'
    availabilitySetUpdateDomain: 2
    availabilitySetFaultDomain: 2
    tags: {
      tag1: 'tag1Value'
      tag2: 'tag2Value'
    }
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          resourceGroupResources.outputs.managedIdentityPrincipalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
    location: location
  }
}
