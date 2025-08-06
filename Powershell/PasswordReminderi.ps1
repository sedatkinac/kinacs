#Sedat Kınaç
# Kullanıcılara belirli periyodik aralıklarla şifrelerinin sürelerini değiştirme için hatırlatıcı bir scripttir.
# Burada kullanıcı SMTP bilgilerini, -SearchBase "OU=UserList,OU=Contoso,DC=contoso,DC=com" bilgilerini ve HTML ksımında mail içerisinde yazacak detayları değiştirebilir.
# Periyodik süreleri kendinize göre ayarlayabilirsiniz.


Write-Host "Adım 1: Kullanıcıları alıyorum..."
$users = Get-ADUser -Filter {Enabled -eq $True -and PasswordNeverExpires -eq $False -and PasswordLastSet -gt 0} -Properties "SamAccountName", "EmailAddress", "msDS-UserPasswordExpiryTimeComputed" -SearchBase "OU=UserList,OU=Contoso,DC=contoso,DC=com" -SearchScope Subtree | Select-Object -Property "SamAccountName", "EmailAddress", @{Name = "PasswordExpiry"; Expression = {[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | Where-Object {$_.EmailAddress}
# Şifre süresi dolma tarihini hesapla
$PasswordExpiry = [datetime]::FromFileTime($User.'msDS-UserPasswordExpiryTimeComputed')
$days = ($PasswordExpiry - (Get-Date)).Days

# Uyarı tarihi
$WarnDate = $PasswordExpiry.ToLongDateString().ToUpper()

Write-Host "Adım 2: Geri sayım..."
$SevenDayWarnDate    = (Get-Date).AddDays(7).ToLongDateString().ToUpper()
$ThreeDayWarnDate    = (Get-Date).AddDays(3).ToLongDateString().ToUpper()
$OneDayWarnDate      = (Get-Date).AddDays(1).ToLongDateString().ToUpper()


$MailSender = 'SMTP Mail adresi'
$SMTPServer = 'SMTP Server Adresi'
$SMTPPort   = 'SMTP Port'

Write-Host "Şifre Son Kullanım Tarihi: $PasswordExpiry"
Write-Host "Bugünün Tarihi: $(Get-Date)"
Write-Host "Kalan Gün: $days"

foreach ($user in $users) {
    $days = ($user.PasswordExpiry - (Get-Date)).Days
Write-Host "IF adımı 1"

if ($days -eq 7 -or $days -eq 3 -or $days -eq 1 ) {
    $SamAccount = $User.SamAccountName.ToUpper()
    $Subject    = "Şifre Süresi Hatırlatıcı $($SamAccount)"
    Write-Host "Adım 4-1: IF adımı"
    $EmailBody  = @"
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password is about to expire</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f9f9f9;
            color: #333;
            margin: 0;
            padding: 20px;
        }

        .container {
            background-color: #fff;
            border: 1px solid #ccc;
            border-radius: 8px;
            padding: 20px;
            max-width: 600px;
            margin: 0 auto;
        }

        h1 {
            color: #d9534f;
            text-align: center;
        }

        .email-content {
            background-color: #f7f7f7;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
        }

        .warning {
            color: #d9534f;
            font-weight: bold;
        }

        .info {
            color: #5bc0de;
        }

        .highlight {
            background-color: #ffeb3b;
            padding: 5px;
            font-weight: bold;
        }

        .footer {
            text-align: center;
            margin-top: 20px;
            font-size: 12px;
            color: #777;
        }

        .footer a {
            color: #5bc0de;
        }
    </style>
</head>
<body>

    <div class="container">
        <h1 style=color:#ff5a00 > IT Team </h1>

        <div class="email-content">
            
           
        
            <ul>
                   <li style="margin-bottom: 5px;"> <span class="highlight">$SamAccount</span> hesabının şifresi <span class="highlight">$days</span> gün içinde, <span class="highlight">$WarnDate</span> tarihinde süresi dolacaktır.</li>
                  <li style="margin-bottom: 5px;">Lütfen şifrenizi mümkün olan en kısa sürede güncelleyin.</li>                 
           
            </ul>
        </div>

        <p class="footer">In case of any doubt regarding the email, please contact the IT  team. </p>
        
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
</table>
       
    </div>

</body>

</html>

"@
Write-Host "mail adımı"
    try {
        $SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
        $SMTPClient.EnableSsl = $false  # Eğer SSL gerekiyorsa $true yap     
        $MailMessage = New-Object Net.Mail.MailMessage
        $MailMessage.From = $MailSender
        $MailMessage.To.Add($User.EmailAddress)
        $MailMessage.Subject = $Subject
        $MailMessage.Body = $EmailBody
        $MailMessage.IsBodyHtml = $true       
        $SMTPClient.Send($MailMessage)

        # Başarı mesajını dosyaya yaz
        $SuccessMessage = "E-posta gönderildi: $($User.EmailAddress) - $($PasswordExpiry)"
        Add-Content -Path "C:\Scripts\expire.txt" -Value "$SuccessMessage - $(Get-Date)"
    } catch {
        # Hata mesajını dosyaya yaz
        $ErrorMessage = "E-posta gönderilemedi: $($User.EmailAddress) - $($PasswordExpiry)"
        Add-Content -Path "C:\Scripts\expire.txt" -Value "$ErrorMessage - $(Get-Date)"
    }
}
}
