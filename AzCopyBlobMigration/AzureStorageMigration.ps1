# Script Parameters
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

    [String[]]
    $IncludeContainer
)

#Increases the number of concurrent requests that can occur on your machine
$env:AZCOPY_CONCURRENCY_VALUE=1000

#AzCopy Login using service principle
$env:AZCOPY_SPA_CLIENT_SECRET=$servicePrincipleClientSecret
$copyPath="C:\AzCopy\azcopy.exe" 
&$copyPath  login --service-principal --application-id "$servicePrincipleClientId" --tenant-id "$tenantId"

#Blob Source
$StartTime = Get-Date
$EndTime = $startTime.AddHours(48.0)
$srcStorageAccountContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccessKey
$srcStorageAccountUrl = "https://" + $srcStorageAccountName + ".blob.core.windows.net/" 

#Blob Dest 
$destinationStorageAccountUrl = "https://" + $destinationStorageAccountName + ".blob.core.windows.net/" 

if($IncludeContainer.Contains("All"))
{
    Write-Host "Copying all containers from storage $srcStorageAccountName to destination storage account $destinationStorageAccountName"
    $srcStorageAccountSASToken = New-AzStorageAccountSASToken `
        -Context $srcStorageAccountContext `
        -Service Blob `
        -ResourceType Service,Container,Object `
        -Permission rwdl 
        -StartTime $StartTime 
        -ExpiryTime $EndTime
    $srcStorageAccountSASUrl = $srcStorageAccountUrl + $srcStorageAccountSASToken
    &$copyPath copy $srcStorageAccountSASUrl  $destinationStorageAccountUrl --recursive
}
else 
{
    # Get all containers from source
    $srcContainers = Get-AzStorageContainer -Name "*" -Context $srcStorageAccountContext
    foreach($container in $srcContainers)
    {
        $containerName = $container.Name                
        # Validate if container name is included in our list
        if($IncludeContainer.Contains($containerName))
        {
            Write-Host "Copying container $containerName from source to dest."
            $srcStorageAccountSASToken = New-AzStorageContainerSASToken -Context $srcStorageAccountContext `
                -Name $containerName `
                -Permission racwdl `
                -ExpiryTime $EndTime
            

            $srcContainerUrl = $srcStorageAccountUrl + $containerName + $srcStorageAccountSASToken
            $destContainerUrl = $destinationStorageAccountUrl 

            &$copyPath copy $srcContainerUrl $destContainerUrl --recursive
        }
    }
}