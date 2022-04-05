Standalone Root CA
==================

Install windows 2019

Rename server
```Powershell
rename-computer ORCA1
restart-computer
```

Create CAPolicy.inf
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
certutil –setreg CA\CACertPublicationURLs "2:http://www.contoso.com/pki/%1_%3%4.crt"
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
Get-CAAuthorityInformationAccess | format-list and Get-CACRLDistributionPoint | format-list
```

Retrieve the CA certificate
```Powershell
dir C:\Windows\system32\certsrv\certenroll\*.cr*
copy C:\Windows\system32\certsrv\certenroll\*.cr* A:\
dir A:\
```