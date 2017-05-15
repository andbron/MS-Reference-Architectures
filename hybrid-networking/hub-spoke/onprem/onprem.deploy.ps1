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

$ONPREM_VPN_TEMPLATE_FILE = "${SCRIPT_DIR}/onprem.gateway.azuredeploy.json"

$ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.virtualNetwork.parameters.json"
$ONPREM_VM_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.vm.parameters.json"
$ONPREM_VPN_GW_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.gateway.parameters.json"

# Create the resource group for the simulated on-prem environment, saving the output for later.
New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME -Location $LOCATION

# Create the simulated on-prem virtual network
"Deploying on-prem simulated virtual network..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name 'ra-onprem-vnet-deployment' `
    -TemplateUri $VIRTUAL_NETWORK_TEMPLATE_URI -TemplateParameterFile $ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE

# Create the simulated on-prem Ubuntu VM
"Deploying on-prem Ubuntu VM..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name 'ra-onprem-vm-deployment' `
    -TemplateUri $MULTI_VMS_TEMPLATE_URI -TemplateParameterFile $ONPREM_VM_PARAMETERS_FILE

# Install VPN gateway
"Deploying VPN gateway..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name 'ra-onprem-vpn-gw-deployment' `
    -TemplateFile $ONPREM_VPN_TEMPLATE_FILE -TemplateParameterFile $ONPREM_VPN_GW_PARAMETERS_FILE