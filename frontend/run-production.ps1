Set-Location -LiteralPath $PSScriptRoot

if (-not $env:API_BASE_URL) {
    throw "Set API_BASE_URL before creating a production build."
}

flutter build web --release --dart-define="API_BASE_URL=$env:API_BASE_URL"