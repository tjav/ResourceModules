# Web Sites Slots `[Microsoft.Web/sites/slots]`

This module deploys Web Sites Slots.

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Insights/diagnosticSettings` | 2021-05-01-preview |
| `Microsoft.Web/sites/slots` | 2021-03-01 |
| `Microsoft.Web/sites/slots/config` | 2021-03-01 |
| `Microsoft.Web/sites/slots/networkConfig` | 2021-03-01 |

## Parameters

| Parameter Name | Type | Default Value | Possible Values | Description |
| :-- | :-- | :-- | :-- | :-- |
| `appInsightId` | string |  |  | Optional. Resource ID of the app insight to leverage for this resource. |
| `appName` | string |  |  | Required. Name of the site. |
| `appServiceEnvironmentId` | string |  |  | Optional. The resource ID of the app service environment to use for this resource. |
| `appServicePlanId` | string |  |  | Optional. The resource ID of the app service plan to use for the slot |
| `clientAffinityEnabled` | bool | `True` |  | Optional. If client affinity is enabled. |
| `cuaId` | string |  |  | Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered. |
| `diagnosticEventHubAuthorizationRuleId` | string |  |  | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to. |
| `diagnosticEventHubName` | string |  |  | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. |
| `diagnosticLogsRetentionInDays` | int | `365` |  | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely. |
| `diagnosticStorageAccountId` | string |  |  | Optional. Resource ID of the diagnostic storage account. |
| `diagnosticWorkspaceId` | string |  |  | Optional. Resource ID of log analytics workspace. |
| `functionsExtensionVersion` | string | `~3` | `[~3, ~4]` | Optional. Version if the function extension. |
| `functionsWorkerRuntime` | string |  | `[dotnet, node, python, java, powershell, ]` | Optional. Runtime of the function worker. |
| `httpsOnly` | bool | `True` |  | Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests. |
| `kind` | string |  | `[functionapp, functionapp,linux, app]` | Required. Type of site to deploy. |
| `location` | string | `[resourceGroup().location]` |  | Optional. Location for all resources. |
| `logsToEnable` | array | `[if(or(equals(parameters('kind'), 'functionapp'), equals(parameters('kind'), 'functionapp,linux')), createArray('FunctionAppLogs'), createArray('AppServiceHTTPLogs', 'AppServiceConsoleLogs', 'AppServiceAppLogs', 'AppServiceFileAuditLogs', 'AppServiceAuditLogs'))]` | `[AppServiceHTTPLogs, AppServiceConsoleLogs, AppServiceAppLogs, AppServiceFileAuditLogs, AppServiceAuditLogs, FunctionAppLogs]` | Optional. The name of logs that will be streamed. |
| `metricsToEnable` | array | `[AllMetrics]` | `[AllMetrics]` | Optional. The name of metrics that will be streamed. |
| `name` | string |  |  | Required. Name of the slot. |
| `siteConfig` | object | `{object}` |  | Optional. Configuration of the app. |
| `storageAccountId` | string |  |  | Optional. Required if functionapp kind. The resource ID of the storage account to manage triggers and logging function executions. |
| `subnetId` | string |  |  | Optional. The Virtual Network subnet resource ID. This is the subnet that this Web App will join. This subnet must have a delegation to Microsoft.Web/serverFarms defined first. |

## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the site slot. |
| `resourceGroupName` | string | The resource group the site slot was deployed into. |
| `resourceId` | string | The resource ID of the site slot. |

## Template references

- ['sites/slots/config' Parent Documentation](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Web/sites)
- [Diagnosticsettings](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Insights/2021-05-01-preview/diagnosticSettings)
- [Sites/Slots](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Web/2021-03-01/sites/slots)
- [Sites/Slots/Networkconfig](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Web/2021-03-01/sites/slots/networkConfig)
