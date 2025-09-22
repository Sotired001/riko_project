# Pre-commit hook: quick secret scan (PowerShell)
# Scans staged files for private key headers or likely AWS keys

param()

# Get staged files
$files = git diff --cached --name-only
if (-not $files) { exit 0 }

$fail = $false
foreach ($f in $files) {
    if (-not (Test-Path $f)) { continue }
    $content = Get-Content $f -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    if ($content -match '-----BEGIN (RSA|OPENSSH|EC|DSA|PRIVATE) KEY') {
        Write-Host "ERROR: Possible private key in staged file: $f" -ForegroundColor Red
        $fail = $true
    }
    if ($content -match 'AKIA[0-9A-Z]{16}') {
        Write-Host "ERROR: Possible AWS access key in staged file: $f" -ForegroundColor Red
        $fail = $true
    }
    if ($content -match '\b(password|secret|token)\b[:=]') {
        Write-Host "WARN: possible credential-like token in $f" -ForegroundColor Yellow
    }
}

if ($fail) {
    Write-Host "Pre-commit checks failed. Remove secrets before committing or use git-secret to encrypt." -ForegroundColor Red
    exit 1
}
exit 0
