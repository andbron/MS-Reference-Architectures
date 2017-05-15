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

$PEERING_TEMPLATE_FILE = "${SCRIPT_DIR}/hub.peering.azuredeploy.json"

$SPOKE_PEERING_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.spoke${SPOKE}.peering.parameters.json"

# Install VNet peering
"Deploying VNet peering..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name "ra-hub-spoke${SPOKE}peering-deployment" `
    -TemplateFile $PEERING_TEMPLATE_FILE -TemplateParameterFile $SPOKE_PEERING_PARAMETERS_FILE