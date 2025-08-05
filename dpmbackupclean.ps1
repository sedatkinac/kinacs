# Protection Group bazlı saklama süreleri (gün cinsinden)
$RetentionPolicy = @{
    "Protection Group Name"   = 14
    

}

# Tüm Protection Group'ları al
$protectionGroups = Get-ProtectionGroup

# Protection Group bazlı işlemler
foreach ($pg in $protectionGroups) {
    $pgName = $pg.FriendlyName

    # Eğer bu PG için retention süresi tanımlı değilse atla
    if (-not $RetentionPolicy.ContainsKey($pgName)) {
        Write-Host "Skipping $pgName - No retention policy defined."
        continue
    }

    # Bu Protection Group için yedek saklama süresi
    $backupDateCutoff = (Get-Date).AddDays(-$RetentionPolicy[$pgName])

    Write-Host "Processing $pgName - Retention Cutoff: $backupDateCutoff"

    # Datasource'ları al
    $datasources = Get-Datasource -ProtectionGroup $pg

    foreach ($ds in $datasources) {
        # Recovery Point'leri al
        $recoveryPoints = Get-RecoveryPoint -Datasource $ds

        foreach ($recovery in $recoveryPoints) {
            if ($recovery.BackupTime -le $backupDateCutoff) {
                Write-Host "Removing Recovery Point: $($recovery.BackupTime) for $($ds.Name)"
                Remove-RecoveryPoint -RecoveryPoint $recovery -Confirm:$false
            }
        }
    }
}

# DPM sunucusundan bağlantıyı kes
Disconnect-DPMServer
