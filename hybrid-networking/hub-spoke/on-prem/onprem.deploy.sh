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

ONPREM_VPN_TEMPLATE_FILE="${SCRIPT_DIR}/onprem.gateway.azuredeploy.json"

ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.virtualNetwork.parameters.json"
ONPREM_VM_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.vm.parameters.json"
ONPREM_VPN_GW_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.gateway.parameters.json"

azure config mode arm

# Create the resource group for the simulated on-prem environment, saving the output for later.
ONPREM_NETWORK_RESOURCE_GROUP_OUTPUT=$(azure group create --name $RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1

# Create the simulated on-prem virtual network
echo "Deploying on-prem simulated virtual network..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-onprem-vnet-deployment" \
--template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters-file $ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

# Create the simulated on-prem Ubuntu VM
echo "Deploying on-prem Ubuntu VM..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-onprem-vm-deployment" \
--template-uri $MULTI_VMS_TEMPLATE_URI --parameters-file $ONPREM_VM_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

# Install VPN gateway
echo "Deploying VPN gateway..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-onprem-vpn-gw-deployment" \
--template-file $ONPREM_VPN_TEMPLATE_FILE --parameters-file $ONPREM_VPN_GW_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1