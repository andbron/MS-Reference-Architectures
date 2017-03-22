# .\installWebAppProxy.ps1 -AdminUser adminUser -AdminPassword "adminP@ssw0rd" -NetBiosDomainName CONTOSO -FederationName adfs.contoso.com
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$NetBiosDomainName,

  [Parameter(Mandatory=$True)]
  [string]$FederationName
)
###############################################
# Manual step for install certificate to the ADFS Web Applicaiton Proxy VMs:

# 1. Make sure you have a certificate (e.g. adfs.contoso.com.pfx) either self created or signed by VerifSign, Go Daddy, DigiCert, and etc.

# 2. RDP to the each ADFS VM (adfs1-vm, adfs2-vm, ...)

# 3. Copy to c:\temp the following file
#		c:\temp\certutil.exe
#		c:\temp\adfs.contoso.com.pfx 
#       c:\MyFakeRootCertificateAuthority.cer  (if you created the above cert yourself \

# 4. Run the following command prompt as admin:
#    	certutil.exe -privatekey -importPFX my C:\temp\adfs.contoso.com.pfx NoExport
#    Run the following command prompt as admin \(if you created the above cert yourself \)
#	    certutil.exe -addstore Root C:\temp\MyFakeRootCertificateAuthority.cer 

# 5. Start MMC, Add Certificates Snap-in, sellect Computer account, and verify that the following certificate is installed:
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com
#    If you created the above cert yourself, verify the the following certificate is installed:
#      \Certificates (Local Computer)\Trusted Root Certification Authorities\Certificates\MyFakeRootCertificateAuthority 
###############################################

# get credential of the domain admin
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

# retrieve the the thumbnail of certificate
$thumbprint=(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint

# Install ADFS feature
Install-WindowsFeature -IncludeManagementTools -name Web-Application-Proxy

Install-WebApplicationProxy -FederationServiceTrustCredential $credential -CertificateThumbprint $thumbprint -FederationServiceName $FederationName 

Restart-Computer
