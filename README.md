# Advanced Migration Scenarios for AzCopy
The following repo contains several scripts for large migrations of a storage account from one subscription to a new subscription with additional scripts for error handling, checking results and syncing missed data. For more info on choosing the right data transfer tool, take a look at Microsoft's guide for performing data migrations: https://docs.microsoft.com/en-us/azure/storage/common/storage-choose-data-transfer-solution

## Azure Blob Storage Container Metadata Script
Outputs metadata about a blob storage account such as the container names, total number of blob files, and total size of all blobs inside the container. It then outputs the results to .csv file and publishes the file to a storage account. Performing a thorough assessment of your storage accounts before performing a migration is critical to ensure migration jobs are optimized. This script is also useful after the migration has taken place to compare source to destination metadata are in sync.

## AzCopy Storage Blob Migration Script
The following script is meant for migrating V1 storage accounts to a new V2 storage accounts. Therefore the V1 source accounts use temporary SAS keys for authentication, while the destination V2 accounts uses an AzureAD service principle AzCopy login to authenticate. The script offers several optimizations, and the ability to pass in a subset of container names to break the migration into multiple jobs

## AzCopy Restart Failed Job
AzCopy has the ability to restart a failed/incomplete job using the job id. When an AzCopy command is run, it should ouput the jobid at the start, otherwise you can find it by running "azcopy jobs list", or navigating to the location of your AzCopy logs.

## AzCopy Sync
AzCopy can also synchronize storage containers to ensure the source and destination match up. The sync functionality is useful for copying over any remaining blobs that might have been sent to the source after the migration started.
