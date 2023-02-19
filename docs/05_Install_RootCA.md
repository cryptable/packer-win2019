Standalone Root CA
==================

Installation
------------

- https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831348(v=ws.11)

Install windows 2019

Rename server
```Powershell
rename-computer ORCA1
restart-computer
```

Create CAPolicy.inf in C:\Windows
```
[Version]
Signature="$Windows NT$"
[PolicyStatementExtension]
Policies=InternalPolicy
[InternalPolicy]
OID= 1.2.3.4.1455.67.89.5
Notice="Legal Policy Statement"
URL=http://www.contoso.com/pki/cps.txt
[Certsrv_Server]
RenewalKeyLength=2048
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=20
CRLPeriod=weeks
CRLPeriodUnits=26
CRLDeltaPeriod=Days
CRLDeltaPeriodUnits=0
LoadDefaultTemplates=0
# If RSA-PSS is wanted -> set to 1
AlternateSignatureAlgorithm=0
```

Install ADCS

```Powershell
Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
```

Create Root CA

```Powershell
Install-AdcsCertificationAuthority -CAType StandaloneRootCA -CACommonName "Cryptable Root CA" -CADistinguishedNameSuffix "O=Cryptable, C=BE" -KeyLength 4096 -HashAlgorithmName SHA256 -ValidityPeriod Years -ValidityPeriodUnits 25 -Force
```

In case of mistake

```Powershell
Uninstall-AdcsCertificationAuthority -Force
```

```Powershell
Install-AdcsCertificationAuthority -CAType StandaloneRootCA -CACommonName "Cryptable Root CA" -CADistinguishedNameSuffix "O=Cryptable, C=BE" -KeyLength 4096 -HashAlgorithmName SHA256 -ValidityPeriod Years -ValidityPeriodUnits 25 -Force -OverwriteExistingDatabase -OverwriteExistingKey
```



CRL and AIA configuration

```Powershell
certutil -setreg CA\CRLPublicationURLs "1:C:\Windows\system32\CertSrv\CertEnroll\%3%8.crl\n2:http://www.contoso.com/pki/%3%8.crl"
certutil -setreg CA\CACertPublicationURLs "2:http://www.contoso.com/pki/%1_%3%4.crt"
Certutil -setreg CA\CRLOverlapPeriodUnits 12
Certutil -setreg CA\CRLOverlapPeriod "Hours"
Certutil -setreg CA\ValidityPeriodUnits 10
Certutil -setreg CA\ValidityPeriod "Years"
certutil -setreg CA\DSConfigDN CN=Configuration,DC=corp,DC=contoso,DC=com
restart-service certsvc
certutil -crl
```

```Powershell
$crllist = Get-CACrlDistributionPoint; 
foreach ($crl in $crllist) {
  Remove-CACrlDistributionPoint $crl.uri -Force
};
Add-CACRLDistributionPoint -Uri C:\Windows\System32\CertSrv\CertEnroll%3%8.crl -PublishToServer -Force
Add-CACRLDistributionPoint -Uri http://www.contoso.com/pki/%3%8.crl -AddToCertificateCDP -Force 
$aialist = Get-CAAuthorityInformationAccess; 
foreach ($aia in $aialist) {
  Remove-CAAuthorityInformationAccess $aia.uri -Force
}; 
Certutil -setreg CA\CRLOverlapPeriodUnits 12
Certutil -setreg CA\CRLOverlapPeriod "Hours"
Certutil -setreg CA\ValidityPeriodUnits 10
Certutil -setreg CA\ValidityPeriod "Years"
restart-service certsvc
certutil -crl
```

View the configuration
```Powershell
Get-CAAuthorityInformationAccess | format-list
Get-CACRLDistributionPoint | format-list
```

Retrieve the CA certificate
```Powershell
dir C:\Windows\system32\certsrv\certenroll\*.cr*
copy C:\Windows\system32\certsrv\certenroll\*.cr* A:\
dir A:\
```

Testing your CA
---------------

- https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/configure-the-server-certificate-template
- https://learn.microsoft.com/en-us/answers/questions/431223/use-certreq-certutil-to-request-and-approve-a-cert
- https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certreq_1

Remark: A standalone RootCA has no templates, because there is no AD to store them. It signs all the extensions which are delivered by the cert request.

```
New-Item .\certreq.inf
Set-Content .\certreq.inf "[Version]
Signature = `"`$WindowsNT`$`"

[NewRequest]
Subject = `"CN=Test`"
Exportable = TRUE
KeyLength = 2048

[Strings]
szCUSTOM_EXTENSION = 1.2.3.4.5.123.1.1
szPK_PACS = 1.3.6.1.4.1.59685.8.5

[RequestAttributes]
CertificateTemplate=TestTemplate

[Extensions]
`%szCUSTOM_EXTENSION`% = `"{text}`"
_continue_ = `"%szOID_PKIX_KP_CLIENT_AUTH%=00001000001500`"
"
