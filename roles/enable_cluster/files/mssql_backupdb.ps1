function Backup-MssqlDatabase {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Hostname,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Instance,

        [Parameter(Mandatory = $true, Position = 2)]
        [string[]]$Database,

        [Parameter(Mandatory = $true, Position = 3)]
        [string]$BackupFolder
    )

    Import-Module SqlServer

    if ($Instance -eq 'MSSQLSERVER') {
        $FullInstanceName = "$Hostname\DEFAULT"
    } else {
        $FullInstanceName = "$Hostname\$Instance"
    }

    Set-Location "SQLSERVER:\SQL\$FullInstanceName"

    foreach ($db in $Database) {
        Backup-SqlDatabase -Database $db -BackupFile "$BackupFolder\full\$db.bak" -Verbose
        Backup-SqlDatabase -Database $db -BackupAction Log -BackupFile "$BackupFolder\log\$db.trn" -Verbose
    }
}
