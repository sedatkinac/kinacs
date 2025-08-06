#SMTP kontrolü için kullanılabilir.
#info@smtp.com yerine gönderim test edilecek e-mail adresi
#to@smtp.com yerine hangi adrese mail gönderimi yapılacak ise o yazılır.
#smtp_adresi kısmına SMTP sunucu ve port bilgisi yazılır burada port 25 olarak test edildi.

$SMTPClient = New-Object Net.Mail.SmtpClient("smtp_adresi", 25)
$SMTPClient.Send("info@smtp.com", "to@smtp.com", "Test Mail", "Bu bir test e-postasıdır.")