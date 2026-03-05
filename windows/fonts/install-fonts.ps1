# Install fonts for code editing
# Requires: Scoop (https://scoop.sh/)
# Run as Administrator for Windows versions before 1809

$ErrorActionPreference = "Stop"

Write-Host "[INFO] Installing fonts for VS Code..." -ForegroundColor Cyan

# Check if Scoop is installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Scoop is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "        irm get.scoop.sh | iex" -ForegroundColor Yellow
    exit 1
}

Write-Host "[INFO] Scoop found. Proceeding with installation..." -ForegroundColor Green

# Add nerd-fonts bucket if not already added
$buckets = scoop bucket list
if ($buckets -notmatch "nerd-fonts") {
    Write-Host "[INFO] Adding nerd-fonts bucket..." -ForegroundColor Cyan
    scoop bucket add nerd-fonts
}

# Original fonts (without Nerd Fonts patch) - from main bucket
$originalFonts = @(
    "firacode",
    "JetBrains-Mono",
    "Cascadia-Code"
)

# Nerd Fonts (with icons) - from nerd-fonts bucket
$nerdFonts = @(
    "FiraCode-NF",
    "JetBrainsMono-NF", 
    "CascadiaCode-NF"
)

Write-Host ""
Write-Host "[INFO] Installing original fonts (clean versions)..." -ForegroundColor Cyan
foreach ($font in $originalFonts) {
    Write-Host "[INFO] Installing $font..." -ForegroundColor Cyan
    scoop install $font
}

Write-Host ""
Write-Host "[INFO] Installing Nerd Fonts (with icons for terminals)..." -ForegroundColor Cyan
foreach ($font in $nerdFonts) {
    Write-Host "[INFO] Installing $font..." -ForegroundColor Cyan
    scoop install $font
}

Write-Host ""
Write-Host "[SUCCESS] All fonts installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Installed fonts:" -ForegroundColor White
Write-Host ""
Write-Host "  Original (clean):" -ForegroundColor White
Write-Host "    - Fira Code" -ForegroundColor White
Write-Host "    - JetBrains Mono" -ForegroundColor White
Write-Host "    - Cascadia Code" -ForegroundColor White
Write-Host ""
Write-Host "  Nerd Fonts (with icons):" -ForegroundColor White
Write-Host "    - Fira Code NF" -ForegroundColor White
Write-Host "    - JetBrains Mono NF" -ForegroundColor White
Write-Host "    - Cascadia Code NF" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart VS Code to detect the new fonts" -ForegroundColor Yellow
Write-Host "  2. Fonts are configured in settings/fragments/10-editor.json" -ForegroundColor Yellow
Write-Host "  3. See docs/FONTS.md for more information" -ForegroundColor Yellow
