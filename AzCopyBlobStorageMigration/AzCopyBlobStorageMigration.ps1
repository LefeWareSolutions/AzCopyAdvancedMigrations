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

    [bool]
    $useContainerNameList,

    [String[]]
    $containerNameList
)

#Increases the number of concurrent requests that can occur on your machine
$env:AZCOPY_CONCURRENCY_VALUE=1000
$azCopyPath="C:\AzCopy\azcopy.exe" 

###########################PERFORM LOGIN TO NEW SUBSCRIPTION#########################################
$env:AZCOPY_SPA_CLIENT_SECRET=$servicePrincipleClientSecret
&$azCopyPath  login --service-principal --application-id $servicePrincipleClientId --tenant-id $tenantId

###########################SOURCE STORAGE ACCOUNT #########################################
$StartTime = Get-Date
$EndTime = $startTime.AddHours(48.0)
$srcStorageAccountContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccessKey
$srcStorageAccountUrl = "https://" + $srcStorageAccountName + ".blob.core.windows.net/" 

###########################DESTINATION ACCOUNT #########################################
$destinationStorageAccountUrl = "https://" + $destinationStorageAccountName + ".blob.core.windows.net/" 


###########################PERFORM COPY#########################################
if($useContainerNameList -eq $true)
{
    $srcContainers = Get-AzStorageContainer -Name "*" -Context $srcStorageAccountContext
    foreach($container in $srcContainers)
    {
        $containerName = $container.Name                
        # Validate if container name is included in our list
        if($containerNameList.Contains($containerName))
        {
            Write-Host "Copying container $containerName from source to dest."
            $srcStorageAccountSASToken = New-AzStorageContainerSASToken `
                -Context $srcStorageAccountContext `
                -Name $containerName `
                -Permission rwdl  `
                -ExpiryTime $EndTime          
            $srcStorageAccountSASUrl = $srcStorageAccountUrl + $containerName + $srcStorageAccountSASToken

            &$azCopyPath copy $srcStorageAccountSASUrl $destinationStorageAccountUrl --recursive
        }
    }
}
else 
{
    Write-Host "Copying all containers from storage $srcStorageAccountName to destination storage account $destinationStorageAccountName"
    $srcStorageAccountSASToken = New-AzStorageAccountSASToken `
        -Context $srcStorageAccountContext `
        -Service Blob `
        -ResourceType Service,Container,Object `
        -Permission rwdl `
        -ExpiryTime $EndTime
    $srcStorageAccountSASUrl = $srcStorageAccountUrl + $srcStorageAccountSASToken
    
    &$azCopyPath copy $srcStorageAccountSASUrl  $destinationStorageAccountUrl --recursive
}
