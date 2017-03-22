#!/bin/bash

NETWORK_RESOURCE_GROUP_NAME="ra-public-dmz-network-rg"
WORKLOAD_RESOURCE_GROUP_NAME="ra-public-dmz-wl-rg"
LOCATION="centralus"

BUILDINGBLOCKS_ROOT_URI=${BUILDINGBLOCKS_ROOT_URI:="https://raw.githubusercontent.com/mspnp/template-building-blocks/master/"}
# Make sure we have a trailing slash
[[ "${BUILDINGBLOCKS_ROOT_URI}" != */ ]] && BUILDINGBLOCKS_ROOT_URI="${BUILDINGBLOCKS_ROOT_URI}/"

# For validating HTTP URIs only
URI_REGEX="^((?:https?://(?:(?:[a-zA-Z0-9$.+!*(),;?&=_-]|(?:%[a-fA-F0-9]{2})){1,64}(?::(?:[a-zA-Z0-9$.+!*(),;?&=_-]|(?:%[a-fA-F0-9]{2})){1,25})?@)?)?(?:(([a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]([a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF-]{0,61}[a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]){0,1}\.)+[a-zA-Z\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]{2,63}|((25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9]))))(?::\d{1,5})?)(/(?:(?:[a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF;/?:@&=#~.+!*(),_-])|(?:%[a-fA-F0-9]{2}))*)?(?:\b|$)$"

validate() {
    for i in "${@:2}"; do
      if [[ "$1" == "$i" ]]
      then
        return 1 
      fi
    done
    
    return 0 
}

validateNotEmpty() {
    if [[ "$1" != "" ]]
    then
      return 1
    else
      return 0
    fi
}

showErrorAndUsage() {
  echo
  if [[ "$1" != "" ]]
  then
    echo "  error:  $1"
    echo
  fi

  echo "  usage:  $(basename ${0}) [options]"
  echo "  options:"
  echo "    -l, --location <location>"
  echo "    -s, --subscription <subscription-id>"
  echo
  exit 1
}

if [[ $# < 1 ]]
then
  showErrorAndUsage
fi

while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -s|--subscription)
      # Explicitly set the subscription to avoid confusion as to which subscription
      # is active/default
      SUBSCRIPTION_ID="$2"
      shift
      ;;
    -l|--location)
      LOCATION="$2"
      shift
      ;;
    *)
      showErrorAndUsage "Unknown option: $1"
    ;;
  esac
  shift
done

if ! [[ $SUBSCRIPTION_ID =~ ^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$  ]];
then
  showErrorAndUsage "Invalid Subscription ID"
fi

if validateNotEmpty $LOCATION;
then
  showErrorAndUsage "Location must be provided"
fi

if grep -P -v $URI_REGEX <<< $BUILDINGBLOCKS_ROOT_URI > /dev/null
then
  showErrorAndUsage "Invalid value for BUILDINGBLOCKS_ROOT_URI: ${BUILDINGBLOCKS_ROOT_URI}"
fi

echo
echo "Using ${BUILDINGBLOCKS_ROOT_URI} to locate templates"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VIRTUAL_NETWORK_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
LOAD_BALANCER_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json"
MULTI_VMS_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"
DMZ_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/dmz/azuredeploy.json"
VPN_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"
NETWORK_SECURITY_GROUPS_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/networkSecurityGroups/azuredeploy.json"

VIRTUAL_NETWORK_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/virtualNetwork.parameters.json"
WEB_SUBNET_LOADBALANCER_AND_VMS_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/loadBalancer-web-subnet.parameters.json"
BIZ_SUBNET_LOADBALANCER_AND_VMS_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/loadBalancer-biz-subnet.parameters.json"
DATA_SUBNET_LOADBALANCER_AND_VMS_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/loadBalancer-data-subnet.parameters.json"
MGMT_SUBNET_VMS_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/virtualMachines-mgmt-subnet.parameters.json"
DMZ_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/dmz.parameters.json"
INTERNET_DMZ_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/internet-dmz.parameters.json"
VPN_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/vpn.parameters.json"
NETWORK_SECURITY_GROUPS_PARAMETERS_FILE="${SCRIPT_DIR}/parameters/networkSecurityGroups.parameters.json"

azure config mode arm

# Create the resource group, saving the output for later.
NETWORK_RESOURCE_GROUP_OUTPUT=$(azure group create --name $NETWORK_RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1
WORKLOAD_RESOURCE_GROUP_OUTPUT=$(azure group create --name $WORKLOAD_RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1

# Create the virtual network
echo "Deploying virtual network..."
azure group deployment create --resource-group $NETWORK_RESOURCE_GROUP_NAME --name "ra-vnet-deployment" \
--template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters-file $VIRTUAL_NETWORK_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying load balancer and virtual machines in web subnet..."
azure group deployment create --resource-group $WORKLOAD_RESOURCE_GROUP_NAME --name "ra-web-lb-vms-deployment" \
--template-uri $LOAD_BALANCER_TEMPLATE_URI --parameters-file $WEB_SUBNET_LOADBALANCER_AND_VMS_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying load balancer and virtual machines in biz subnet..."
azure group deployment create --resource-group $WORKLOAD_RESOURCE_GROUP_NAME --name "ra-biz-lb-vms-deployment" \
--template-uri $LOAD_BALANCER_TEMPLATE_URI --parameters-file $BIZ_SUBNET_LOADBALANCER_AND_VMS_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying load balancer and virtual machines in data subnet..."
azure group deployment create --resource-group $WORKLOAD_RESOURCE_GROUP_NAME --name "ra-data-lb-vms-deployment" \
--template-uri $LOAD_BALANCER_TEMPLATE_URI --parameters-file $DATA_SUBNET_LOADBALANCER_AND_VMS_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying jumpbox in mgmt subnet..."
azure group deployment create --resource-group $NETWORK_RESOURCE_GROUP_NAME --name "ra-mgmt-vms-deployment" \
--template-uri $MULTI_VMS_TEMPLATE_URI --parameters-file $MGMT_SUBNET_VMS_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying dmz..."
azure group deployment create --resource-group $NETWORK_RESOURCE_GROUP_NAME --name "ra-dmz-deployment" \
--template-uri $DMZ_TEMPLATE_URI --parameters-file $DMZ_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying internet dmz..."
azure group deployment create --resource-group $NETWORK_RESOURCE_GROUP_NAME --name "ra-internet-dmz-deployment" \
--template-uri $DMZ_TEMPLATE_URI --parameters-file $INTERNET_DMZ_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying vpn..."
azure group deployment create --resource-group $NETWORK_RESOURCE_GROUP_NAME --name "ra-vpn-deployment" \
--template-uri $VPN_TEMPLATE_URI --parameters-file $VPN_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying network security group..."
azure group deployment create --resource-group $NETWORK_RESOURCE_GROUP_NAME --name "ra-nsg-deployment" \
--template-uri $NETWORK_SECURITY_GROUPS_TEMPLATE_URI --parameters-file $NETWORK_SECURITY_GROUPS_PARAMETERS_FILE \
--subscription $SUBSCRIPTION_ID || exit 1

