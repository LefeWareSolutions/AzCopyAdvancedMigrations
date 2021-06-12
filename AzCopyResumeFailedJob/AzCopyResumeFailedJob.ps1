#Parameters
param (
    [String]
    $jobId,

    [String]
    $tenantId,
    
    [String]
    $servicePrincipleClientId,

    [String]
    $servicePrincipleClientSecret
)

$env:AZCOPY_SPA_CLIENT_SECRET=$servicePrincipleClientSecret
$copyPath="C:\AzCopy\azcopy.exe" 
&$copyPath  login --service-principal --application-id "$servicePrincipleClientId" --tenant-id "$tenantId"

&$copyPath jobs resume $jobId