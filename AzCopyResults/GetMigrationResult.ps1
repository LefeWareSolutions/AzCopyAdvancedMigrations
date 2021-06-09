#Parameters
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

###########################CALCULATE STORAGE COTAINERS#########################################
function DisplayStorageContainerResults {
    param (
        $storageAccountContext,
        $containers
    )

    $results = @()
    foreach($container in $containers)
    {
        $blobs = Get-AzStorageBlob -Context $storageAccountContext -Container $container.Name;
        $length = 0
        $blobs | ForEach-Object {$length = $length + $_.Length}
        Write-Host "Blob Container" $container.Name "Results:"
        Write-Host "Total number of blobs: " $blobs.Count
        Write-Host "Total storage size: " $length "MB"
        $details = @{            
            ContainerName    = $container.Name            
            NumberOfBlobs    = $blobs.Count                 
            StorageSize      = $length
        } 
        $results += New-Object PSObject -Property $details   
    }

    $resultsFileName = "$(get-date -f yyyy-MM-dd-HHmmss)-Results.csv"
    $path = ".\" + $resultsFileName 

    if(!(Test-Path $path))
    {
        New-Item -Path . -Name $resultsFileName -ItemType "file"
    }
    $results | export-csv -Path $path -NoTypeInformation


    $resultsContainerName = "storageresults"
    if (!(Get-AzStorageContainer -Context $storageAccountContext | Where-Object { $_.Name -eq $resultsContainerName }))
    {
        New-AzStorageContainer -Name $resultsContainerName  -Context $storageAccountContext
    }
    Set-AzStorageBlobContent -File $path -Container $resultsContainerName -Blob $resultsFileName -Context $storageAccountContext 
}



###########################SRC ACCOUNT CALCULATIONS#########################################
if($getSrc -eq $true)
{
    $srcStorageAccountContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccessKey
    $srcContainers = @()

    if($resultType.Contains("Range"))
    {
        $allContainers = Get-AzStorageContainer -Name "*" -Context $srcStorageAccountContext
        foreach($container in $allContainers)
        {
            $containerName = $container.Name
            try
            {
                $containerNameInt = [int]$containerName
                if($containerNameInt -ge $startIndex -And $containerNameInt -le $endIndex) 
                {
                    $srcContainers+=$container
                }
            }
            catch
            {
                Write-Host "Unable to get results for" $containerName
            }
        }
    }
    else 
    {
        $srcContainers += Get-AzStorageContainer -Name "*" -Context $srcStorageAccountContext
    }
    DisplayStorageContainerResults -storageAccountContext $srcStorageAccountContext -containers $srcContainers
}

############################DEST ACCOUNT CALCULATIONS#########################################
if($getDest -eq $true)
{
    $destStorageAccountContext = New-AzStorageContext -StorageAccountName $destinationStorageAccountName -UseConnectedAccount
    $destContainers = @()

    if($resultType.Contains("Range"))
    {
        $allContainers += Get-AzStorageContainer -Name "*" -Context $destStorageAccountContext
        foreach($container in $allContainers)
        {
            $containerName = $container.Name
            try{
                $containerNameInt = [int]$containerName
                if($containerNameInt -ge $startIndex -And $containerNameInt -le $endIndex) 
                {
                    $destContainers+=$container
                }
            }
            catch
            {

            }
        }
    }
    else 
    {
        $destContainers += Get-AzStorageContainer -Name "*" -Context $destStorageAccountContext
    }
    DisplayStorageContainerResults -storageAccountContext $destStorageAccountContext -containers $destContainers

}
