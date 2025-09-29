# Modül Yüklenir
Import-Module ADSync

# Mevcut durum görüntüleme için
Get-ADSyncScheduler

#Sync çıktı örnek

PS C:\Windows\system32> Get-ADSyncScheduler


AllowedSyncCycleInterval            : 00:30:00
CurrentlyEffectiveSyncCycleInterval : 00:30:00
CustomizedSyncCycleInterval         :
NextSyncCyclePolicyType             : Delta
NextSyncCycleStartTimeInUTC         : 9/29/2025 12:51:47 PM
PurgeRunHistoryInterval             : 7.00:00:00
SyncCycleEnabled                    : True
MaintenanceEnabled                  : True
StagingModeEnabled                  : False
SchedulerSuspended                  : False
SyncCycleInProgress                 : False

#Sync başlatmak için
Start-ADSyncSyncCycle -PolicyType Delta

#Çıktı

 Result
 ------
Success



