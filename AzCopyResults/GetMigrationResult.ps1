# #Parameters
param (
    [String]
    $srcStorageAccountName,
    
    [String]
    $srcStorageAccessKey,
    
    [String]
    $destinationStorageAccountName
)


###########################SRC ACCOUNT CALCULATIONS#########################################
$srcBlobCount = 0;
$srcContainerCount = 0;
$srcStorageSize = 0;

$srcStorageAccountContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccessKey
$srcContainers = Get-AzStorageContainer -Name "*" -Context $srcStorageAccountContext
foreach($container in $srcContainers)
{
    $srcContainerCount++;
    
    #Blobs counts
    $blobs = Get-AzStorageBlob -Context $srcStorageAccountContext -Container $container.Name;
    $srcBlobCount = $srcBlobCount + $blobs.Count

    #container size
    $srcStorageSize = $srcStorageSize + $blobs.Length
}

Write-Host $srcStorageAccountName " Results:"
Write-Host "Total number of containers: " $srcContainerCount
Write-Host "Total number of blobs: " $srcBlobCount
Write-Host "Total storage size: " $srcStorageSize "MB"


############################DEST ACCOUNT CALCULATIONS#########################################
$destBlobCount = 0;
$destContainerCount = 0;
$destStorageSize = 0;

$destStorageAccountContext = New-AzStorageContext -StorageAccountName $destinationStorageAccountName -UseConnectedAccount
$containers = Get-AzStorageContainer -Name "*" -Context $destStorageAccountContext
foreach($container in $containers)
{
    $destContainerCount++;
    
    #Blobs counts
    $blobs = Get-AzStorageBlob -Context $destStorageAccountContext -Container $container.Name;
    $destBlobCount = $destBlobCount + $blobs.Count

    #container size
    $destStorageSize = $destStorageSize + $blobs.Length
}

Write-Host $destStorageAccountName " Results:"
Write-Host "Total number of containers: " $destContainerCount
Write-Host "Total number of blobs: " $destBlobCount
Write-Host "Total storage size: " $destStorageSize "MB"
