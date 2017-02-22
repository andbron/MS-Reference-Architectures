[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$DomainName,

  [Parameter(Mandatory=$True)]
  [string]$SiteName,

  [Parameter(Mandatory=$True)]
  [string]$OnpremSiteName,

  [Parameter(Mandatory=$True)]
  [string]$Cidr,

  [Parameter(Mandatory=$True)]
  [int]$ReplicationFrequency
)

$Description="azure vnet ad site"
$Location="azure subnet location"
$SitelinkName = "AzureToOnpremLink"

Import-Module ADDSDeployment

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$AdminUser", $secAdminPassword)

New-ADReplicationSite -Name $SiteName -Description $Description -Credential $credential 

New-ADReplicationSubnet -Name $Cidr -Site $SiteName -Location $location -Credential $credential 

New-ADReplicationSiteLink `
-Credential $credential `
-Name $SitelinkName `
-SitesIncluded $OnpremSiteName, $SiteName `
-Cost 100 `
-ReplicationFrequency $ReplicationFrequency `
-InterSiteTransportProtocol IP
