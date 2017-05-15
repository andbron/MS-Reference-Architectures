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

UDR_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/userDefinedRoutes/azuredeploy.json"

SPOKE_UDR_PARAMETERS_FILE="${SCRIPT_DIR}/spoke${SPOKE}.udr.parameters.json"

# Create the UDR
echo "Deploying UDR for Spoke${SPOKE}..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-spoke${SPOKE}-udr-deployment" \
--template-uri $UDR_TEMPLATE_URI --parameters @$SPOKE_UDR_PARAMETERS_FILE