param (
    [String]
    $tenantId,
    
    [String]
    $servicePrincipleClientId,

    [String]
    $servicePrincipleClientSecret,

    [String]
    $srcStorageAccountName,
    
    [String]
    $srcStorageAccessKey,
    
    [String]
    $destinationStorageAccountName
)

###########################PERFORM LOGIN TO NEW SUBSCRIPTION#########################################
$env:AZCOPY_SPA_CLIENT_SECRET=$servicePrincipleClientSecret
&$azCopyPath  login --service-principal --application-id $servicePrincipleClientId --tenant-id $tenantId

#Create SAS Token for Blob Source
$StartTime = Get-Date
$EndTime = $startTime.AddHours(48.0)
$srcStorageAccountUrl = "https://" + $srcStorageAccountName + ".blob.core.windows.net/" 
$srcStorageAccountContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccessKey

###########################DESTINATION ACCOUNT #########################################
$destinationStorageAccountUrl = "https://" + $destinationStorageAccountName + ".blob.core.windows.net/" 

###########################PERFORM SYNC#########################################
$srcContainers = Get-AzStorageContainer -Name "*" -Context $srcStorageAccountContext
foreach($container in $srcContainers)
{
  $containerName = $container.Name
  Write-Host "Syncing container $containerName from source to dest."
  $srcStorageAccountSASToken = New-AzStorageContainerSASToken -Context $srcStorageAccountContext `
      -Name $containerName `
      -Permission racwdl `
      -ExpiryTime $EndTime

    $srcContainerUrl = $srcStorageAccountUrl + $containerName + $srcStorageAccountSASToken
    $destContainerUrl = $destinationStorageAccountUrl + $containerName
    &$copyPath sync $srcContainerUrl $destContainerUrl --recursive=true
}
