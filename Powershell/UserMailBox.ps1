$kullanicilar = Get-Content -Path "C:\temp\deleteusertest.txt"
$hatalar = @()

Write-Host "Toplu silme işlemi başlıyor..." -ForegroundColor Yellow

foreach ($user in $kullanicilar) {
    if (-not [string]::IsNullOrWhiteSpace($user)) {
        try {
            Write-Host "İşlem yapılıyor: $user"
            Remove-Mailbox -Identity $user -Confirm:$false -ErrorAction Stop
            Write-Host "BAŞARILI: $user posta kutusu ve AD hesabı silindi." -ForegroundColor Green
        }
        catch {
            Write-Warning "HATA: $user silinemedi. Detay: $($_.Exception.Message)"
            $hatalar += "Kullanıcı: $user - Hata: $($_.Exception.Message)"
        }
    }
}

Write-Host "İşlem tamamlandı." -ForegroundColor Yellow

if ($hatalar.Count -gt 0) {
    Write-Host "Hata alınan kullanıcılar:" -ForegroundColor Red
    $hatalar | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    $hatalar | Out-File -FilePath "C:\temp\silme_hatalari.txt" -Encoding UTF8
}