# Generates a JKS keystore for signing the Android release build.
#
# Privacy: this script asks you for company details and nothing else. It does
# NOT read your username, machine name, IP address, location, or any other
# system information, and it does NOT auto-fill any field. Every value in the
# certificate comes only from what you type.
#
# Requirements: a JDK on PATH (provides `keytool`). Check with: keytool -help
#
# Output:
#   - starcart-upload.jks          (the keystore - keep it safe, never commit)
#   - starcart-keystore-base64.txt (base64 of the keystore for GitHub Secrets)

$ErrorActionPreference = "Stop"

function Read-Required([string]$Prompt) {
    while ($true) {
        $value = Read-Host $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) { return $value.Trim() }
        Write-Host "  This field is required." -ForegroundColor Yellow
    }
}

function Read-Secret([string]$Prompt) {
    while ($true) {
        $secure = Read-Host $Prompt -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        if ($plain.Length -lt 6) {
            Write-Host "  Use at least 6 characters." -ForegroundColor Yellow
            continue
        }
        return $plain
    }
}

Write-Host ""
Write-Host "=== Brass & Starlight Android signing keystore generator ===" -ForegroundColor Cyan
Write-Host "Enter your company details. Nothing is read from your system." -ForegroundColor DarkGray
Write-Host ""

# Company details only (6 distinct fields for the certificate dname).
$companyName = Read-Required "Company / app publisher name (CN)"
$orgUnit     = Read-Required "Organizational unit, e.g. Mobile (OU)"
$org         = Read-Required "Organization / legal entity (O)"
$city        = Read-Required "City / locality (L)"
$state       = Read-Required "State / province (ST)"
$country     = Read-Required "Two-letter country code, e.g. US (C)"

Write-Host ""
$alias       = Read-Required "Key alias, e.g. starcart-upload"
[int]$validity = Read-Required "Validity in days (>= 10000 recommended)"

Write-Host ""
$storePass   = Read-Secret "Keystore (store) password"
$keyPass     = Read-Secret "Key password"

$dname = "CN=$companyName, OU=$orgUnit, O=$org, L=$city, ST=$state, C=$country"
$keystorePath = Join-Path $PSScriptRoot "starcart-upload.jks"
$base64Path   = Join-Path $PSScriptRoot "starcart-keystore-base64.txt"

if (Test-Path $keystorePath) {
    Remove-Item $keystorePath -Force
}

Write-Host ""
Write-Host "Generating keystore..." -ForegroundColor Cyan

& keytool -genkeypair -v `
    -keystore $keystorePath `
    -storetype JKS `
    -keyalg RSA `
    -keysize 2048 `
    -validity $validity `
    -alias $alias `
    -dname $dname `
    -storepass $storePass `
    -keypass $keyPass

if ($LASTEXITCODE -ne 0) {
    throw "keytool failed (exit $LASTEXITCODE). Is a JDK installed and on PATH?"
}

$bytes = [IO.File]::ReadAllBytes($keystorePath)
[IO.File]::WriteAllText($base64Path, [Convert]::ToBase64String($bytes))

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  Keystore : $keystorePath" -ForegroundColor Green
Write-Host "  Base64   : $base64Path" -ForegroundColor Green
Write-Host ""
Write-Host "Add these GitHub repository secrets (Settings -> Secrets and variables -> Actions):" -ForegroundColor Cyan
Write-Host "  STARCART_KEYSTORE_BASE64  = contents of starcart-keystore-base64.txt"
Write-Host "  STARCART_STORE_PASSWORD   = the keystore (store) password you entered"
Write-Host "  STARCART_KEY_ALIAS        = $alias"
Write-Host "  STARCART_KEY_PASSWORD     = the key password you entered"
Write-Host ""
Write-Host "Keep starcart-upload.jks and the passwords safe and OFFLINE." -ForegroundColor Yellow
Write-Host "Both generated files are git-ignored - never commit them." -ForegroundColor Yellow
