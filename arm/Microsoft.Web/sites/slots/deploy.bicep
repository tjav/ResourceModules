@description('Required. Name of the slot.')
param name string

@description('Required. Name of the site.')
param appName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests.')
param httpsOnly bool = true

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Optional. Configuration of the app.')
param siteConfig object = {}

@description('Optional. Required if functionapp kind. The resource ID of the storage account to manage triggers and logging function executions.')
param storageAccountId string = ''

@description('Optional. Resource ID of the app insight to leverage for this resource.')
param appInsightId string = ''

@description('Optional. The resource ID of the app service plan to use for the slot')
param appServicePlanId string = ''

@description('Optional. The resource ID of the app service environment to use for this resource.')
param appServiceEnvironmentId string = ''

@description('Optional. Runtime of the function worker.')
@allowed([
  'dotnet'
  'node'
  'python'
  'java'
  'powershell'
  ''
])
param functionsWorkerRuntime string = ''

@description('Optional. Version if the function extension.')
param functionsExtensionVersion string = '~3'

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered.')
param cuaId string = ''

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource appInsight 'microsoft.insights/components@2020-02-02' existing = if (!empty(appInsightId)) {
  name: last(split(appInsightId, '/'))
  scope: resourceGroup(split(appInsightId, '/')[2], split(appInsightId, '/')[4])
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = if (!empty(storageAccountId)) {
  name: last(split(storageAccountId, '/'))
  scope: resourceGroup(split(storageAccountId, '/')[2], split(storageAccountId, '/')[4])
}

resource app 'Microsoft.Web/sites@2021-03-01' existing = {
  name: appName
}

resource slot 'Microsoft.Web/sites/slots@2021-03-01' = {
  name: name
  location: location
  parent: app
  properties: {
    serverFarmId: !empty(appServicePlanId) ? appServicePlanId : null
    httpsOnly: httpsOnly
    hostingEnvironmentProfile: !empty(appServiceEnvironmentId) ? {
      id: appServiceEnvironmentId
    } : null
    clientAffinityEnabled: clientAffinityEnabled
    siteConfig: siteConfig
  }
}

module slot_config 'config/deploy.bicep' = {
  name: '${deployment().name}-SlotConfig'
  params: {
    name: 'appsettings'
    appName: app.name
    slotName: slot.name
    storageAccountId: !empty(storageAccountId) ? storageAccountId : ''
    appInsightId: !empty(appInsightId) ? appInsightId : ''
    functionsWorkerRuntime: !empty(functionsWorkerRuntime) ? functionsWorkerRuntime : ''
    functionsExtensionVersion: !empty(functionsExtensionVersion) ? functionsExtensionVersion : '~3'
  }
}

@description('The name of the site config.')
output name string = slot.name

@description('The resource ID of the site config.')
output resourceId string = slot.id

@description('The resource group the site config was deployed into.')
output resourceGroupName string = resourceGroup().name
