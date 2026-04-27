@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0generate_legitimate_traffic.ps1" %*
