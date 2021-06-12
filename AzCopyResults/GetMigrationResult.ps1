param (
    [String]
    $storageAccountName,

    [bool]
    $useMasterKey,

    [bool]
    $useContainerNameList,
    
    [String]
    $storageAccountAccessKey,

    [String[]]
    $containerNameList
)
        
###########################GET STORAGE ACCOUNT CONTEXT#########################################
$storageAccountContext
if($useMasterKey -eq $true)
{
    $storageAccountContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountAccessKey
}
else
{
    $storageAccountContext = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
}


###########################GET CONTAINERS TO CALCUALTE#########################################
$containersToCalculate = @()
if($useContainerNameList -eq $true)
{
    $allContainers = Get-AzStorageContainer -Name "*" -Context $storageAccountContext
    foreach($container in $allContainers)
    {
        $containerName = $container.Name                
        # Validate if container name is included in our list
        if($containerNameList.Contains($containerName))
        {
            $containersToCalculate+=$container
        }
    }
}
else 
{
    $containersToCalculate += Get-AzStorageContainer -Name "*" -Context $storageAccountContext
}


###########################CALCULATE SIZE AND NUMBER OF FILES#########################################
$results = @()
foreach($container in $containersToCalculate)
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


###########################OUTPUT RESULTS TO .CSV#########################################
$resultsFileName = "$(get-date -f yyyy-MM-dd-HHmmss)-Results.csv"
$path = ".\" + $resultsFileName 
New-Item -Path . -Name $resultsFileName -ItemType "file"
$results | export-csv -Path $path -NoTypeInformation


###########################PUBLISH RESULTS TO AZ STORAGE#########################################
$resultsContainerName = "storageresults"
if (!(Get-AzStorageContainer -Context $storageAccountContext | Where-Object { $_.Name -eq $resultsContainerName }))
{
    New-AzStorageContainer -Name $resultsContainerName  -Context $storageAccountContext
}
Set-AzStorageBlobContent -File $path -Container $resultsContainerName -Blob $resultsFileName -Context $storageAccountContext 