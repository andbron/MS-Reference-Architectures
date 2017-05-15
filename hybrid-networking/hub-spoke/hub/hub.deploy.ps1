Param(
    [Parameter(Mandatory=$true)]
    [Alias('Subscription')]
    [string]$SUBSCRIPTION_ID,
    [Parameter(Mandatory=$true)]
    [Alias('ResourceGroup')]
    [string]$RESOURCE_GROUP_NAME,
    [Parameter(Mandatory=$true)]
    [string]$LOCATION
)

$AzureSubscription = Get-AzureRmSubscription -SubscriptionId $SUBSCRIPTION_ID
Select-AzureRmSubscription -SubscriptionId $SUBSCRIPTION_ID

$BUILDINGBLOCKS_ROOT_URI = "https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"
$SCRIPT_DIR = $PSScriptRoot

"`n"
"Using $BUILDINGBLOCKS_ROOT_URI to locate templates"
"scripts = $SCRIPT_DIR"
"`n"

$VIRTUAL_NETWORK_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
$MULTI_VMS_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"
$VPN_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"

$HUB_VIRTUAL_NETWORK_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.virtualNetwork.parameters.json"
$HUB_VPN_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.gateway.parameters.json"
$HUB_JB_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.vm.parameters.json"

# Create the resource group for the hub environment, saving the output for later.
New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME -Location $LOCATION

# Create the hub virtual network
"Deploying hub virtual network..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name 'ra-hub-vnet-deployment' `
    -TemplateUri $VIRTUAL_NETWORK_TEMPLATE_URI -TemplateParameterFile $HUB_VIRTUAL_NETWORK_PARAMETERS_FILE

# Create the jumpbox vm
"Deploying jumpbox..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name 'ra-hub-jb-deployment' `
    -TemplateUri $MULTI_VMS_TEMPLATE_URI -TemplateParameterFile $HUB_JB_PARAMETERS_FILE

# Create the vpn gateway and connection to onprem
"Deploying hub gateway and connection..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name 'ra-hub-vpn-deployment' `
    -TemplateUri $VPN_TEMPLATE_URI -TemplateParameterFile $HUB_VPN_PARAMETERS_FILE