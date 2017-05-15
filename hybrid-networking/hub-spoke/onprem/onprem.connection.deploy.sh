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

ONPREM_CONNECTION_TEMPLATE_FILE="${SCRIPT_DIR}/onprem.connection.azuredeploy.json"
ONPREM_CONNECTION_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.connection.parameters.json"

# Install VPN connnection to hub
echo "Deploying VPN conection to hub..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-onprem-vpn-gw-cn-deployment" \
--template-file $ONPREM_CONNECTION_TEMPLATE_FILE --parameters @$ONPREM_CONNECTION_PARAMETERS_FILE