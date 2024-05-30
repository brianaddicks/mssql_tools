function Get-MssqlNodeHealth {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, Position = 0)]
        [int]$DatabaseSyncStateInterval = 30,

        [Parameter(Mandatory = $false, Position = 1)]
        [int]$DatabaseSyncStateRetries = 20
    )

    $FullOutput = @()

    $Hostname = $env:COMPUTERNAME

    $SQLInstances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances

    foreach ($sql in $SQLInstances) {
        if ($sql -eq 'MSSQLSERVER') {
            $SqlInstanceFullName = $Hostname
            $SqlProviderAGPath = 'SQLSERVER:\SQL\' + $Hostname + '\DEFAULT\AvailabilityGroups'
        }
        else {
            $SqlInstanceFullName = "$Hostname\$sql"
            $SqlProviderAGPath = 'SQLSERVER:\SQL\' + $Hostname + '\' + $sql + '\AvailabilityGroups'
        }

        $SqlQueryParams = @{}
        $SqlQueryParams.Query = "select DISTINCT value_data AS Port from sys.dm_server_registry WHERE value_name = 'TcpPort'"
        $SqlQueryParams.ServerInstance = $SqlInstanceFullName
        $SqlQueryParams.ErrorAction = 'SilentlyContinue'
        $SqlQueryParams.TrustServerCertificate = $true

        $TcpPort = Invoke-Sqlcmd @SqlQueryParams

        # Get AGs
        $SqlAGs = Get-ChildItem -Path $SqlProviderAGPath

        foreach ($ag in $SqlAGs) {
            $ThisOutput = '' | Select-Object ServerName, InstanceName, TcpPort, AvailabilityGroup, PrimaryReplica, AvailabilityMode, ReplicaStatus, Retries
            $NewOutput = @()
            $ThisOutput.ServerName = $Hostname
            $ThisOutput.InstanceName = $sql

            if ($TcpPort) {
                $TcpPort = [int]($TcpPort.port)
            }
            else {
                $TcpPort = $false
            }

            $ThisOutput.AvailabilityGroup = $ag.Name
            $ThisOutput.PrimaryReplica = $ag.PrimaryReplicaServerName
        }

        # Get replica servers, availability mode, failovermode
        $SqlQueryParams.Query = @"
            IF SERVERPROPERTY ('IsHadrEnabled') = 1
            BEGIN
            SELECT
            ag.name,
            drs.replica_server_name,
            drs.availability_mode_desc,
            drs.failover_mode_desc
            FROM sys.availability_replicas drs,
            sys.availability_groups ag
            WHERE drs.group_id = ag.group_id AND ag.name LIKE '$($ThisOutput.AvailabilityGroup)';

            END
"@

        $SqlOutputAvailabilityMode = Invoke-Sqlcmd @SqlQueryParams
        $ThisOutput.AvailabilityMode = $SqlOutputAvailabilityMode

        $SqlQueryParams.Query = @"
            select
            ag.name,
            ar.replica_server_name,
            ar.availability_mode_desc as [availability_mode],
            ars.synchronization_health_desc as replica_sync_state,
            rcs.database_name,
            drs.synchronization_state_desc as db_sync_state
            from sys.dm_hadr_database_replica_cluster_states as rcs
            join sys.availability_replicas as ar
            on ar.replica_id = rcs.replica_id
            join sys.dm_hadr_availability_replica_states as ars
            on ars.replica_id = ar.replica_id
            join sys.dm_hadr_database_replica_states as drs
            on drs.group_database_id = rcs.group_database_id
            and drs.replica_id = ar.replica_id
            join sys.availability_groups as ag
            on ag.group_id = ar.group_id
            where drs.synchronization_state_desc <> '' and ag.name like '$($ThisOutput.AvailabilityGroup)';
"@

        $ReplicaStatus = Invoke-Sqlcmd @SqlQueryParams
        $DatabaseNotSynced = $ReplicaStatus | Where-Object { $_.db_sync_state -ne 'SYNCHRONIZED' }
        $CurrentAttempt = 0
        do {
            $CurrentAttempt++
            Start-Sleep -Seconds $DatabaseSyncStateInterval
            $ReplicaStatus = Invoke-Sqlcmd @SqlQueryParams
            $DatabaseNotSynced = $ReplicaStatus | Where-Object { $_.db_sync_state -ne 'SYNCHRONIZED' }
        } while ($DatabaseNotSynced.Count -gt 0 -and $CurrentAttempt -lt $DatabaseSyncStateRetries)

        $ThisOutput.ReplicaStatus = $ReplicaStatus
        $ThisOutput.Retries = $CurrentAttempt

        foreach ($amEntry in $SqlOutputAvailabilityMode) {
            foreach ($rsEntry in $ReplicaStatus) {
                if ($rsEntry.replica_server_name -ne $amEntry.replica_server_name) { continue }
                $ThisEntry = '' | Select-Object ServerName, InstanceName, TcpPort, AvailabilityGroup, ReplicaRole, AvailabilityMode, FailoverMode, ReplicaSyncStatus, DatabaseName, DatabaseSyncStatus
                $ThisEntry.ServerName = $amEntry.replica_server_name
                $ThisEntry.InstanceName = $sql
                $ThisEntry.AvailabilityGroup = $ag.Name
                $ThisEntry.TcpPort = $TcpPort

                if ($amEntry.replica_server_name -eq $ag.PrimaryReplicaServerName) {
                    $ThisEntry.ReplicaRole = 'PrimaryReplica'
                } else {
                    $ThisEntry.ReplicaRole = 'SecondaryReplica'
                }

                $ThisEntry.AvailabilityMode = $amEntry.availability_mode_desc
                $ThisEntry.FailoverMode = $amEntry.failover_mode_desc

                $ThisEntry.ReplicaSyncStatus = $rsEntry.replica_sync_state
                $ThisEntry.DatabaseName = $rsEntry.database_name
                $ThisEntry.DatabaseSyncStatus = $rsEntry.db_sync_state

                $NewOutput += $ThisEntry
            }
        }

        # add to output array
        $FullOutput += $ThisOutput
    }

    $NewOutput
}
