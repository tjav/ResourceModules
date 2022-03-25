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

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'adp-${serviceShort}-az-msi-x-01'
  location: location
}

// ======= //
// Outputs //
// ======= //

output managedIdentityPrincipalId string = managedIdentity.properties.principalId
