-- SQL Server'da MSDB veritabanındaki backupset tablosunu kullanarak her veritabanı için en son tam yedekleme (Full Backup) tarihini listeler.

SELECT 
    database_name,
    MAX(backup_finish_date) AS LastFullBackupDate
FROM 
    msdb.dbo.backupset
WHERE 
    type = 'D'  -- D = Full Backup
GROUP BY 
    database_name
ORDER BY 
    LastFullBackupDate DESC;