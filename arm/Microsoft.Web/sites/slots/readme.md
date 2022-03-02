# Web Sites Slots `[Microsoft.Web/sites/slots]`

This module deploys Web Sites Slots.

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Web/sites/slots` | 2021-03-01 |
| `Microsoft.Web/sites/slots/config` | 2021-03-01 |

## Parameters

| Parameter Name | Type | Default Value | Possible Values | Description |
| :-- | :-- | :-- | :-- | :-- |
| `appInsightId` | string |  |  | Optional. Resource ID of the app insight to leverage for this resource. |
| `appName` | string |  |  | Required. Name of the site. |
| `appServiceEnvironmentId` | string |  |  | Optional. The resource ID of the app service environment to use for this resource. |
| `appServicePlanId` | string |  |  | Optional. The resource ID of the app service plan to use for the slot |
| `clientAffinityEnabled` | bool | `True` |  | Optional. If client affinity is enabled. |
| `cuaId` | string |  |  | Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered. |
| `functionsExtensionVersion` | string | `~3` |  | Optional. Version if the function extension. |
| `functionsWorkerRuntime` | string |  | `[dotnet, node, python, java, powershell, ]` | Optional. Runtime of the function worker. |
| `httpsOnly` | bool | `True` |  | Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests. |
| `location` | string | `[resourceGroup().location]` |  | Optional. Location for all resources. |
| `name` | string |  |  | Required. Name of the slot. |
| `siteConfig` | object | `{object}` |  | Optional. Configuration of the app. |
| `storageAccountId` | string |  |  | Optional. Required if functionapp kind. The resource ID of the storage account to manage triggers and logging function executions. |

## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the site config. |
| `resourceGroupName` | string | The resource group the site config was deployed into. |
| `resourceId` | string | The resource ID of the site config. |

## Template references

- ['sites/slots/config' Parent Documentation](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Web/sites)
- [Sites/Slots](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Web/2021-03-01/sites/slots)
