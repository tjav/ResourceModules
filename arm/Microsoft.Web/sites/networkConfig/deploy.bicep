@description('Required. Name of the site network config.')
@allowed([
  'virtualNetwork'
])
param name string

@description('Required. Name of the site parent resource.')
param appName string

@description('Required. The Virtual Network subnet resource ID. This is the subnet that this Web App will join. This subnet must have a delegation to Microsoft.Web/serverFarms defined first.')
param subnetId string

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered.')
param cuaId string = ''

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource app 'Microsoft.Web/sites@2021-03-01' existing = {
  name: appName
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  name: name
  parent: app
  properties: {
    subnetResourceId: subnetId
  }
}

@description('The name of the site config.')
output name string = networkConfig.name

@description('The resource ID of the site config.')
output resourceId string = networkConfig.id

@description('The resource group the site config was deployed into.')
output resourceGroupName string = resourceGroup().name
