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
  name: 'dep-${serviceShort}-az-msi-x-01'
  location: location
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'dep-${serviceShort}-az-nsg-x-01'
  location: location
}

resource routeTable 'Microsoft.Network/routeTables@2021-05-01' = {
  name: 'dep-${serviceShort}-az-rt-x-01'
  location: location
}

resource peeringVNET 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'dep-${serviceShort}-az-vnet-x-01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${serviceShort}-az-subnet-x-001'
        properties: {
          addressPrefix: '10.2.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// ======= //
// Outputs //
// ======= //

output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output networkSecurityGroupResourceId string = networkSecurityGroup.id
output routeTableResourceId string = routeTable.id
output peeringVirtualNetworkResourceId string = peeringVNET.id
