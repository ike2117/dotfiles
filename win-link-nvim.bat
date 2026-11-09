@echo off
setlocal

rem Creates a junction at %LOCALAPPDATA%\nvim that points to the nvim folder
rem next to this script. Junctions do not need admin rights.
rem
rem Usage: win-link-nvim.bat [/nopause]
rem   /nopause   Do not wait for a key at the end. Use when calling from a script.

set "SOURCE=%~dp0nvim\.config\nvim"
set "TARGET=%LOCALAPPDATA%\nvim"
set "NOPAUSE="
if /i "%~1"=="/nopause" set "NOPAUSE=1"

if not exist "%SOURCE%\" set "MSG=Source folder not found: %SOURCE%" & goto :fail

rem If nvim is already a link, "dir /AL" lists it as: nvim [target path]
set "LINK_TARGET="
for /f "tokens=2 delims=[]" %%T in ('dir /AL "%LOCALAPPDATA%" 2^>nul ^| findstr /i /c:" nvim ["') do set "LINK_TARGET=%%T"

if /i "%LINK_TARGET%"=="%SOURCE%" echo Already linked, nothing to do. & goto :end
if defined LINK_TARGET set "MSG=%TARGET% is already a link to %LINK_TARGET%. Delete it and run again." & goto :fail
if exist "%TARGET%" set "MSG=%TARGET% already exists. Rename or remove it and run again." & goto :fail

mklink /J "%TARGET%" "%SOURCE%" && goto :end
set "MSG=Could not create the junction. Both folders must be on local NTFS drives."
goto :fail

:fail
rem Delayed expansion stops special characters in paths from breaking the echo.
setlocal EnableDelayedExpansion
>&2 echo Error: !MSG!
if not defined NOPAUSE pause
exit /b 1

:end
if not defined NOPAUSE pause
exit /b 0
