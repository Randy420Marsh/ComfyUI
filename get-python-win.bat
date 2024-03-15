@echo off
setlocal

set ZIP_URL=https://github.com/Randy420Marsh/cpython/releases/download/v3.10.13/python-3.10.13-embed-amd64.zip
set ZIP_FILENAME=python-3.10.13-embed-amd64.zip
set EXTRACT_FOLDER=python-3.10.13-embed-amd64
set CHECKSUM=6c999e7f7c10e30f0270bc780a56ceea001d216035f16aa2704a795127d09df7

if not exist "%ZIP_FILENAME%" (
    echo File "%ZIP_FILENAME%" not found. Downloading...
    powershell -command "& {Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILENAME%'}"
)

if exist "%ZIP_FILENAME%" (
    echo Verifying checksum...
    powershell -command "& {Get-FileHash -Path '%ZIP_FILENAME%' -Algorithm SHA256 | ForEach-Object {if ($_.Hash -eq '%CHECKSUM%') {exit 0} else {exit 1}}}"
    if %errorlevel% equ 0 (
        echo Checksum verified. Extracting...
        powershell -command "& {Expand-Archive -Path '%ZIP_FILENAME%' -DestinationPath '%EXTRACT_FOLDER%'}"
        echo Extraction complete.
    ) else (
        echo Checksum mismatch. Deleting the file.
        del "%ZIP_FILENAME%"
    )
)

endlocal
pause