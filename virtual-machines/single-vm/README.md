# Deploying a single VM to Azure

You can read the [guidance on deploying a single VM to Azure][guidance] document to understand the best practices related to single VM deployment that accompanies the reference architecture below.

![[0]][0]

## Solution components

The reference architecture above is deployed using different building blocks for virtual network, network security group, and virtual machine.

You can deploy these template building blocks by using:
- [a template file][solution-template]
- [a PowerShell script][solution-psscript]
- [a bash script][solution-shscript]

Each building block consumes a parameter file that you can download and modify for your own environment. The parameters used in this deployment scenario are as follows.

### Virtual network

Download the [virtualNetwork.parameters.json][vnet-parameters] and make any necessary changes. You can learn about each parameter used in this file in the [vnet-n-subnet][bb-vnet] building block **readme** page. The parameter file used in this scenario creates a vnet with a single subnet, using 10.0.1.0/24 as its CIDR as follows.

	  "parameters": {
	    "virtualNetworkSettings": {
	      "value": {
	        "name": "ra-single-vm-vnet",
	        "addressPrefixes": [
	          "10.0.0.0/16"
	        ],
	        "subnets": [
	          {
	            "name": "web",
	            "addressPrefix": "10.0.1.0/24"
	          }
	        ],
	        "dnsServers": [ ]
	      }
	    }
	  }

### Network security group

Download the [networkSecurityGroup.parameters.json][nsg-parameters] and make any necessary changes. You can learn about each parameter used in this file in the [networkSecurityGroups][bb-nsg] building block **readme** page. The parameter file used in this scenario creates an NSG with a single rule, allowing SSH access, linked to the **web** subnet as follows.

	  "parameters": {
	    "virtualNetworkSettings": {
	      "value": {
	        "name": "ra-single-vm-vnet",
	        "resourceGroup": "ra-single-vm-rg"
	      }
	    },
	    "networkSecurityGroupsSettings": {
	      "value": [
	        {
	          "name": "ra-single-vm-nsg",
	          "subnets": [
	            "web"
	          ],
	          "networkInterfaces": [
	          ],
	          "securityRules": [
	            {
	              "name": "default-allow-ssh",
	              "direction": "Inbound",
	              "priority": 1000,
	              "sourceAddressPrefix": "*",
	              "destinationAddressPrefix": "*",
	              "sourcePortRange": "*",
	              "destinationPortRange": "22",
	              "access": "Allow",
	              "protocol": "Tcp"
	            }
	          ]
	        }
	      ]
	    }
	  }

### Virtual machine

Download the [virtualMachineParameters.json][vm-parameters] and make any necessary changes. You can learn about each parameter used in this file in the [multi-vm-n-nic-m-storage][bb-vm] building block **readme** page. The parameter file used in this scenario creates a single Linux VM with a NIC, a public IP address, and two data disks as follows.

	  "parameters": {
	    "virtualMachinesSettings": {
	      "value": {
	        "namePrefix": "ra-single-vm",
	        "computerNamePrefix": "cn",
	        "size": "Standard_DS1_v2",
	        "osType": "linux",
	        "adminUsername": "",
	        "adminPassword": "",
	        "osAuthenticationType": "password",
	        "nics": [
	          {
	            "isPublic": "true",
	            "subnetName": "subnet1",
	            "privateIPAllocationMethod": "dynamic",
	            "publicIPAllocationMethod": "dynamic",
	            "enableIPForwarding": false,
	            "dnsServers": [
	            ],
	            "isPrimary": "true"
	          }
	        ],
	        "imageReference": {
	          "publisher": "Canonical",
	          "offer": "UbuntuServer",
	          "sku": "14.04.5-LTS",
	          "version": "latest"
	        },
	        "dataDisks": {
	          "count": 2,
	          "properties": {
	            "diskSizeGB": 128,
	            "caching": "None",
	            "createOption": "Empty"
	          }
	        },
	        "osDisk": {
	          "caching": "ReadWrite"
	        },
	        "extensions": [ ],
	        "availabilitySet": {
	          "useExistingAvailabilitySet": "No",
	          "name": ""
	        }
	      }
	    },
	    "virtualNetworkSettings": {
	      "value": {
	        "name": "ra-single-vm-vnet",
	        "resourceGroup": "ra-single-vm-rg"
	      }
	    },
	    "buildingBlockSettings": {
	      "value": {
	        "storageAccountsCount": 1,
	        "vmCount": 1,
	        "vmStartIndex": 0
	      }
	    }
	  }

## Solution deployment

You can deploy this reference architecture by using PowerShell, bash, or the Azure portal. To do so using your own parameter files, follow the instructions below.

1. Download all the files and folders in this folder.

2. In the **parameters** folder, customize each parameter file according to your needs.

3. Follow the steps in one of the following sections to deploy your solution.

### Portal
1. Copy your parameters files to a URI that is publicly accessible.

2. Click the button below.

	<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Freference-architectures%2Fmaster%2Fguidance-compute-single-vm%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/></a>

3. In the Azure portal, specify the **Subscription**, **Resource group**, and **Location** you want to use for your deployment.

	**Note** Make sure the **Resource group** name used matches the value used in your parameter files.

4. In the **Parameter Root Uri** textbox, type the URL where you copied your parameter files to. Remember, this must be a publicly accessible URL.

5. Specify the **OS Type** (Windows or Linux).

6. Click **I agree to the terms and conditions stated above** and then click **Purchase**.

### PowerShell
1. Open a PowerShell console and navigate to the folder where you downloaded the script and parameter files.

2. Run the cmdlet below using your own subscription id, location, OS type, and resource group name.

	.\Deploy-ReferenceArchitecture -SubscriptionId <id> -Location <location> -OSType <linux|windows> -ResourceGroupName <resource group>

### Bash
1. Open a bash console and navigate to the folder where you downloaded the script and parameter files.

2. Run the command below using your own subscription id, location, OS type, and resource group name.

	sh deploy-reference-architecture.sh -s <subscription id> -l <location> -o <linux|windows> -r <resource group>

<!-- links -->
[0]: ./diagram.png
[bb]: https://github.com/mspnp/template-building-blocks
[bb-vnet]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/vnet-n-subnet
[bb-nsg]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/networkSecurityGroups
[bb-vm]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/multi-vm-n-nic-m-storage
[deployment]: #Solution-deployment
[solution-shscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/deploy-reference-architecture.sh
[solution-psscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/Deploy-ReferenceArchitecture.ps1
[solution-template]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/azuredeploy.json
[vnet-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualNetwork.parameters.json 
[nsg-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/parameters/linux/networkSecurityGroups.parameters.json
[vm-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualMachine.parameters.json
[guidance]: https://azure.microsoft.com/en-us/documentation/articles/guidance-compute-single-vm-linux/