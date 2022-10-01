Import-Module Az.KeyVault
# Set up RG

$resourceGroup = "<RESOURCE-GROUP-NAME>"
$location = "<LOCATION-NAME>"
New-AzResourceGroup -ResourceGroupName $resourceGroup -Location $location

# Create KV
$keyvaultName="<KEY-VAULT-NAME>"
New-AzKeyVault -VaultName $keyvaultName `
    -ResourceGroup $resourceGroup `
    -Location $location `
    -EnabledForDeployment

# Create cert and store in KV
$policy = New-AzKeyVaultCertificatePolicy `
    -SubjectName "CN=<CERTIFICATE-NAME>" `
    -SecretContentType "application/x-pkcs12" `
    -IssuerName Self `
    -ValidityInMonths 12

$certName = "mycert"
Add-AzKeyVaultCertificate `
    -VaultName $keyvaultName `
    -Name $certName `
    -CertificatePolicy $policy

# Set VM credentials
# vmdemoadmin
# demopassword1!
$cred = Get-Credential

# Create a VM
New-AzVm `
    -ResourceGroupName $resourceGroup `
    -Name "myVM" `
    -Location $location `
    -VirtualNetworkName "myVnet" `
    -SubnetName "mySubnet" `
    -SecurityGroupName "myNetworkSecurityGroup" `
    -PublicIpAddressName "myPublicIpAddress" `
    -Credential $cred `
    -OpenPorts 443 `
    -Priority "Spot" ` # spot instance
    -Image "Win2019Datacenter" `
    -Size "Standard_L8s_v2"


# Use the Custom Script Extension to install IIS
Set-AzVMExtension -ResourceGroupName $resourceGroup `
    -ExtensionName "IIS" `
    -VMName "myVM" `
    -Location $location `
    -Publisher "Microsoft.Compute" `
    -ExtensionType "CustomScriptExtension" `
    -TypeHandlerVersion 1.8 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server -IncludeManagementTools"}'

# Add cert to VM from KV
$certURL=(Get-AzKeyVaultSecret -VaultName $keyvaultName -Name $certName).id

$vm=Get-AzVM -ResourceGroupName $resourceGroup -Name "myVM"
$vaultId=(Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName).ResourceId
$vm = Add-AzVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "My" -CertificateUrl $certURL

Update-AzVM -ResourceGroupName $resourceGroup -VM $vm

# Configure IIS to use the cert
$publicSettings = '{
    "fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/secure-iis.ps1"],
    "commandToExecute":"powershell -ExecutionPolicy Unrestricted -File secure-iis.ps1"
}'

Set-AzVMExtension -ResourceGroupName $resourceGroup `
    -ExtensionName "IIS" `
    -VMName "myVM" `
    -Location $location `
    -Publisher "Microsoft.Compute" `
    -ExtensionType "CustomScriptExtension" `
    -TypeHandlerVersion 1.8 `
    -SettingString $publicSettings

# Test by visiting FQDN of VM