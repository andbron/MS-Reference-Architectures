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

$UDR_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/userDefinedRoutes/azuredeploy.json"

$SPOKE_UDR_PARAMETERS_FILE = "${SCRIPT_DIR}/spoke${SPOKE}.udr.parameters.json"

# Create the UDR
"Deploying UDR for Spoke${SPOKE}..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME -Name "ra-spoke${SPOKE}-udr-deployment" `
    -TemplateUri $UDR_TEMPLATE_URI -TemplateParameterFile $SPOKE_UDR_PARAMETERS_FILE