#
# Deploy_ReferenceArchitecture.ps1
#
[cmdletbinding(DefaultParameterSetName='DEV')]
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "Central US",
  [Parameter(Mandatory=$true, ParameterSetName="DEV")]
  [Security.SecureString]$SharedKey,
  [Parameter(Mandatory=$true, ParameterSetName="PROD")]
  $KeyVaultName,
  [Parameter(Mandatory=$true, ParameterSetName="PROD")]
  $SharedKeySecretName
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

$virtualNetworkTemplateUri = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualNetworkParametersPath = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetwork.parameters.json")

$virtualNetworkGatewayTemplateUri = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$virtualNetworkGatewayParametersPath = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetworkGateway.parameters.json")

$resourceGroupName = "ra-hybrid-vpn-rg"

# Login to Azure and select the subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

$protectedSettings = @{}
switch ($PSCmdlet.ParameterSetName) {
  "DEV" { $protectedSettings.Add("sharedKey", [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SharedKey)))}
  "PROD" { $protectedSettings.Add("sharedKey", (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $SharedKeySecretName).SecretValueText)}
  default { throw "Invalid parameters specified." }
}

# Create the resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

Write-Host "Deploying virtual network..."
New-AzureRmResourceGroupDeployment -Name "ra-hybrid-vpn-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplateUri.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersPath

Write-Host "Deploying virtual network gateway..."
New-AzureRmResourceGroupDeployment -Name "ra-hybrid-vpn-gateway-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkGatewayTemplateUri.AbsoluteUri -TemplateParameterFile $virtualNetworkGatewayParametersPath -protectedSettings $protectedSettings
