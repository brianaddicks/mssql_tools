# Restore-SqlDatabase -Database "MyDB1" -BackupFile "\\share\backups\MyDB1.bak" -NoRecovery -ServerInstance "DestinationMachine\Instance"
# # Restore log backup
# Restore-SqlDatabase -Database "MyDB1" -BackupFile "\\share\backups\MyDB1.trn" -RestoreAction "Log" -NoRecovery -ServerInstance "DestinationMachine\Instance"

function Restore-MssqlDatabase {
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
        Restore-SqlDatabase -Database $db -NoRecovery -BackupFile "$BackupFolder\full\$db.bak" -Verbose
        Restore-SqlDatabase -Database $db -NoRecovery -RestoreAction Log -BackupFile "$BackupFolder\log\$db.trn" -Verbose
    }
}
