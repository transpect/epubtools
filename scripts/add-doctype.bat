@echo off

if "%~1"=="" (
    echo Usage: %0 ^<file-path^>
    exit /b 1
)

set "rawPath=%~1"

set "filePath=%rawPath:file:///=%"

set "filePath=%filePath:/=\%"

if not exist "%filePath%" (
    echo Error: File "%filePath%" does not exist.
    exit /b 1
)

set "tempFile=%~dpn1_tmp_prepend_file.txt"

(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<^!DOCTYPE html^>
) > "%tempFile%"

type "%filePath%" >> "%tempFile%"
if errorlevel 1 (
    echo Failed to read the original file.
    del "%tempFile%"
    exit /b 1
)

move /Y "%tempFile%" "%filePath%" >nul

echo DOCTYPE successfully added to "%filePath%"

