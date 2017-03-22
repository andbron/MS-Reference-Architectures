#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$true)]
  $Location,
  [Parameter(Mandatory=$true)]
  [ValidateSet("All", "Onpremise", "Infrastructure", "CreateVpn", "AzureADDS", "Workload")]
  $Mode
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

$onPremiseVirtualNetworkGatewayTemplateFile = [System.IO.Path]::Combine($PSScriptRoot, "templates\onpremise\virtualNetworkGateway.json")
$onPremiseConnectionTemplateFile = [System.IO.Path]::Combine($PSScriptRoot, "templates\onpremise\connection.json")

$loadBalancerTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json")
$dmzTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/dmz/azuredeploy.json")
$virtualNetworkGatewayTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$virtualMachineExtensionsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json")

# Azure Onpremise Parameter Files
$onpremiseVirtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetwork.parameters.json")
$onpremiseVirtualNetworkDnsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetwork-adds-dns.parameters.json")
$onpremiseADDSVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualMachines-adds.parameters.json")
$onpremiseCreateAddsForestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\create-adds-forest-extension.parameters.json")
$onpremiseAddAddsDomainControllerExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\add-adds-domain-controller.parameters.json")
$onpremiseReplicationSiteForestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\create-azure-replication-site.parameters.json")
$onpremiseVirtualNetworkGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetworkGateway.parameters.json")
$onpremiseConnectionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\connection.parameters.json")

# Azure ADDS Parameter Files
$azureVirtualNetworkOnpremiseAndAzureDnsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualNetwork-with-onpremise-and-azure-dns.parameters.json")
$azureAddsVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualMachines-adds.parameters.json")
$azureAddAddsDomainControllerExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\add-adds-domain-controller.parameters.json")

$azureVirtualNetworkGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualNetworkGateway.parameters.json")
$azureVirtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualNetwork.parameters.json")
$webLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-web.parameters.json")
$bizLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-biz.parameters.json")
$dataLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-data.parameters.json")
$managementParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualMachines-mgmt.parameters.json")
$privateDmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\dmz-private.parameters.json")
$publicDmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\dmz-public.parameters.json")


# Azure Onpremise Deployments
$onpremiseNetworkResourceGroupName = "ra-adds-onpremise-rg"

# Azure ADDS Deployments
$azureNetworkResourceGroupName = "ra-adds-network-rg"
$workloadResourceGroupName = "ra-adds-workload-rg"
$securityResourceGroupName = "ra-adds-security-rg"
$addsResourceGroupName = "ra-adds-adds-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

if ($Mode -eq "Onpremise" -Or $Mode -eq "All") {
    $onpremiseNetworkResourceGroup = New-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName -Location $Location
    Write-Host "Creating onpremise virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkParametersFile

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $onpremiseADDSVirtualMachinesParametersFile

    # Remove the Azure DNS entry since the forest will create a DNS forwarding entry.
    Write-Host "Updating virtual network DNS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-dns-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkDnsParametersFile

    Write-Host "Creating ADDS forest..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-forest-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseCreateAddsForestExtensionParametersFile

    Write-Host "Creating ADDS domain controller..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-dc-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseAddAddsDomainControllerExtensionParametersFile
}
if ($Mode -eq "Infrastructure" -Or $Mode -eq "All") {
    Write-Host "Creating ADDS resource group..."
    $azureNetworkResourceGroup = New-AzureRmResourceGroup -Name $azureNetworkResourceGroupName -Location $Location

    # Deploy network infrastructure
    Write-Host "Deploying virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-vnet-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $azureVirtualNetworkParametersFile

    # Deploy security infrastructure
    Write-Host "Creating security resource group..."
    $securityResourceGroup = New-AzureRmResourceGroup -Name $securityResourceGroupName -Location $Location

    Write-Host "Deploying jumpbox..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-jumpbox-deployment" -ResourceGroupName $securityResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementParametersFile
}
if ($Mode -eq "CreateVpn" -Or $Mode -eq "All") {
    $onpremiseNetworkResourceGroup = Get-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName
    $azureNetworkResourceGroup = Get-AzureRmResourceGroup -Name $azureNetworkResourceGroupName

    Write-Host "Deploying Onpremise Virtual Network Gateway..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-vpn-gateway-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateFile $onPremiseVirtualNetworkGatewayTemplateFile -TemplateParameterFile $onpremiseVirtualNetworkGatewayParametersFile

    Write-Host "Deploying Azure Virtual Network Gateway..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-vpn-gateway-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkGatewayTemplate.AbsoluteUri -TemplateParameterFile $azureVirtualNetworkGatewayParametersFile

    Write-Host "Creating Onpremise connection..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-connection-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateFile $onPremiseConnectionTemplateFile -TemplateParameterFile $onpremiseConnectionParametersFile
}
if ($Mode -eq "AzureADDS" -Or $Mode -eq "All") {
    # Add the replication site.
    $onpremiseNetworkResourceGroup = Get-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName
    Write-Host "Creating ADDS replication site..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-site-replication-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseReplicationSiteForestExtensionParametersFile

    # Deploy AD tier
    Write-Host "Creating ADDS resource group..."
    $addsResourceGroup = New-AzureRmResourceGroup -Name $addsResourceGroupName -Location $Location

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-adds-deployment" -ResourceGroupName $addsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $azureAddsVirtualMachinesParametersFile

    $azureNetworkResourceGroup = Get-AzureRmResourceGroup -Name $azureNetworkResourceGroupName
    # Update DNS server to point to onpremise and azure
    Write-Host "Updating virtual network DNS..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-vnet-onpremise-azure-dns-deployment" `
        -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $azureVirtualNetworkOnpremiseAndAzureDnsParametersFile

    # Join the domain and create DCs
    Write-Host "Creating ADDS domain controllers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-adds-dc-deployment" `
        -ResourceGroupName $addsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $azureAddAddsDomainControllerExtensionParametersFile
}
if ($Mode -eq "Workload" -Or $Mode -eq "All") {
    # Deploy DMZs
    $azureNetworkResourceGroup = Get-AzureRmResourceGroup -Name $azureNetworkResourceGroupName

    Write-Host "Deploying private DMZ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-dmz-private-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $dmzTemplate.AbsoluteUri -TemplateParameterFile $privateDmzParametersFile

    Write-Host "Deploying public DMZ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-dmz-public-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $dmzTemplate.AbsoluteUri -TemplateParameterFile $publicDmzParametersFile

    # Deploy workload tiers
    Write-Host "Creating workload resource group..."
    $workloadResourceGroup = New-AzureRmResourceGroup -Name $workloadResourceGroupName -Location $Location

    Write-Host "Deploying web load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-web-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $webLoadBalancerParametersFile

#    Write-Host "Deploying biz load balancer..."
#    New-AzureRmResourceGroupDeployment -Name "ra-adds-biz-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
#        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $bizLoadBalancerParametersFile

#    Write-Host "Deploying data load balancer..."
#    New-AzureRmResourceGroupDeployment -Name "ra-adds-data-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
#        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $dataLoadBalancerParametersFile
}