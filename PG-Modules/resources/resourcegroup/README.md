# Resource Groups

This template deploys Microsoft.Resources Resource Groups and optionally available children or extensions

## Parameters

| Name              | Type     | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                    |
| :---------------- | :------: | :------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`            | `string` | Yes      | Required. The name of the Resource Group                                                                                                                                                                                                                                                                                                                                                                       |
| `location`        | `string` | No       | Optional. Location of the Resource Group. It uses the deployment's location when not provided.                                                                                                                                                                                                                                                                                                                 |
| `lock`            | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                                                                                                                                                            |
| `roleAssignments` | `array`  | No       | Optional. Array of role assignment objects that contain the 'roleDefinitionIdOrName' and 'principalId' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11' |
| `tags`            | `object` | No       | Optional. Tags of the storage account resource.                                                                                                                                                                                                                                                                                                                                                                |

## Outputs

| Name       | Type   | Description                           |
| :--------- | :----: | :------------------------------------ |
| name       | string | The name of the resource group        |
| resourceId | string | The resource ID of the resource group |

## Examples

### Example 1

```bicep
```

### Example 2

```bicep
```