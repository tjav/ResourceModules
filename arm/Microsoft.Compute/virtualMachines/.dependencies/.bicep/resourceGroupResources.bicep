// ========== //
// Parameters //
// ========== //

@description('Required. The identifier to inject into each resource name. Should only contain lowercase letters.')
param serviceShort string

@description('Optional. The location to deploy to')
param location string = resourceGroup().location

// =========== //
// Deployments //
// =========== //

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'adp-sxx-msi-${serviceShort}-01'
  location: location
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'adpsxxazsa${serviceShort}01'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  location: location
  properties: {
    allowBlobPublicAccess: false
  }

  resource blobServices 'blobServices@2021-08-01' = {
    name: 'default'

    resource container 'containers@2021-08-01' = {
      name: 'scripts'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// Required to allow the MSI to upload files to fetch the storage account context to upload files to the container
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount::blobServices::container.name, 'Owner')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
    principalId: managedIdentity.properties.principalId
  }
  scope: storageAccount::blobServices::container
}

resource storageAccountDeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'sxx-ds-sa-${serviceShort}-01'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '3.0'
    retentionInterval: 'P1D'
    arguments: ' -StorageAccountName "${storageAccount.name}" -ResourceGroupName "${resourceGroup().name}" -ContainerName "scripts" -FileName "scriptExtensionMasterInstaller.ps1"'
    cleanupPreference: 'OnSuccess'
    scriptContent: '''
      param(
        [string] $StorageAccountName,
        [string] $ResourceGroupName,
        [string] $ContainerName,
        [string] $FileName
      )
      Write-Verbose "Create file [$FileName]" -Verbose
      $file = New-Item -Value "Write-Host 'I am content'" -Path $FileName -Force

      Write-Verbose "Getting storage account [$StorageAccountName|$ResourceGroupName] context." -Verbose
      $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction 'Stop'

      Write-Verbose 'Uploading file [$fileName]' -Verbose
      Set-AzStorageBlobContent -File $file.FullName -Container $ContainerName -Context $storageAccount.Context -Force -ErrorAction 'Stop' | Out-Null
    '''
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'adp-sxx-nsg-${serviceShort}-01'
  location: location
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'adp-sxx-vnet-${serviceShort}-01'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'sxx-subnet-x-01'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-01-01' = {
  name: 'adp-sxx-rsv-${serviceShort}-01'

  resource backupConfig 'backupconfig@2022-01-01' = {
    name: 'vaultconfig'
    properties: {
      enhancedSecurityState: 'Disabled'
      softDeleteFeatureState: 'Disabled'
    }
  }

  resource backupPolicies 'backupPolicies@2022-01-01' = {
    name: 'VMpolicy'
    properties: {
      backupManagementType: 'AzureIaasVM'
      instantRPDetails: {}
      schedulePolicy: {
        schedulePolicyType: 'SimpleSchedulePolicy'
        scheduleRunFrequency: 'Daily'
        scheduleRunTimes: [
          '2019-11-07T07:00:00Z'
        ]
        scheduleWeeklyFrequency: 0
      }
      retentionPolicy: {
        retentionPolicyType: 'LongTermRetentionPolicy'
        dailySchedule: {
          retentionTimes: [
            '2019-11-07T07:00:00Z'
          ]
          retentionDuration: {
            count: 180
            durationType: 'Days'
          }
        }
      }
    }
  }
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: 'adp-sxx-kv-${serviceShort}-01'
  location: location
  properties: {
    sku: {
      name: 'premium'
      family: 'A'
    }
    tenantId: tenant().tenantId
    enablePurgeProtection: false
  }

  resource accessPolicies 'accessPolicies@2021-10-01' = {
    name: 'add'
    properties: {
      accessPolicies: [
        // Required so that the MSI can add secrets to the key vault
        {
          objectId: managedIdentity.properties.principalId
          permissions: {
            secrets: [
              'all'
            ]
          }
          tenantId: tenant().tenantId
        }
      ]
    }
  }

  resource key 'keys@2021-10-01' = {
    name: 'keyEncryptionKey'
    properties: {}
  }
}

resource keyVaultdeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'sxx-ds-kv-${serviceShort}-01'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '3.0'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    arguments: ' -keyVaultName "${keyVault.name}"'
    scriptContent: '''
      param(
        [string] $keyVaultName
      )

      $usernameString = (-join ((65..90) + (97..122) | Get-Random -Count 9 -SetSeed 1 | % {[char]$_ + "$_"})).substring(0,19) # max length
      $passwordString = (New-Guid).Guid.SubString(0,19)

      $userName = ConvertTo-SecureString -String $usernameString -AsPlainText -Force
      $password = ConvertTo-SecureString -String $passwordString -AsPlainText -Force

      # VirtualMachines and VMSS
      Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'adminUsername' -SecretValue $username
      Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'adminPassword' -SecretValue $password
    '''
  }
}

// ======= //
// Outputs //
// ======= //

output virtualNetworkSubnetResourceId string = virtualNetwork.properties.subnets[0].id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output recoveryServicesVaultName string = recoveryServicesVault.name
output recoveryServicesVaultBackupPolicyName string = recoveryServicesVault::backupPolicies.name
output keyVaultResourceId string = keyVault.id
output keyVaultKeyName string = keyVault::key.name
