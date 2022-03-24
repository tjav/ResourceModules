targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

// Shared
@description('Optional. The location to deploy resources to')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints')
param serviceShort string = 'vnet'

// ========== //
// Test Setup //
// ========== //

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${serviceShort}-microsoft-network-virtualnetwork-rg'
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

module diagnosticDependencies './.bicep/diagnostic.dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-diagDep'
  params: {
    serviceShort: serviceShort
    location: location
  }
}

// ============== //
// Test Execution //
// ============== //

// TEST 1 - MIN
module minvnet '../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-minvnet'
  params: {
    name: '${serviceShort}-az-vnet-min-01'
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
  }
}

// TEST 2 - GENERAL
module genvnet '../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-genvnet'
  params: {
    name: '${serviceShort}-az-vnet-gen-01'
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.255.0/24'
      }
      {
        name: '${serviceShort}-az-subnet-x-001'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupId: resourceGroupResources.outputs.networkSecurityGroupResourceId
        serviceEndpoints: [
          {
            service: 'Microsoft.Storage'
          }
          {
            service: 'Microsoft.Sql'
          }
        ]
        routeTableId: resourceGroupResources.outputs.routeTableResourceId
      }
      {
        name: '${serviceShort}-az-subnet-x-002'
        addressPrefix: '10.0.3.0/24'
        delegations: [
          {
            name: 'netappDel'
            properties: {
              serviceName: 'Microsoft.Netapp/volumes'
            }
          }
        ]
      }
      {
        name: '${serviceShort}-az-subnet-x-003'
        addressPrefix: '10.0.6.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          resourceGroupResources.outputs.managedIdentityPrincipalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
    diagnosticLogsRetentionInDays: 7
    diagnosticStorageAccountId: diagnosticDependencies.outputs.storageAccountResourceId
    diagnosticWorkspaceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
    diagnosticEventHubAuthorizationRuleId: diagnosticDependencies.outputs.eventHubNamespaceEventHubAuthorizationRuleResourceId
    diagnosticEventHubName: diagnosticDependencies.outputs.eventHubNamespaceEventHubName
  }
}

// TEST 3 - PEERING
module peervnet '../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-peervnet'
  params: {
    name: '${serviceShort}-az-vnet-peer-01'
    location: location
    addressPrefixes: [
      '10.0.0.0/24'
    ]

    subnets: [
      {
        'name': 'GatewaySubnet'
        'addressPrefix': '10.0.0.0/26'
      }
    ]

    virtualNetworkPeerings: [
      {
        remoteVirtualNetworkId: resourceGroupResources.outputs.peeringVirtualNetworkResourceId
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
        remotePeeringEnable: true
        remotePeeringName: 'customName'
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
      }
    ]
  }
}
