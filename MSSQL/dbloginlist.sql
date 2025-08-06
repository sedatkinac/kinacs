-- Server loginleri listele
PRINT '--- Server Logins ---'
SELECT 
    name, type_desc, create_date, modify_date
FROM 
    sys.server_principals
WHERE 
    type IN ('S', 'U', 'G')
ORDER BY name;

-- Tüm veritabanlarında kullanıcıları listele
DECLARE @dbName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR
SELECT name FROM sys.databases
WHERE state = 0 -- ONLINE olanlar

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = '
    PRINT ''--- Users in database: ' + QUOTENAME(@dbName) + ' ---'';
    USE ' + QUOTENAME(@dbName) + ';
    SELECT 
        DB_NAME() AS DatabaseName,
        name AS UserName,
        type_desc,
        create_date,
        modify_date
    FROM 
        sys.database_principals
    WHERE 
        type IN (''S'', ''U'', ''G'')
        AND name NOT LIKE ''##%'' -- Sistem kullanıcıları hariç
    ORDER BY name;
    ';
    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;