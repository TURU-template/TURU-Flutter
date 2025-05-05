@echo off
REM This script helps start the Turu Java API with Aiven database connection

REM Check if .env file exists and load variables (requires findstr)
if exist .env (
  echo Loading environment variables from .env file
  for /f "tokens=*" %%a in ('findstr /v "^#" .env') do (
    set %%a
  )
) else (
  echo No .env file found. Using default values or system environment variables.
)

REM Print connection info (without password)
echo Starting Turu API with the following database connection:
echo Host: %DB_HOST%
echo Port: %DB_PORT%
echo Database: %DB_NAME%
echo Username: %DB_USER%

REM Run the Spring Boot application
mvnw.cmd spring-boot:run 