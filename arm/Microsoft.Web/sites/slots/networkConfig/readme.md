# Web App Sites NetworkConfig `[Microsoft.Web/sites/slots/networkConfig]`

This module deploys Web App Sites Network Configuration for Virtual Network Integration.

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Web/sites/slots/networkConfig` | 2021-03-01 |

## Parameters

| Parameter Name | Type | Default Value | Possible Values | Description |
| :-- | :-- | :-- | :-- | :-- |
| `appName` | string |  |  | Required. Name of the site parent resource. |
| `cuaId` | string |  |  | Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered. |
| `name` | string |  | `[virtualNetwork]` | Required. Name of the site network config. |
| `slotName` | string |  |  | Required. Name of the slot parent resource. |
| `subnetId` | string |  |  | Required. The Virtual Network subnet resource ID. This is the subnet that this Web App will join. This subnet must have a delegation to Microsoft.Web/serverFarms defined first. |


## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the site config. |
| `resourceGroupName` | string | The resource group the site config was deployed into. |
| `resourceId` | string | The resource ID of the site config. |

## Template references

- [Sites/Slots/Networkconfig](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Web/2021-03-01/sites/slots/networkConfig)
