Set-Location -LiteralPath $PSScriptRoot

$pythonCandidates = @(
	(Join-Path $PSScriptRoot ".venv-py311\Scripts\python.exe"),
	(Join-Path $PSScriptRoot "..\.venv\Scripts\python.exe")
)
$pythonExecutable = $pythonCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $pythonExecutable) {
	$pythonExecutable = "python"
}

& $pythonExecutable -m uvicorn --app-dir . app.main:app --reload --host 0.0.0.0 --port 8000
