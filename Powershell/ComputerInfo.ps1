# Konsol ekranını temizle ve metin rengini yeşil yap
Clear-Host
[System.Console]::ForegroundColor = "Green"

# --- BAŞLIK ---
Write-Host "========================================================================"
Write-Host "*** WINDOWS BİLGİ VE LİSANS SORGULAMA ARACI ***"
Write-Host "========================================================================"
Write-Host

# --- GENEL SİSTEM BİLGİLERİ ---
Write-Host "*** GENEL SİSTEM BİLGİLERİ ***"

# Gerekli sistem bilgilerini tek seferde çekerek performansı artır
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$processor = Get-CimInstance -ClassName Win32_Processor
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Bilgileri formatlı bir şekilde yazdır
Write-Host ("{0,-20}: {1}" -f "Bilgisayar Adı", $env:COMPUTERNAME)
Write-Host ("{0,-20}: {1}" -f "Aktif Kullanıcı", $env:USERNAME)
Write-Host ("{0,-20}: {1}" -f "Seri Numarası", $bios.SerialNumber)
Write-Host ("{0,-20}: {1}" -f "Marka/Üretici", $computerSystem.Manufacturer)
Write-Host ("{0,-20}: {1}" -f "Model", $computerSystem.Model)
Write-Host ("{0,-20}: {1}" -f "İşlemci", $processor.Name)
Write-Host ("{0,-20}: {1} GB" -f "Yüklü RAM", ([Math]::Round($computerSystem.TotalPhysicalMemory / 1GB)))

# RAM Slot Bilgileri
try {
    $ramSlots = Get-CimInstance -ClassName Win32_PhysicalMemoryArray | Select-Object -ExpandProperty MemoryDevices
    $doluSlots = (Get-CimInstance -ClassName Win32_PhysicalMemory).Count
    $bosSlots = $ramSlots - $doluSlots
    Write-Host ("{0,-20}: Toplam: {1}, Dolu: {2}, Boş: {3}" -f "RAM Slotları", $ramSlots, $doluSlots, $bosSlots)
} catch {
    Write-Host ("{0,-20}: {1}" -f "RAM Slotları", "Bilgi alınamadı.")
}
Write-Host

# --- RAM MODÜLLERİ ---
Write-Host "*** RAM MODÜLLERİ (HIZ) ***"
$ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object BankLabel, @{N="Boyut";E={[Math]::Round($_.Capacity / 1GB)}}, Speed
if ($ramModules) {
    # Başlıkları yazdır
    Write-Host ("{0,-15} {1,-10} {2}" -f "BANK", "BOYUT (GB)", "HIZ (MHz)")
    Write-Host ("-"*40)
    # Her bir RAM modülü için bilgileri yazdır
    foreach ($module in $ramModules) {
        Write-Host ("{0,-15} {1,-10} {2}" -f $module.BankLabel, $module.Boyut, $module.Speed)
    }
} else {
    Write-Host "RAM modül bilgileri bulunamadı."
}
Write-Host

# --- DİSK BİLGİSİ ---
Write-Host "*** DİSK BİLGİSİ ***"
$disks = Get-PhysicalDisk | Select-Object FriendlyName, @{N="Boyut";E={[Math]::Round($_.Size / 1GB)}}, MediaType, BusType
if ($disks) {
    # Başlıkları yazdır
    Write-Host ("{0,-30} {1,-10} {2}" -f "Disk Adı", "BOYUT (GB)", "TİP/ARAYÜZ")
    Write-Host ("-"*60)
    # Her bir disk için bilgileri yazdır
    foreach ($disk in $disks) {
        Write-Host ("{0,-30} {1,-10} {2} ({3})" -f $disk.FriendlyName, $disk.Boyut, $disk.MediaType, $disk.BusType)
    }
} else {
    Write-Host "Fiziksel disk bilgileri bulunamadı."
}
Write-Host

# --- ETKİ ALANI BİLGİSİ ---
Write-Host "*** ETKİ ALANI BİLGİSİ ***"
$domainInfo = $computerSystem.PartOfDomain
if ($domainInfo) {
    Write-Host ("{0,-20}: {1}" -f "Etki Alanı Durumu", "DOMAIN")
    Write-Host ("{0,-20}: {1}" -f "Etki Alanı Adı", $computerSystem.Domain)
} else {
    Write-Host ("{0,-20}: {1}" -f "Etki Alanı Durumu", "WORKGROUP")
    Write-Host ("{0,-20}: {1}" -f "Çalışma Grubu Adı", $computerSystem.Domain) # Domain değilse bu özellik Workgroup adını tutar
}
Write-Host ("{0,-20}: {1}" -f "İşletim Sistemi", $os.Caption)
Write-Host

# --- WINDOWS LİSANS BİLGİSİ ---
Write-Host "*** WINDOWS LİSANS BİLGİSİ ***"
try {
    # Sadece Windows işletim sistemine ait, aktif ve kısmi anahtarı olan lisansı bul
    $license = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.Name -like "Windows*" -and $_.PartialProductKey -and $_.LicenseStatus -eq 1 } | Select-Object -First 1

    if ($license) {
        # Lisans durumunu metne çevir
        $licenseStatusText = switch ($license.LicenseStatus) {
            0 {"Lisanssız (Unlicensed)"}
            1 {"Lisanslı (Licensed)"}
            2 {"İlk Kullanım Süresinde (In Grace Period)"}
            3 {"İlk Kullanım Süresi Dolmuş (Grace Period Expired)"}
            4 {"Bildirimde (Notification)"}
            5 {"Uzatılmış İlk Kullanım (Extended Grace)"}
            default {"Bilinmiyor"}
        }

        Write-Host ("{0,-23}: {1}" -f "Ad", $license.Name)
        Write-Host ("{0,-23}: {1}" -f "Açıklama", $license.Description)
        Write-Host ("{0,-23}: {1}" -f "Kısmi Ürün Anahtarı", $license.PartialProductKey)
        Write-Host ("{0,-23}: {1}" -f "Lisans Durumu", $licenseStatusText)
    } else {
        Write-Host "Aktif Windows lisans bilgisi bulunamadı."
    }
} catch {
    Write-Host "Lisans bilgileri alınırken bir hata oluştu: $($_.Exception.Message)"
}
Write-Host

# --- BİTİŞ ---
Write-Host "========================================================================"
Write-Host "Bilgiler görüntülenmiştir. Kapatmak için bir tuşa basın..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Konsol rengini varsayılana döndür
[System.Console]::ResetColor()