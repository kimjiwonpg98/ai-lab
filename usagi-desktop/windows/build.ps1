$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
python -m pip install -r windows/requirements.txt
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed' }
python -m PyInstaller --noconfirm --clean --windowed --onefile --name Meonjakgwi-Friends --add-data 'Assets;Assets' windows/main.py
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
