-- SQL Server'da aktif kullanıcı oturumlarını listeler ve filtrelenen bilgileri öğrenebilirsiniz.
SELECT 
    login_name,
    login_time,
    host_name,
    program_name,
    client_interface_name
FROM 
    sys.dm_exec_sessions
WHERE 
    is_user_process = 1
ORDER BY 
    login_time DESC;
