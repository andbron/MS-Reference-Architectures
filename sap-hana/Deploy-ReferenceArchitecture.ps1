#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "Central US"
)

$ErrorActionPreference = "Stop"

$templateRootUriString = $env:TEMPLATE_ROOT_URI
if ($templateRootUriString -eq $null) {
  $templateRootUriString = "https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"
}

if (![System.Uri]::IsWellFormedUriString($templateRootUriString, [System.UriKind]::Absolute)) {
  throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}

Write-Host
Write-Host "Using $templateRootUriString to locate templates"
Write-Host

# Deployer templates for respective resources
$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)

$virtualNetworkTemplateUri = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualNetworkGatewayTemplateUri = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json')
$loadBalancedVmSetTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json')

# Template parameters for respective deployments
$virtualNetworkParametersPath = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', 'virtualNetwork.parameters.json')
$virtualNetworkGatewayParametersPath = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', 'virtualNetworkGateway.parameters.json')
$managementTierJumpboxParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', 'managementTierJumpbox.parameters.json')
$businessTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', 'sapAppsTier.parameters.json')
$sapAppsTierScsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', 'sapAppsTier.scs.parameters.json')
$sapDataTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', 'sapDataTier.parameters.json')

$resourceGroupName = "ra-sap-hana-rg"

# Login to Azure and select the subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

# Create the resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

Write-Host "Deploying virtual network..."
New-AzureRmResourceGroupDeployment -Name "ra-sap-hana-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplateUri.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersPath

# Write-Host "Deploying virtual network gateway..."
# New-AzureRmResourceGroupDeployment -Name "ra-sap-hana-gateway-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
#     -TemplateUri $virtualNetworkGatewayTemplateUri.AbsoluteUri -TemplateParameterFile $virtualNetworkGatewayParametersPath

Write-Host "Deploying jumpbox in management tier..."
New-AzureRmResourceGroupDeployment -Name "ra-sap-hana-mgmt-jb-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementTierJumpboxParametersFile

Write-Host "Deploying SAP Apps tier..."
New-AzureRmResourceGroupDeployment -Name "ra-sap-hana-apps-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $businessTierParametersFile

Write-Host "Deploying SAP Apps (SCS) tier..."
New-AzureRmResourceGroupDeployment -Name "ra-sap-hana-apps-scs-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $sapAppsTierScsParametersFile

Write-Host "Deploying SAP Hana DB tier..."
New-AzureRmResourceGroupDeployment -Name "ra-sap-hana-db-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $sapDataTierParametersFile