@description('Required. Name of the slot.')
param name string

@description('Required. Name of the site.')
param appName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Type of site to deploy.')
@allowed([
  'functionapp'
  'functionapp,linux'
  'app'
])
param kind string

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

@description('The Virtual Network subnet resource ID. This is the subnet that this Web App will join. This subnet must have a delegation to Microsoft.Web/serverFarms defined first.')
param subnetId string

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
@allowed([
  '~3'
  '~4'
])
param functionsExtensionVersion string = '~3'

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered.')
param cuaId string = ''

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceFileAuditLogs'
  'AppServiceAuditLogs'
  'FunctionAppLogs'
])
param logsToEnable array = kind == 'functionapp' || kind == 'functionapp,linux' ? [
  'FunctionAppLogs'
] : [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceFileAuditLogs'
  'AppServiceAuditLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

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
    reserved: app.kind == 'functionapp,linux' ? true : null
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

module slot_networkConfig 'networkConfig/deploy.bicep' = if (!empty(subnetId)) {
  name: '${deployment().name}-SlotNetworkConfig'
  params: {
    name: 'virtualNetwork'
    appName: app.name
    slotName: slot.name
    subnetId: subnetId
  }
}

resource slot_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: '${slot.name}-diagnosticSettings'
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: slot
}

@description('The name of the site slot.')
output name string = slot.name

@description('The resource ID of the site slot.')
output resourceId string = slot.id

@description('The resource group the site slot was deployed into.')
output resourceGroupName string = resourceGroup().name
