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

$ONPREM_CONNECTION_TEMPLATE_FILE = "${SCRIPT_DIR}/onprem.connection.azuredeploy.json"
$ONPREM_CONNECTION_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.connection.parameters.json"

# Install VPN connnection to hub
"Deploying VPN conection to hub..."

New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name 'ra-onprem-vpn-gw-cn-deployment' `
    -TemplateFile $ONPREM_CONNECTION_TEMPLATE_FILE -TemplateParameterFile $ONPREM_CONNECTION_PARAMETERS_FILE