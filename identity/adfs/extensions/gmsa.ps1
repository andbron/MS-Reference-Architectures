[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$NetBiosDomainName,

   [Parameter(Mandatory=$True)]
  [string]$FqDomainName,

  [Parameter(Mandatory=$True)]
  [string]$GmsaName,

  [Parameter(Mandatory=$True)]
  [string]$FederationName,

  [Parameter(Mandatory=$True)]
  [string]$HostName,

  [Parameter(Mandatory=$True)]
  [string]$HostIp
)

# $AdminUser = "testuser"
# $AdminPassword = "AweS0me@PW"
# $NetBiosDomainName = "CONTOSO"
# $FqDomainName = "contoso.com"
# $GmsaName = "adfsgmsa"
# $FederationName = "adfs.contoso.com"
# $HostName="adfs"
# $HostIp="10.0.255.190"


###############################################
# get credential of the domain admin
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

###############################################
# Create group managed service accout (you can use ADSI Edit to verify)
Add-KdsRootKey –EffectiveTime (Get-Date).AddHours(-10) 
#New-ADServiceAccount adfsgmsa -DNSHostName adfs.contoso.com -AccountExpirationDate $null -ServicePrincipalNames host/adfs.contoso.com -Credential $credential
New-ADServiceAccount $GmsaName -DNSHostName $FederationName -AccountExpirationDate $null -ServicePrincipalNames "host/$FederationName" -Credential $credential

###############################################
# add DNS Record for adfs load balancer (you cna use DNS tool to verify)
# Add-DnsServerResourceRecordA -Name "adfs" -ZoneName "contoso.com" -AllowUpdateAny -IPv4Address "10.0.255.190"
Add-DnsServerResourceRecordA -Name $HostName -ZoneName $FqDomainName -AllowUpdateAny -IPv4Address $HostIp

