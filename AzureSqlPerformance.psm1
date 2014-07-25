function Test-AzureSqlDatabaseImportPerformance {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)][string]$DatabaseName,
        [parameter(Mandatory=$true)][string]$ServerAdminUsername,
        [parameter(Mandatory=$true)][string]$ServerAdminPassword,
        [parameter(Mandatory=$true)][string]$ServerLocationName,
        [parameter(Mandatory=$true)][string]$DatabaseEdition,
        [parameter(Mandatory=$true)][string]$DatabaseServiceObjective,
        [parameter(Mandatory=$true)][string]$StorageAccountName,
        [parameter(Mandatory=$true)][string]$StorageAccountKey,
        [parameter(Mandatory=$true)][string]$StorageAccountContainer,
        [parameter(Mandatory=$true)][string]$StorageAccountBlobName,
        [parameter(Mandatory=$true)][string]$MaximumSizeGB

    )
    process
    {
        $location = Get-AzureLocation | Where-Object -FilterScript { $_.Name -eq $ServerLocationName }

        if ($location -eq $null) {
            throw "Location is not valid."
        }

        Write-Verbose $ServerAdminUsername
        Write-Verbose $ServerAdminPassword

        $server = New-AzureSqlDatabaseServer -AdministratorLogin $ServerAdminUsername -AdministratorLoginPassword $ServerAdminPassword -Location $ServerLocationName

        Write-Verbose "Server Name is $($server.ServerName)."

        while ($server.OperationStatus -ne "Success") {
            Write-Verbose "Waiting for server to be created."
            $server = Get-AzureSqlDatabaseServer $server.ServerName
        }

        Write-Verbose "Server is ready."

        $objective = Get-AzureSqlDatabaseServiceObjective -ServerName $server.ServerName | Where-Object -FilterScript { $_.Name -eq $DatabaseServiceObjective }

        if ($objective -eq $null) {
            throw "Objective is not valid."
        }

        $database = New-AzureSqlDatabase -ServerName $server.ServerName -DatabaseName $DatabaseName -Edition $DatabaseEdition -ServiceObjective $objective -MaxSizeGB $MaximumSizeGB
        
        while ($database.Status -ne 0) {
            Write-Verbose "Waiting for database to come online."
            $database = Get-AzureSqlDatabase -ServerName $server.Name -DatabaseName $DatabaseName
        }

        New-AzureSqlDatabaseServerFirewallRule -ServerName $server.ServerName -RuleName Everything -StartIpAddress 0.0.0.0 -EndIpAddress 255.255.255.255

        $passwordassecurestring = ConvertTo-SecureString -String $ServerAdminPassword -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($ServerAdminUsername, $passwordassecurestring)

        $servercontext = New-AzureSqlDatabaseServerContext -ServerName $server.ServerName -Credential $credential
        $storagecontext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
        $container = Get-AzureStorageContainer -Name $StorageAccountContainer -Context $storagecontext
        $operation = Start-AzureSqlDatabaseImport -SqlConnectionContext $servercontext -StorageContainer $container -DatabaseName $DatabaseName -BlobName $StorageAccountBlobName
               
        $startedimport = Get-Date

        do {
            Start-Sleep -Seconds 10
            $requeststatus = Get-AzureSqlDatabaseImportExportStatus -Username $ServerAdminUsername -Password $ServerAdminPassword -ServerName $server.ServerName -RequestId $operation.RequestGuid
            Write-Output $requeststatus

            $currenttime = Get-Date
            $currentduration = $currenttime - $startedimport
            Write-Output "Import has been running for $($currentduration.TotalMinutes) minutes."

        } while ($requeststatus.Status.StartsWith("Running"))

        $finishedimport = Get-Date
        $duration = $finishedimport - $startedimport
        Write-Output "Total Minutes was $($duration.TotalMinutes) minutes."
    }
}

Export-ModuleMember -Function Test-AzureSqlDatabaseImportPerformance