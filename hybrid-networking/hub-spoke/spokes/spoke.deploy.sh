#!/bin/bash
while [ $# -gt 0 ]
do
  key="$1"
  case $key in
    -l|--location)
      LOCATION="$2"
      shift
      ;;
    -r|--resourcegroup)
      RESOURCE_GROUP_NAME="$2"
      ;;
    -s|--subscription)
      SUBSCRIPTION_ID="$2"
      shift
      ;;
    -k|--spoke)
      SPOKE="$2"
      shift
      ;;
    *)
      ;;
  esac
  shift
done

BUILDINGBLOCKS_ROOT_URI="https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

echo
echo "Using ${BUILDINGBLOCKS_ROOT_URI} to locate templates"
echo "scripts=${SCRIPT_DIR}"
echo

VIRTUAL_NETWORK_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
LB_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json"

PEERING_TEMPLATE_FILE="${SCRIPT_DIR}/spoke.peering.azuredeploy.json"

SPOKE_VNET_PARAMETERS_FILE="${SCRIPT_DIR}/spoke${SPOKE}.virtualNetwork.parameters.json"
SPOKE_WEB_PARAMETERS_FILE="${SCRIPT_DIR}/spoke${SPOKE}.web.parameters.json"
SPOKE_PEERING_PARAMETERS_FILE="${SCRIPT_DIR}/spoke${SPOKE}.peering.parameters.json"

# Create the VNet
echo "Deploying VNet for Spoke${SPOKE}..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-spoke${SPOKE}-vnet-deployment" \
--template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters @$SPOKE_VNET_PARAMETERS_FILE

# Create the peering connection
echo "Deploying VNet peering for Spoke${SPOKE}..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-spoke${SPOKE}-vnet-peering-deployment" \
--template-file $PEERING_TEMPLATE_FILE --parameters @$SPOKE_PEERING_PARAMETERS_FILE

# Create the load balanced VMs connection
echo "Deploying load balanced VMs for Spoke${SPOKE}..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-spoke${SPOKE}-vnet-peering-deployment" \
--template-uri $LB_TEMPLATE_URI --parameters @$SPOKE_WEB_PARAMETERS_FILE