function Set-MssqlPrimaryReplica {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AvailabilityGroup
    )

    Import-Module SqlServer

    $SqlQueryParams = @{}
    $SqlQueryParams.Query = "ALTER AVAILABILITY GROUP $AvailabilityGroup FAILOVER;"
    $SqlQueryParams.ServerInstance = 'localhost'
    $SqlQueryParams.TrustServerCertificate = $true

    Invoke-Sqlcmd @SqlQueryParams
}
