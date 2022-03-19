targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Required. The name of the resource group to deploy for a testing purposes')
@maxLength(90)
param resourceGroupName string

@description('Optional. The location to deploy to')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. E.g. "vmpar". Should be kept short to not run into resource-name length-constraints')
param serviceShort string = 'vmpar'

// =========== //
// Deployments //
// =========== //

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module diagnosticDependencies './.bicep/diagnostic.dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-diagDep'
  params: {
    serviceShort: serviceShort
    location: location
  }
}

module resourceGroupResources '.bicep/resourceGroupResources.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-rgresources'
  params: {
    location: location
    serviceShort: serviceShort
  }
}

resource dependencyKeyVaultKey 'Microsoft.KeyVault/vaults/keys@2021-11-01-preview' existing = {
  name: split(resourceGroupResources.outputs.keyVaultResourceId, '/')[-1]
  scope: resourceGroup
}

////////////////////
//   Test cases   //
////////////////////

module testLinMin '../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-testLinMin'
  params: {
    location: location
    name: '${serviceShort}-vm-linux-min-01'
    adminUsername: 'localAdminUser'
    imageReference: {
      publisher: 'Canonical'
      offer: 'UbuntuServer'
      sku: '18.04-LTS'
      version: 'latest'
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetId: resourceGroupResources.outputs.virtualNetworkSubnetResourceId
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
          }
        ]
      }
    ]
    osDisk: {
      createOption: 'fromImage'
      deleteOption: 'Delete'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    disablePasswordAuthentication: true
    publicKeys: [
      {
        path: '/home/localAdminUser/.ssh/authorized_keys'
        keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdOir5eO28EBwxU0Dyra7g9h0HUXDyMNFp2z8PhaTUQgHjrimkMxjYRwEOG/lxnYL7+TqZk+HcPTfbZOunHBw0Wx2CITzILt6531vmIYZGfq5YyYXbxZa5MON7L/PVivoRlPj5Z/t4RhqMhyfR7EPcZ516LJ8lXPTo8dE/bkOCS+kFBEYHvPEEKAyLs19sRcK37SeHjpX04zdg62nqtuRr00Tp7oeiTXA1xn5K5mxeAswotmd8CU0lWUcJuPBWQedo649b+L2cm52kTncOBI6YChAeyEc1PDF0Tn9FmpdOWKtI9efh+S3f8qkcVEtSTXoTeroBd31nzjAunMrZeM8Ut6dre+XeQQIjT7I8oEm+ZkIuIyq0x2fls8JXP2YJDWDqu8v1+yLGTQ3Z9XVt2lMti/7bIgYxS0JvwOr5n5L4IzKvhb4fm13LLDGFa3o7Nsfe3fPb882APE0bLFCmfyIeiPh7go70WqZHakpgIr6LCWTyePez9CsI/rfWDb6eAM8= generated-by-azure'
      }
    ]
  }
}

module testLinPar '../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-testLinPar'
  params: {
    location: location
    name: '${serviceShort}-vm-linux-par-01'
    systemAssignedIdentity: true
    userAssignedIdentities: {
      '${resourceGroupResources.outputs.managedIdentityPrincipalId}': {}
    }
    osType: 'Linux'
    encryptionAtHost: false
    availabilityZone: 1
    imageReference: {
      publisher: 'Canonical'
      offer: 'UbuntuServer'
      sku: '18.04-LTS'
      version: 'latest'
    }
    osDisk: {
      createOption: 'fromImage'
      deleteOption: 'Delete'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    adminUsername: 'localAdminUser'
    disablePasswordAuthentication: true
    publicKeys: [
      {
        path: '/home/localAdminUser/.ssh/authorized_keys'
        keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdOir5eO28EBwxU0Dyra7g9h0HUXDyMNFp2z8PhaTUQgHjrimkMxjYRwEOG/lxnYL7+TqZk+HcPTfbZOunHBw0Wx2CITzILt6531vmIYZGfq5YyYXbxZa5MON7L/PVivoRlPj5Z/t4RhqMhyfR7EPcZ516LJ8lXPTo8dE/bkOCS+kFBEYHvPEEKAyLs19sRcK37SeHjpX04zdg62nqtuRr00Tp7oeiTXA1xn5K5mxeAswotmd8CU0lWUcJuPBWQedo649b+L2cm52kTncOBI6YChAeyEc1PDF0Tn9FmpdOWKtI9efh+S3f8qkcVEtSTXoTeroBd31nzjAunMrZeM8Ut6dre+XeQQIjT7I8oEm+ZkIuIyq0x2fls8JXP2YJDWDqu8v1+yLGTQ3Z9XVt2lMti/7bIgYxS0JvwOr5n5L4IzKvhb4fm13LLDGFa3o7Nsfe3fPb882APE0bLFCmfyIeiPh7go70WqZHakpgIr6LCWTyePez9CsI/rfWDb6eAM8= generated-by-azure'
      }
    ]

    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        deleteOption: 'Delete'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetId: resourceGroupResources.outputs.virtualNetworkSubnetResourceId
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
              roleAssignments: [
                {
                  roleDefinitionIdOrName: 'Reader'
                  principalIds: [
                    resourceGroupResources.outputs.managedIdentityPrincipalId
                  ]
                }
              ]
            }
            roleAssignments: [
              {
                roleDefinitionIdOrName: 'Reader'
                principalIds: [
                  resourceGroupResources.outputs.managedIdentityPrincipalId
                ]
              }
            ]
          }
        ]
      }
    ]
    backupVaultName: resourceGroupResources.outputs.recoveryServicesVaultName
    backupVaultResourceGroup: resourceGroup.name
    backupPolicyName: resourceGroupResources.outputs.recoveryServicesVaultBackupPolicyName
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          resourceGroupResources.outputs.managedIdentityPrincipalId
        ]
      }
    ]
    diagnosticLogsRetentionInDays: 7
    diagnosticStorageAccountId: diagnosticDependencies.outputs.storageAccountResourceId
    diagnosticWorkspaceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
    diagnosticEventHubAuthorizationRuleId: diagnosticDependencies.outputs.eventHubNamespaceEventHubAuthorizationRuleResourceId
    diagnosticEventHubName: diagnosticDependencies.outputs.eventHubNamespaceEventHubName
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
    extensionDependencyAgentConfig: {
      enabled: true
    }
    extensionNetworkWatcherAgentConfig: {
      enabled: true
    }
    extensionDiskEncryptionConfig: {
      enabled: true
      settings: {
        EncryptionOperation: 'EnableEncryption'
        KeyVaultURL: 'https://${split(resourceGroupResources.outputs.keyVaultResourceId, '/')[-1]}.${environment().suffixes.keyvaultDns}/'
        KeyVaultResourceId: resourceGroupResources.outputs.keyVaultResourceId
        KeyEncryptionKeyURL: dependencyKeyVaultKey.properties.keyUriWithVersion
        KekVaultResourceId: resourceGroupResources.outputs.keyVaultResourceId
        KeyEncryptionAlgorithm: 'RSA-OAEP'
        VolumeType: 'All'
        ResizeOSDisk: 'false'
      }
    }
    extensionDSCConfig: {
      enabled: true
    }
    configurationProfileAssignments: [
      '/providers/Microsoft.Automanage/bestPractices/AzureBestPracticesProduction'
    ]
    extensionCustomScriptConfig: {
      enabled: true
      fileData: [
        {
          uri: 'https://${split(diagnosticDependencies.outputs.storageAccountResourceId, '/')[-1]}.${environment().suffixes.storage}/scripts/scriptExtensionMasterInstaller.ps1'
          storageAccountId: diagnosticDependencies.outputs.storageAccountResourceId
        }
      ]
      protectedSettings: {
        commandToExecute: 'sudo apt-get update'
      }
    }
  }
}
