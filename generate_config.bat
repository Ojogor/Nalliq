@echo off
echo Generating google-services.json from template...
dart run scripts/generate_google_services.dart
if %ERRORLEVEL% EQU 0 (
    echo Google services configuration generated successfully!
) else (
    echo Failed to generate google services configuration!
    exit /b 1
)
