@echo off
chcp 65001 >nul
title BREBORN - Envio Automatico Universal WhatsApp
cls
echo ============================================================
echo   BREBORN SALES HUB - ENVIO AUTOMATICO UNIVERSAL WHATSAPP
echo   (Todos los rubros: Cafeterias, Barberias, Tiendas y mas)
echo   V Region - Vina del Mar y Valparaiso
echo ============================================================
echo.
echo  Este script envia mensajes a TODOS los locales del portal
echo  que tengan WhatsApp activo y que aun NO tengan "Mensaje Enviado"
echo  (priorizando primero los locales SIN pagina web).
echo.
echo  Selecciona cuantos mensajes enviar en esta tanda:
echo    [1] Proximos 5 locales   (~2 min - Prueba rapida)
echo    [2] Proximos 10 locales  (~4.5 min - Recomendado)
echo    [3] Proximos 20 locales  (~9 min - Tanda media)
echo    [4] TODOS los locales pendientes sin mensaje enviado
echo    [5] Solo locales SIN pagina web propia (auditados 100%%)
echo.
set /p choice="Elige una opcion [1-5, Enter=10]: "

set BATCH=10
set EXTRA=
if "%choice%"=="1" set BATCH=5
if "%choice%"=="2" set BATCH=10
if "%choice%"=="3" set BATCH=20
if "%choice%"=="4" set BATCH=0
if "%choice%"=="5" (
  set BATCH=0
  set EXTRA=-OnlySinWeb
)

echo.
echo  IMPORTANTE: Durante el proceso NO toques el teclado ni el
echo  raton para no quitar el foco a WhatsApp Desktop.
echo  Si un numero no tiene WhatsApp, el script lo detecta y lo salta.
echo.
pause
echo.
cd /d "%~dp0"
if "%BATCH%"=="0" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "send_batch.ps1" -All %EXTRA% -DelaySec 25
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "send_batch.ps1" -BatchSize %BATCH% -DelaySec 25
)
echo.
echo Presiona cualquier tecla para cerrar esta ventana...
pause >nul
