@echo off
chcp 65001 >nul
title BREBORN - Envio Automatico WhatsApp
cls
echo ============================================================
echo   BREBORN SALES HUB - ENVIO AUTOMATICO DE WHATSAPP
echo   (Gastronomia V Region - Vina del Mar y Valparaiso)
echo ============================================================
echo.
echo  Este proceso abrira los chats de los siguientes locales
echo  pendientes y presionara ENTER de forma 100%% automatica.
echo.
echo  IMPORTANTE: Durante el proceso (~2 minutos), no toques
echo  el teclado ni el raton para no quitar el foco a WhatsApp.
echo.
pause
echo.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "send_batch.ps1" -BatchSize 5 -DelaySec 20
echo.
echo Presiona cualquier tecla para cerrar esta ventana...
pause >nul
