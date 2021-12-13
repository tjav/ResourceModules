﻿#region helper
function Set-GitHubWorkflow {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string] $repoRoot,

        [Parameter(Mandatory = $true)]
        [string] $rgPatternEnvName,

        [Parameter(Mandatory = $true)]
        [string] $rgPattern,

        [Parameter(Mandatory = $true)]
        [string] $providerNameShort
    )

    $gitHubWorkflowFilePath = (Join-Path $repoRoot '.github' 'workflows' ('{0}.{1}.yml' -f $providerNameShort, $moduleName)).ToLower()
    if (-not (Test-Path $gitHubWorkflowFilePath)) {
        throw "GitHub workflow file in path [$gitHubWorkflowFilePath] not found."
    }

    # Process content
    # ---------------
    # Env
    # ---
    $workflowContent = Get-Content $gitHubWorkflowFilePath
    # Find 'env:' section index
    $envIndex = 0

    while ($workflowContent[$envIndex] -notlike 'env:*' -and $envIndex -lt $workflowContent.count) {
        $envIndex++
    }
    if ($envIndex -ge $workflowContent.count) {
        throw "[env] section not found in workflow file [$gitHubWorkflowFilePath]"
    }

    # Find end of 'env:' section index
    $envEndIndex = $envIndex + 1
    while ($workflowContent[$envEndIndex] -notlike 'jobs:*' -and $envEndIndex -lt $workflowContent.count) {
        $envEndIndex++
    }
    if ($envEndIndex -ge $workflowContent.count) {
        throw "[jobs] section not found in workflow file [$gitHubWorkflowFilePath]"
    }

    $rgPatternExists = $false
    for ($index = $envIndex + 1; $index -le $envEndIndex; $index++) {
        if (-not [String]::IsNullOrEmpty($workflowContent[$index]) -and $workflowContent[$index].Split(':')[0].Trim() -eq $rgPatternEnvName) {
            # Not rg pattern already in file. Updating
            $workflowContent[$index] = "{0}: '{1}'" -f $workflowContent[$index].Split(':')[0], $rgPattern
            $rgPatternExists = $true
        }
    }
    if (-not $rgPatternExists) {
        # Not rg pattern not yet in file. Adding new
        $newLine = "  {0}: '{1}'" -f $rgPatternEnvName, $rgPattern
        $workflowContent = $workflowContent[0..$envIndex] + @($newLine) + $workflowContent[($envIndex + 1)..$workflowContent.Count]
    }

    # Deploy
    # ------
    $rgRefIndex = $envEndIndex
    while ($workflowContent[$rgRefIndex] -notlike '*resourceGroupName:*' -and $rgRefIndex -lt $workflowContent.count) {
        $rgRefIndex++
    }
    if ($rgRefIndex -ge $workflowContent.count) {
        throw "[resourceGroupName] deploy job parameter not found in workflow file [$gitHubWorkflowFilePath]"
    }
    $workflowContent[($rgRefIndex)] = "{0}: '{1}'" -f $workflowContent[$rgRefIndex].Split(':')[0], '${{ format(env.rgPattern, matrix.parameterFilePaths) }}'

    # Resut
    if ($PSCmdlet.ShouldProcess("Workflow file [$gitHubWorkflowFilePath]", 'Update')) {
        $null = Set-Content -Path $gitHubWorkflowFilePath -Value $workflowContent -Force
    }
}

function Set-AzureDevOpsPipeline {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string] $repoRoot,

        [Parameter(Mandatory = $true)]
        [string] $rgPatternEnvName,

        [Parameter(Mandatory = $true)]
        [string] $rgPattern,

        [Parameter(Mandatory = $true)]
        [string] $providerNameShort
    )

    # TODO: Add once DevOps pipelines are available

    throw 'Not implemented exception [Azure DevOps pipeline file uodate]'
}

function Set-DependencyTemplate {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $repoRoot,

        [Parameter(Mandatory = $true)]
        [string] $providerName,

        [Parameter(Mandatory = $true)]
        [string] $moduleName,

        [Parameter(Mandatory = $true)]
        [string] $parameterFilePath
    )

    $templatesDirectory = Join-Path $repoRoot 'utilities' 'pipelines' 'moduleDependencies' $providerName $moduleName
    $templateFilePath = Join-Path $templatesDirectory ('{0}.bicep' -f (Split-Path $parameterFilePath -LeafBase))

    # Check exected folder
    if (-not (Test-Path $templatesDirectory)) {
        $null = New-Item $templatesDirectory -ItemType 'Directory' -Force
    }

    # Check file iteself
    if (-not (Test-Path $templateFilePath)) {
        $initialContent = Get-Content -Path (Join-Path $PSScriptRoot 'dependencyFileSource' 'bootstrap.bicep') -Raw
        $null = New-Item $templateFilePath -ItemType 'File' -Value $initialContent -Force
    }

    [array]$dependencyFileContent = Get-Content -Path $templateFilePath

    # Process IDs
    # -----------
    $specifiedIds = ((Get-Content -Path $parameterFilePath | Select-String -Pattern '"(/subscriptions/.*)"').Matches.Groups.Value | ForEach-Object { $_.Replace('"', '') }) | Select-Object -Unique

    foreach ($specifiedId in $specifiedIds) {

        $templateContentInputObject = @{
            originalContent   = $dependencyFileContent
            parameterFilePath = $parameterFilePath
            moduleName        = $moduleName
            providerName      = $providerName
        }

        switch ($specifiedId) {
            { $PSItem -like '*/Microsoft.ManagedIdentity/UserAssignedIdentities/*' } {
                if (-not (Test-IsResourceContained -resourceTypeToSeachFor 'Microsoft.ManagedIdentity/UserAssignedIdentities' -contentToSearchIn $dependencyFileContent)) {
                    $newContent = Get-Content -Path (Join-Path $PSScriptRoot 'dependencyFileSource' 'managedIdentity.bicep')
                    $dependencyFileContent = Add-TemplateContent @templateContentInputObject -newContent $newContent
                }
                break
            }
            { $PSItem -like '*/Microsoft.Storage/StorageAccounts/*' } {
                if (-not (Test-IsResourceContained -resourceTypeToSeachFor 'Microsoft.Storage/StorageAccounts' -contentToSearchIn $dependencyFileContent)) {
                    $newContent = Get-Content -Path (Join-Path $PSScriptRoot 'dependencyFileSource' 'storageAccount.bicep')
                    $dependencyFileContent = Add-TemplateContent @templateContentInputObject -newContent $newContent
                }
                break
            }
            { $PSItem -like '*/Microsoft.OperationalInsights/Workspaces/*' } {
                if (-not (Test-IsResourceContained -resourceTypeToSeachFor 'Microsoft.OperationalInsights/Workspaces' -contentToSearchIn $dependencyFileContent)) {
                    $newContent = Get-Content -Path (Join-Path $PSScriptRoot 'dependencyFileSource' 'logAnalytics.bicep')
                    $dependencyFileContent = Add-TemplateContent @templateContentInputObject -newContent $newContent
                }
                break
            }
            { $PSItem -like '*/Microsoft.EventHub/namespaces/*' } {
                if (-not (Test-IsResourceContained -resourceTypeToSeachFor 'Microsoft.EventHub/namespaces' -contentToSearchIn $dependencyFileContent)) {
                    $newContent = Get-Content -Path (Join-Path $PSScriptRoot 'dependencyFileSource' 'eventHubNamespace.bicep')
                    $dependencyFileContent = Add-TemplateContent @templateContentInputObject -newContent $newContent
                }
                break
            }
            { $PSItem -like '*/Microsoft.Network/virtualNetworks/*' } {
                if (-not (Test-IsResourceContained -resourceTypeToSeachFor 'Microsoft.Network/virtualNetworks' -contentToSearchIn $dependencyFileContent)) {
                    $newContent = Get-Content -Path (Join-Path $PSScriptRoot 'dependencyFileSource' 'virtualNetwork.bicep')
                    $dependencyFileContent = Add-TemplateContent @templateContentInputObject -newContent $newContent
                }
                break
            }
        }
    }

    Set-Content $templateFilePath -Value $dependencyFileContent
}

function Add-TemplateContent {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $originalContent,

        [Parameter(Mandatory = $true)]
        [array] $newContent,

        [Parameter(Mandatory = $true)]
        [string] $parameterFilePath,

        [Parameter(Mandatory = $true)]
        [string] $moduleName,

        [Parameter(Mandatory = $true)]
        [string] $providerName
    )

    # Check if a variables section already exist
    if (-not ($originalContent | Select-String -Pattern '^var .* = {').Matches.Value) {
        # Add variables header & servicesShort
        $modulesSectionStart = $originalContent.IndexOf('// Deployments //') - 1
        $newVarContent = Get-Content -Path (Join-Path $PSScriptRoot 'dependencyFileSource' 'bootstrap_var.bicep')

        # inject proposed short
        $generatedName = Get-ServiceShort -moduleName $moduleName -parameterFilePath $parameterFilePath -providerName $providerName
        $newVarContent[1] = $newVarContent[1].Replace('<updateShort>', $generatedName)

        # set content
        $originalContent = $originalContent[0..($modulesSectionStart - 1)] + $newVarContent + @('') + $originalContent[$modulesSectionStart..($originalContent.Count)]
    }

    # Add variable(s)
    $newVariable = $newContent[0..($newContent.IndexOf('// Module //') - 1)]
    $modulesSectionStart = $originalContent.IndexOf('// Deployments //') - 1
    $originalContent = $originalContent[0..($modulesSectionStart - 1)] + $newVariable + @('') + $originalContent[$modulesSectionStart..($originalContent.Count)]

    # Add module(s)
    $newModule = $newContent[($newContent.IndexOf('// Module //') + 1)..($newContent.IndexOf('// Output //') - 1)]
    $outputsSectionStart = $originalContent.IndexOf('// Outputs //') - 1
    $originalContent = $originalContent[0..($outputsSectionStart - 1)] + $newModule + @('') + $originalContent[$outputsSectionStart..($originalContent.Count)]

    # Add output(s)
    $newOutput = $newContent[($newContent.IndexOf('// Output //') + 1)..($newContent.Count - 1)]
    $originalContent = $originalContent + $newOutput

    return $originalContent
}

function Get-ServiceShort {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $providerName,

        [Parameter(Mandatory = $true)]
        [string] $moduleName,

        [Parameter(Mandatory = $true)]
        [string] $parameterFilePath
    )

    [array]$providerParts = ($providerName.Split('.')[1] -creplace '([A-Z\W_]|\d+)(?<![a-z])', ' $&').Trim().Split(' ')
    $providerShort = ($providerParts.Count -gt 1) ? (($providerParts | ForEach-Object { $_.ToCharArray()[0] }) -join '').ToLower() : $providerParts.SubString(0, 3).ToLower()

    [array]$resourceTypeParts = ($moduleName -creplace '([A-Z\W_]|\d+)(?<![a-z])', ' $&').Trim().Split(' ')
    $resourceTypeShort = ($resourceTypeParts.Count -gt 1) ? (($resourceTypeParts | ForEach-Object { $_.ToCharArray()[0] }) -join '').ToLower() : $resourceTypeParts.SubString(0, 3).ToLower()

    [array]$paramFileParts = (Split-Path $parameterFilePath -LeafBase).Split('.')
    $prefixes = ($paramFileParts.Count -gt 1) ? ($paramFileParts[0..($paramFileParts.Count - 2)] | ForEach-Object { $_.Substring(0, 3) }) -join '' : $paramFileParts.SubString(0, 3).ToLower()

    # Build name
    return '{0}{1}{2}' -f $providerShort, $resourceTypeShort, $prefixes
}

function Test-IsResourceContained {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $resourceTypeToSeachFor,

        [Parameter(Mandatory = $true)]
        [array] $contentToSearchIn
    )

    if (($contentToSearchIn | Select-String -Pattern "^module.*$resourceTypeToSeachFor.*\.bicep.*'").Matches.Value) {
        return $true
    }
    return $false
}
#endregion

function New-DependenciesFile {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string] $templateFilePath,

        [Parameter(Mandatory = $false)]
        [switch] $includeGitHubWorkflow,

        [Parameter(Mandatory = $false)]
        [switch] $includeAzureDevOpsPipeline
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }
    process {
        $modulePath = Split-Path $templateFilePath -Parent
        $moduleName = Split-Path $modulePath -Leaf
        $providerName = Split-Path (Split-Path $modulePath -Parent) -Leaf
        $providerNameShort = $providerName.Replace('Microsoft', 'MS')
        $repoRoot = $templateFilePath.Replace('\', '/').Split('/arm/')[0]
        $rgPatternEnvName = 'rgPattern'
        $rgPattern = $('test', $providerNameShort.ToLower(), $moduleName, '{0}', 'rg') -join '-'

        # Handle Pipelines
        # ----------------
        if ($includeGitHubWorkflow) {
            $setGitHubWorkflowInputObject = @{
                repoRoot          = $repoRoot
                rgPatternEnvName  = $rgPatternEnvName
                rgPattern         = $rgPattern
                providerNameShort = $providerNameShort
            }
            if ($PSCmdlet.ShouldProcess('GitHub workflow file', 'Update')) {
                Set-GitHubWorkflow @setGitHubWorkflowInputObject
            }
        }
        if ($includeAzureDevOpsPipeline) {
            $setAzureDevOpsPipelineInputObject = @{
                repoRoot          = $repoRoot
                rgPatternEnvName  = $rgPatternEnvName
                rgPattern         = $rgPattern
                providerNameShort = $providerNameShort
            }
            if ($PSCmdlet.ShouldProcess('Azure DevOps pipeline file', 'Update')) {
                Set-AzureDevOpsPipeline @setAzureDevOpsPipelineInputObject
            }
        }

        # Handle dependency file
        # ----------------------
        $parameterFiles = Get-ChildItem (Join-Path $modulePath '.parameters') -Filter '*.json'
        foreach ($parameterFilePath in $parameterFiles.FullName) {
            $dependencyTemplateInputObject = @{
                repoRoot          = $repoRoot
                providerName      = $providerName
                moduleName        = $moduleName
                parameterFilePath = $parameterFilePath
            }
            if ($PSCmdlet.ShouldProcess(('Dependency template for parameter file [{0}]' -f (Split-Path $parameterFilePath -Leaf)), 'Set')) {
                Set-DependencyTemplate @dependencyTemplateInputObject
            }
        }

    }
    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
# New-DependenciesFile -templateFilePath 'C:\dev\ip\Azure-ResourceModules\ResourceModules\arm\Microsoft.Compute\galleries\deploy.bicep' -includeGitHubWorkflow
# New-DependenciesFile -templateFilePath 'C:\dev\ip\Azure-ResourceModules\ResourceModules\arm\Microsoft.AnalysisServices\servers\deploy.bicep' -includeGitHubWorkflow
# New-DependenciesFile -templateFilePath 'C:\dev\ip\Azure-ResourceModules\ResourceModules\arm\Microsoft.Compute\virtualMachines\deploy.bicep' -includeGitHubWorkflow
New-DependenciesFile -templateFilePath 'C:\dev\ip\Azure-ResourceModules\ResourceModules\arm\Microsoft.Sql\servers\deploy.bicep' -includeGitHubWorkflow