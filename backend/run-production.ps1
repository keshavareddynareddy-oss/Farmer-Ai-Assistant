Set-Location -LiteralPath $PSScriptRoot

$python = Join-Path $PSScriptRoot ".venv-py311\Scripts\python.exe"
if (-not (Test-Path $python)) {
    $python = "python"
}

& $python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1