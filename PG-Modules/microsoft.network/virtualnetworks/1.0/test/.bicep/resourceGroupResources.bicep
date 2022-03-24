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
  name: '${serviceShort}-az-msi-x-01'
  location: location
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${serviceShort}-az-nsg-x-01'
}

resource routeTable 'Microsoft.Network/routeTables@2021-05-01' = {
  name: '${serviceShort}-az-rt-x-01'
}

// ======= //
// Outputs //
// ======= //

output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output networkSecurityGroupResourceId string = networkSecurityGroup.id
output routeTableResourceId string = routeTable.id
