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

PEERING_TEMPLATE_FILE="${SCRIPT_DIR}/hub.peering.azuredeploy.json"

SPOKE_PEERING_PARAMETERS_FILE="${SCRIPT_DIR}/hub.spoke${SPOKE}.peering.parameters.json"

# Install VNet peering
echo "Deploying VNet peering..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-hub-spoke${SPOKE}peering-deployment" \
--template-file $PEERING_TEMPLATE_FILE --parameters @$SPOKE_PEERING_PARAMETERS_FILE