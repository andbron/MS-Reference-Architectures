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
      shift
      ;;    
    -s|--subscription)
      SUBSCRIPTION_ID="$2"
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
MULTI_VMS_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"
VPN_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"

HUB_VIRTUAL_NETWORK_PARAMETERS_FILE="${SCRIPT_DIR}/hub.virtualNetwork.parameters.json"
HUB_VPN_PARAMETERS_FILE="${SCRIPT_DIR}/hub.gateway.parameters.json"
HUB_JB_PARAMETERS_FILE="${SCRIPT_DIR}/hub.vm.parameters.json"

# Create the resource group for the hub environment, saving the output for later.
HUB_NETWORK_RESOURCE_GROUP_OUTPUT=$(az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1

# Create the hub virtual network
echo "Deploying hub virtual network..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-hub-vnet-deployment" \
--template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters-file $HUB_VIRTUAL_NETWORK_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

# Create the jumpbox vm
echo "Deploying jumpbox..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-hub-jb-deployment" \
--template-uri $MULTI_VMS_TEMPLATE_URI --parameters-file $HUB_JB_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

# Create the vpn gateway and connection to onprem
echo "Deploying hub gateway and connection..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-hub-vpn-deployment" \
--template-uri $VPN_TEMPLATE_URI --parameters-file $HUB_VPN_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1