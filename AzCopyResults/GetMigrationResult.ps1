# #Parameters
param (
    [String]
    $srcStorageAccountName,
    
    [String]
    $srcStorageAccessKey,

    [String]
    $destinationStorageAccountName,

    [String[]]
    $resultType,
    
    [bool]
    $getSrc,

    [bool]
    $getDest,
    
    [Int]
    $startIndex,

    [Int]
    $endIndex
)


function DisplayStorageAccountResults {
    param (
        $storageAccountContext,
        $containers
    )

    $blobCount = 0;
    $containerCount = 0;
    $storageSize = 0;

    foreach($container in $containers)
    {
        Write-Host "Calculating blob results for" $container.Name "container"
        $containerCount++;
        
        #Blobs counts
        $blobs = Get-AzStorageBlob -Context $storageAccountContext -Container $container.Name;
        $blobCount = $blobCount + $blobs.Count
    
        #container size
        $storageSize = $storageSize + $blobs.Length
    }

    Write-Host $storageAccountContext.StorageAccountName " Results:"
    Write-Host "Total number of containers:"  $containerCount
    Write-Host "Total number of blobs:" $blobCount
    Write-Host "Total storage size:" $storageSize "MB"
}

function DisplayStorageContainerResults {
    param (
        $storageAccountContext,
        $containers,
        $startIndex,
        $endIndex
    )

    foreach($container in $containers)
    {
        $containerName = $container.Name
        $containerNameInt = [int]$containerName
        if($containerNameInt -ge $startIndex -And $containerNameInt -le $endIndex)
        {
            $blobs = Get-AzStorageBlob -Context $storageAccountContext -Container $container.Name;
            Write-Host "Blob Container" $container.Name "Results:"
            Write-Host "Total number of blobs: " $blobs.Count
            Write-Host "Total storage size: " $blobs.Length "MB"
        }
    }
}

###########################SRC ACCOUNT CALCULATIONS#########################################
if($getSrc -eq $true)
{
    $srcStorageAccountContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccessKey
    $srcContainers = Get-AzStorageContainer -Name "*" -Context $srcStorageAccountContext
    if($resultType.Contains("Range"))
    {
        DisplayStorageContainerResults -storageAccountContext $srcStorageAccountContext -containers $srcContainers -startIndex $startIndex -endIndex $endIndex
    }
    else 
    {
        DisplayStorageAccountResults -storageAccountContext $srcStorageAccountContext -containers $srcContainers
    }
}
############################DEST ACCOUNT CALCULATIONS#########################################
if($getDest -eq $true)
{
    $destStorageAccountContext = New-AzStorageContext -StorageAccountName $destinationStorageAccountName -UseConnectedAccount
    $destContainers = Get-AzStorageContainer -Name "*" -Context $destStorageAccountContext
    if($resultType.Contains("Range"))
    {
        DisplayStorageContainerResults -storageAccountContext $destStorageAccountContext -containers $destContainers -startIndex $startIndex -endIndex $endIndex
    }
    else 
    {
        DisplayStorageAccountResults -storageAccountContext $destStorageAccountContext -containers $destContainers
    }
}
