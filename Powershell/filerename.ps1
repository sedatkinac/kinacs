# Kullanıcı arayüzünü temizle
Clear-Host

# Betiğin amacını açıklayan bir başlık yazdır
Write-Host "PowerShell Dosya Uzantısı Değiştirme Aracı" -ForegroundColor Yellow
Write-Host "------------------------------------------"

# Kullanıcıdan dosyanın tam yolunu iste
$dosyaYolu = Read-Host "Lütfen uzantısını değiştirmek istediğiniz dosyanın tam yolunu girin (örneğin, C:\belgeler\rapor.txt)"

# Kullanıcıdan yeni uzantıyı iste
$yeniUzantı = Read-Host "Lütfen yeni dosya uzantısını girin (BAŞINDA NOKTA OLMADAN, örneğin, log, docx, vb.)"

# --- DOĞRULAMA ALANI ---

# 1. Kullanıcının bir dosya yolu veya yeni uzantı girip girmediğini kontrol et
if ([string]::IsNullOrWhiteSpace($dosyaYolu) -or [string]::IsNullOrWhiteSpace($yeniUzantı)) {
    Write-Host "Hata: Dosya yolu veya yeni uzantı alanı boş bırakılamaz." -ForegroundColor Red
    # Betiği sonlandır
    return
}

# 2. Belirtilen yolda bir dosyanın var olup olmadığını kontrol et
#    -PathType Leaf parametresi, bunun bir klasör değil, bir dosya olduğunu garanti eder.
if (-not (Test-Path -Path $dosyaYolu -PathType Leaf)) {
    Write-Host "Hata: '$dosyaYolu' adresinde bir dosya bulunamadı veya bu bir klasör." -ForegroundColor Red
    # Betiği sonlandır
    return
}


#  İŞLEM ALANI

try {
    # Kullanıcının yeni uzantının başına nokta koyma ihtimaline karşı temizle
    $yeniUzantı = $yeniUzantı.TrimStart('.')

    # Dosyanın bulunduğu dizini al
    $dizin = Split-Path -Path $dosyaYolu

    # Dosyanın mevcut uzantısı olmadan adını al
    $temelAd = [System.IO.Path]::GetFileNameWithoutExtension($dosyaYolu)

    # Yeni dosya adını oluştur (temel ad + . + yeni uzantı)
    $yeniAd = "$temelAd.$yeniUzantı"

    # Yeniden adlandırma işlemini gerçekleştir
    Rename-Item -Path $dosyaYolu -NewName $yeniAd -ErrorAction Stop

    # Başarı mesajını göster
    Write-Host "İşlem Başarıyla Tamamlandı!" -ForegroundColor Green
    Write-Host "Dosyanın yeni adı: $yeniAd"
    Write-Host "Yeni tam yol: $(Join-Path -Path $dizin -ChildPath $yeniAd)"

} catch {
    # Yeniden adlandırma sırasında bir hata oluşursa yakala ve göster
    Write-Host "Beklenmedik bir hata oluştu:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}