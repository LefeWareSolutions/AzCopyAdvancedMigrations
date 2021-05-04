# #Parameters
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
    $destinationStorageAccountName,
)

#AzCopy
$env:AZCOPY_SPA_CLIENT_SECRET=$servicePrincipleClientSecret
$copyPath="C:\AzCopy\azcopy.exe" 
&$copyPath  login --service-principal --application-id "$servicePrincipleClientId" --tenant-id "$tenantId"

#Create SAS Token for Blob Source
$StartTime = Get-Date
$EndTime = $startTime.AddHours(48.0)
$srcStorageAccountUrl = "https://" + $srcStorageAccountName + ".blob.core.windows.net/" 
$srcStorageAccountContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccessKey
$srcStorageAccountSASToken = New-AzStorageAccountSASToken -Context $srcStorageAccountContext -Service Blob -ResourceType Service,Container,Object -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime

#Blob Dest 
$destinationStorageAccountUrl = "https://" + $destinationStorageAccountName + ".blob.core.windows.net/" 

# Get all containers from source
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
