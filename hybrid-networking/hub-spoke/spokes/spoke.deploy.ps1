Param(
    [Parameter(Mandatory=$true)]
    [Alias('Subscription')]
    [string]$SUBSCRIPTION_ID,
    [Parameter(Mandatory=$true)]
    [Alias('ResourceGroup')]
    [string]$RESOURCE_GROUP_NAME,
    [Parameter(Mandatory=$true)]
    [string]$LOCATION,
    [Parameter(Mandatory=$true)]
    [string]$SPOKE
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
$LB_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json"

$PEERING_TEMPLATE_FILE = "${SCRIPT_DIR}/spoke.peering.azuredeploy.json"

$SPOKE_VNET_PARAMETERS_FILE = "${SCRIPT_DIR}/spoke${SPOKE}.virtualNetwork.parameters.json"
$SPOKE_WEB_PARAMETERS_FILE = "${SCRIPT_DIR}/spoke${SPOKE}.web.parameters.json"
$SPOKE_PEERING_PARAMETERS_FILE = "${SCRIPT_DIR}/spoke${SPOKE}.peering.parameters.json"

# Create the resource group for the spoke
New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME -Location $LOCATION

# Create the VNet
"Deploying VNet for Spoke${SPOKE}..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name "ra-spoke${SPOKE}-vnet-deployment" `
    -TemplateUri $VIRTUAL_NETWORK_TEMPLATE_URI -TemplateParameterFile $SPOKE_VNET_PARAMETERS_FILE

# Create the peering connection
"Deploying VNet peering for Spoke${SPOKE}..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name "ra-spoke${SPOKE}-vnet-peering-deployment" `
    -TemplateFile $PEERING_TEMPLATE_FILE -TemplateParameterFile $SPOKE_PEERING_PARAMETERS_FILE

# Create the load balanced VMs connection
"Deploying load balanced VMs for Spoke${SPOKE}..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name "ra-spoke${SPOKE}-vnet-peering-deployment" `
    -TemplateUri $LB_TEMPLATE_URI -TemplateParameterFile $SPOKE_WEB_PARAMETERS_FILE