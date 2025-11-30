@echo off
@rem Batch script to package mod, deploy mod, and run Enshrouded

@set steamAppId=1203620

@rem Get the mod name from the parent folder
@for /f "delims=" %%a in ('powershell -Command "(get-item '%~f0').Directory.Parent.Name"') do @set name=%%a
@rem Get the mod version from the mod.json file
@for /f "delims=" %%a in ('powershell -Command "$file='%~dp0\..\mod.json'; $json = (Get-Content $file -Raw) | ConvertFrom-Json; $json.version;"') do @set version=%%a

@rem Prepare output folder
@rmdir /S /Q "%~dp0\..\.output"
@mkdir "%~dp0\..\.output\%name%"

@rem Copy necessary files to output folder
@xcopy /E /I /Y /Q "%~dp0\..\src\*" "%~dp0\..\.output\%name%\src" >nul 2>&1
@copy /Y "%~dp0\..\mod.json" "%~dp0\..\.output\%name%\mod.json" >nul 2>&1
@copy /Y "%~dp0\..\README.MD" "%~dp0\..\.output\%name%\README.MD" >nul 2>&1

@rem Create the zip file if 7zip is available
@rem Get the path to 7-Zip executable
@del /F /Q "%~dp0\..\.output\%name%-%version%.zip" >nul 2>&1
@for /f "delims=" %%a in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Get-7ZipExePath.ps1"') do @set "sevenZipExePath=%%a"
if "%sevenZipExePath%"=="" (
    @echo "7-Zip executable not found. Please ensure 7-Zip is installed."
) else (
    @rem uses 7zip as works with factorio whereas compress does not
    @"%sevenZipExePath%" a -tzip -bb0 -bso0 -bsp0 -y -aoa -o"%~dp0\..\.output" "%~dp0\..\.output\%name%-%version%.zip" "%~dp0\..\.output\%name%"
)

@rem Deploy to game mods folder
@rem Get the Steam game path
@for /f "delims=" %%a in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Get-SteamGamePath.ps1" -AppID %steamAppId%') do @set "steamGamePath=%%a"
@rmdir /S /Q "%steamGamePath%\Mods\%name%"
@xcopy /E /I /Y "%~dp0\..\.output\%name%" "%steamGamePath%\Mods\%name%"

@rem Launch the game
@for /f "delims=" %%a in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Get-SteamExePath.ps1"') do @set "steamExePath=%%a"
@start "" "%steamExePath%" -applaunch %steamAppId%
