@echo off
powershell -ExecutionPolicy Bypass -Command "& {[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '%LOCALAPPDATA%\mpv-launcher\set-audio-device.ps1'}"
pause
