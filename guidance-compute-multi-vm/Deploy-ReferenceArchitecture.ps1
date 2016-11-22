#
# Deploy_ReferenceArchitecture.ps1
#
[cmdletbinding(DefaultParameterSetName='DEV-PASSWORD')]
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "Central US",
  [Parameter(Mandatory=$false)]
  [ValidateSet("Windows", "Linux")]
  $OSType = "Windows",
  [Parameter(Mandatory=$true, ParameterSetName="DEV-PASSWORD")]
  [Security.SecureString]$AdminPassword,
  [Parameter(Mandatory=$true, ParameterSetName="DEV-SSH")]
  [Security.SecureString]$SshPublicKey,
  [Parameter(Mandatory=$true, ParameterSetName="PROD")]
  $KeyVaultName,
  [Parameter(Mandatory=$false, ParameterSetName="PROD")]
  [ValidateSet("adminPassword", "sshPublicKey")]
  $KeyVaultSecretName = "adminPassword"
)

$ErrorActionPreference = "Stop"

$templateRootUriString = $env:TEMPLATE_ROOT_URI
if ($templateRootUriString -eq $null) {
  $templateRootUriString = "https://raw.githubusercontent.com/mspnp/template-building-blocks/master/"
}

if (![System.Uri]::IsWellFormedUriString($templateRootUriString, [System.UriKind]::Absolute)) {
  throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}

Write-Host
Write-Host "Using $templateRootUriString to locate templates"
Write-Host

$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$networkSecurityGroupTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/networkSecurityGroups/azuredeploy.json")

$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", $OSType.ToLower(), "virtualNetwork.parameters.json")
$virtualMachineParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", $OSType.ToLower(), "loadBalancer.parameters.json")
$networkSecurityGroupParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", $OSType.ToLower(), "networkSecurityGroups.parameters.json")

$resourceGroupName = "ra-multi-vm-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

# Build protectedSettings hash table
$protectedSettings = @{"adminPassword" = $null; "sshPublicKey" = $null}

switch ($PSCmdlet.ParameterSetName) {
  "DEV-PASSWORD" { $protectedSettings["adminPassword"] = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))}
  "DEV-SSH" { $protectedSettings["sshPublicKey"] = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SshPublicKey))}
  "PROD" { $protectedSettings[$KeyVaultSecretName] = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName).SecretValueText}
  default { throw "Invalid parameters specified." }
}

# Create the resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

Write-Host "Deploying virtual network..."
New-AzureRmResourceGroupDeployment -Name "ra-multi-vm-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersFile

Write-Host "Deploying load balancer..."
New-AzureRmResourceGroupDeployment -Name "ra-multi-vm-lb-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $virtualMachineParametersFile -protectedSettings $protectedSettings

Write-Host "Deploying network security group..."
New-AzureRmResourceGroupDeployment -Name "ra-multi-vm-nsg-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $networkSecurityGroupTemplate.AbsoluteUri -TemplateParameterFile $networkSecurityGroupParametersFile
