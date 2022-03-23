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

resource proximityPlacementGroup 'Microsoft.Compute/proximityPlacementGroups@2021-11-01' = {
  name: '${serviceShort}-az-ppg-x-01'
  location: location
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${serviceShort}-az-msi-x-01'
  location: location
}

// ======= //
// Outputs //
// ======= //

output proximityPlacementGroupResourceId string = proximityPlacementGroup.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
