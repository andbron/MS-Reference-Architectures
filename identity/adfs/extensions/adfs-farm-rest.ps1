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
  [string]$PrimaryComputerName
)

###############################################
# $AdminUser = "testuser"
# $AdminPassword = "AweS0me@PW"
# $NetBiosDomainName = "CONTOSO"
# $FqDomainName = "contoso.com"
# $GmsaName = "adfsgmsa"
# $FederationName = "adfs.contoso.com"
# $PrimaryComputerName = "adfs1"

# get credential of the domain admin
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

# retrieve the the thumbnail of certificate
$thumbprint=(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint

# Install ADFS feature
Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation
Import-Module ADFS

# add a node to the existing ADFS Farm
Add-AdfsFarmNode -CertificateThumbprint $thumbprint -PrimaryComputerName $PrimaryComputerName -GroupServiceAccountIdentifier "$NetBiosDomainName\$GmsaName`$" -Credential $credential

# Initialize device registration service for workplace join 
Initialize-ADDeviceRegistration -ServiceAccountName "$NetBiosDomainName\$GmsaName`$" -DeviceLocation $FqDomainName -RegistrationQuota 10 -MaximumRegistrationInactivityPeriod 90 -Credential $Credential -Force

Enable-AdfsDeviceRegistration -Credential $Credential -Force
#############################


# Test with the folloiwng link
# https://adfs.contoso.com/adfs/ls/idpinitiatedsignon.htm

###############################################
# Note
# Manual step for install certificate to the ADFS VMs:

# 1. Make sure you have a certificate (e.g. adfs.contoso.com.pfx) either self created or signed by VerifSign, Go Daddy, DigiCert, and etc.

# 2. RDP to the each ADFS VM (adfs1-vm, adfs2-vm, ...)

# 3. Copy to c:\temp the following file
#		c:\temp\certutil.exe
#		c:\temp\adfs.contoso.com.pfx 

# 4. Run the following command prompt as admin:
#    	certutil.exe -privatekey -importPFX my C:\temp\adfs.contoso.com.pfx NoExport

# 5. Start MMC, Add Certificates Snap-in, sellect Computer account, and verify that the following certificate is installed:
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com
