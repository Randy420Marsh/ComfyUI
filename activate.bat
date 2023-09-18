@echo off

SET current_path=%CD%

cd %current_path%

setlocal enabledelayedexpansion

set "PYTHON=C:\Python-3.10\PCbuild\amd64\python.exe"

IF exist ./venv (cmd /k call .\venv\scripts\activate.bat)  ELSE (cmd /k C:\Python-3.10\PCbuild\amd64\python.exe -m venv venv && cmd /k call .\venv\scripts\activate.bat)