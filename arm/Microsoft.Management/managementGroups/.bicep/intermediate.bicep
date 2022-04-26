targetScope = 'managementGroup'

@description('Optional. Array of role assignment objects to define RBAC on this resource.')
param roleAssignments array = []

@description('Required. The resource ID of the resource to apply the role assignment to')
param resourceId string

module managementGroup_rbac 'nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name)}-ManagementGroup-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: resourceId
  }
  scope: az.managementGroup(last(split(resourceId, '/')))
}]
