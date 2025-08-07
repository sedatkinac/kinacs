# Hedef adresler burada örnek amaçlı aşağıdaki adresleri ekledim, Gereksinim duyulan adresler ile değiştirin.
# Örnek olarak gib.gov.tr , https://localhost:8543/ / E-fatura iptal java erişimi linki vb.

$sites = @(
    "http://localhost:8084",
    "http://127.0.0.1:8080",
    "http://192.168.1.10:8080"
)

# Exception Site List dosya yolu
$exceptionSiteFile = "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"

# Gerekli klasör varsa oluştur
$dir = Split-Path $exceptionSiteFile
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force
}

# Dosya yoksa oluştur, varsa sadece eksik adresleri ekle
if (-not (Test-Path $exceptionSiteFile)) {
    Set-Content -Path $exceptionSiteFile -Value $sites
} else {
    $existing = Get-Content $exceptionSiteFile
    foreach ($site in $sites) {
        if ($existing -notcontains $site) {
            Add-Content -Path $exceptionSiteFile -Value $site
        }
    }
}

Write-Output "Java Exception Site List güncellendi, erişim deneyebilirsiniz: $exceptionSiteFile"
