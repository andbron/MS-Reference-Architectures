#
# Deploy_ReferenceArchitecture.ps1
#
param(
    [Parameter(Mandatory = $true)]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    $Location,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Infrastructure", "Security", "Workload")]
    $Mode
)

$ErrorActionPreference = "Stop"

$templateRootUriString = $env:TEMPLATE_ROOT_URI
if ($templateRootUriString -eq $null)
{
   
    $templateRootUriString = "https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"
}

if (![System.Uri]::IsWellFormedUriString($templateRootUriString, [System.UriKind]::Absolute))
{
    throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}

Write-Host
Write-Host "Using $templateRootUriString to locate templates"
Write-Host

$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)

$loadBalancerTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualNetworkGatewayTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json")
$virtualMachineExtensionsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json")
$networkSecurityGroupTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/networkSecurityGroups/azuredeploy.json")

# Azure ADDS Parameter Files
$domainControllersParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adds\ad.parameters.json")
$virtualNetworkDNSParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adds\virtualNetwork-adds-dns.parameters.json")
$addAddsDomainControllerExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adds\add-adds-domain-controller.parameters.json")
$createAddsDomainControllerForestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adds\create-adds-forest-extension.parameters.json")

# SQL Always On Parameter Files
$sqlParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\sql.parameters.json")
$fswParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\fsw.parameters.json")
$sqlPrepareAOExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\sql-iaas-ao-extensions.parameters.json")
$sqlConfigureAOExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\sql-configure-ao-extension.parameters.json")

# Infrastructure And Workload Parameters Files
$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetwork.parameters.json")
$virtualNetworkGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetworkGateway.parameters.json")
$managementParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualMachines-mgmt.parameters.json")

$appVirtualMachineParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\app.parameters.json")
$webLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\web.parameters.json")
$dchVirtualMachineParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\dch.parameters.json")
$srchVirtualMachineParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\srch.parameters.json")
$createFarmApp1ExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\spt-create-farm-app1-ext.parameters.json")
$configFarmDCH1ExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\spt-config-farm-dch1-ext.parameters.json")
$configFarmWFE1SRCH1ExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\spt-config-farm-wfe1-srch1-ext.parameters.json")
$configFarmWfe2App2ExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\spt-config-farm-wfe2-app2-ext.parameters.json")
$configFarmDch2Srch2ExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\spt-config-farm-dch2-srch2-ext.parameters.json")
$addArecordExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\add-dns-arecord.parameters.json")
$networkSecurityGroupParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\networkSecurityGroups.parameters.json")



$infrastructureResourceGroupName = "ra-sp2016-network-rg"
$workloadResourceGroupName = "ra-sp2016-workload-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

if ($Mode -eq "Infrastructure")
{
    $infrastructureResourceGroup = New-AzureRmResourceGroup -Name $infrastructureResourceGroupName -Location $Location
    Write-Host "Creating virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-vnet-deployment" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $virtualNetworkParametersFile

 #   Write-Host "Creating VPN Gateway..."
 #   New-AzureRmResourceGroupDeployment -Name "ra-sp2016-vpn-deployment" `
 #       -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
 #       -TemplateParameterFile $virtualNetworkParametersFile

    Write-Host "Deploying jumpbox..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-mgmt-deployment" -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementParametersFile

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-ad-deployment" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $domainControllersParametersFile

    Write-Host "Updating virtual network DNS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-sql-update-dns" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $virtualNetworkDNSParametersFile        

    Write-Host "Creating ADDS forest..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-primary-ad-ext" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $createAddsDomainControllerForestExtensionParametersFile

    Write-Host "Creating ADDS domain controller..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-secondary-ad-ext" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $addAddsDomainControllerExtensionParametersFile
	
    Write-Host "Deploy SQL servers with load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-sql-servers" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName -TemplateUri $loadBalancerTemplate.AbsoluteUri `
        -TemplateParameterFile $sqlParametersFile

    Write-Host "Deploy FWS..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-sql-fsw" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $fswParametersFile

    Write-Host "Prepare SQL Always ON..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-sql-ao-iaas-ext" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $sqlPrepareAOExtensionParametersFile

    Write-Host "Configure SQL Always ON..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-sql-ao-iaas-ext" `
        -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $sqlConfigureAOExtensionParametersFile
}
elseif ($Mode -eq "Workload")
{
    Write-Host "Creating workload resource group..."
   $workloadResourceGroup = New-AzureRmResourceGroup -Name $workloadResourceGroupName -Location $Location

    Write-Host "Deploy Applictation servers ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-app-deployment" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineTemplate.AbsoluteUri `
        -TemplateParameterFile $appVirtualMachineParametersFile

    Write-Host "Deploy WebFrontEnd servers with load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-web-deployment" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $loadBalancerTemplate.AbsoluteUri `
        -TemplateParameterFile $webLoadBalancerParametersFile
        
    Write-Host "Deploy DistributedCache servers ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-dch-deployment" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineTemplate.AbsoluteUri `
        -TemplateParameterFile $dchVirtualMachineParametersFile
        
    Write-Host "Deploy Search servers ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-srch-deployment" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineTemplate.AbsoluteUri `
        -TemplateParameterFile $srchVirtualMachineParametersFile

    Write-Host "Creating SharePoint Farm on App1 ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-create-farm-App1-ext" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri `
        -TemplateParameterFile $createFarmApp1ExtensionParametersFile        

    Write-Host "Configuring SharePoint Farm on Dch1 ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-config-farm-Dch1-ext" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri `
        -TemplateParameterFile $configFarmDCH1ExtensionParametersFile         

    Write-Host "Configuring SharePoint Farm on Wfe1 and Srch1 ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-config-farm-Wfe1-Srch1-ext" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri `
        -TemplateParameterFile $configFarmWFE1SRCH1ExtensionParametersFile        

    Write-Host "Creating SharePoint Farm on Wfe2 and App2 ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-config-farm-Wfe2-App2-ext" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri `
        -TemplateParameterFile $configFarmWfe2App2ExtensionParametersFile        

    Write-Host "Creating SharePoint Farm on Dch2 and Srch2 ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-config-farm-Dch2-Srch2-ext" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri `
        -TemplateParameterFile $configFarmDch2Srch2ExtensionParametersFile

    Write-Host "Adding DNS Arecords for Web Applications ..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-add-dns-arecord-ext" `
        -ResourceGroupName $workloadResourceGroup.ResourceGroupName -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri `
        -TemplateParameterFile $addArecordExtensionParametersFile        
}
elseif ($Mode -eq "Security")
{
    # Deploy DMZs
    $infrastructureResourceGroup = Get-AzureRmResourceGroup -Name $infrastructureResourceGroupName 

    Write-Host "Deploying NSGs..."
    New-AzureRmResourceGroupDeployment -Name "ra-sp2016-sql-nsg-deployment" -ResourceGroupName $infrastructureResourceGroup.ResourceGroupName `
        -TemplateUri $networkSecurityGroupTemplate.AbsoluteUri -TemplateParameterFile $networkSecurityGroupParametersFile

}