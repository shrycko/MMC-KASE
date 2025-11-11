@echo off

REM    Copyright 2020 Quest Software, Inc.
REM    All rights reserved.
REM
REM    File: agent_msi_provision.bat
REM
REM    This bat installs the KACE SMA Agent.
REM
REM    Params:
REM      %1 - required, server hostname on which installer sits
REM      %2 - required, server path to subdir of installer
REM      %3 - required, name of msi installer file
REM      %4 - optional, if present is KACE SMA server hostname, if not given, defaults to %1
REM      %5 - optional, if present is the agent token used to authenticate with the KACE SMA.
REM

echo [MSGCODE: 000] Begin agent_msi_provision.bat processing.

REM If given 3rd param, use it, otherwise first param is our KACE SMA server
set KBOX_SERVER=%4
if "x%4x" == "xx" set KBOX_SERVER=%1

REM Change working dir to temp
cd %windir%\temp

REM Detect correct Program Files folder. Note this batch file may run in 32-bit env (SysWOW64/cmd.exe)
REM So %ProgramFiles% might be Program Files (x86), but we always want to check the regular Program Files.
set K64=no
if "%ProgramFiles(x86)%" == "" echo [MSGCODE: 032] Detected 32-bit platform.
if "%ProgramFiles(x86)%" == "" goto on32Bit
set K64=yes
echo [MSGCODE: 064] Detected 64-bit platform.
goto setKSystem

:on32Bit
echo [MSGCODE: 064] Detected unsupported 32-bit platform.
goto end

:setKSystem
SET KSystem32=%SystemRoot%

REM Detect if 5.2 (or later) agent already installed, if so, skip everything else
if exist "%ProgramFiles%\Quest\KACE\AMPTools.exe" goto skip
if exist "%ProgramFiles(x86)%\Quest\KACE\AMPTools.exe" goto skip
goto install

:skip

echo [MSGCODE: 014] KACE SMA Agent is already installed.
goto end

:install

REM Run our msi installer
echo [MSGCODE: 015] Executing MSI installer.

set INSTALLER="\\%1\%2\agent_provisioning\windows_platform\%3"

REM Set install path to %temp% when the passed in server path is set to "local_install"
if "%2" == "local_install" set INSTALLER="%temp%\%3"

set TOKEN=%5

echo on

start /wait msiexec.exe /qn /l*v %temp%\ampmsi.log /i %INSTALLER% HOST=%KBOX_SERVER% TOKEN=%TOKEN%

echo off
set retcode=%errorlevel%
echo Return code (MSI_ERROR_LEVEL) from MSI execution: [%retcode%] 
REM detect and print error related to trying to install 5.4 agent on Windows 2000
if "%retcode%"=="1" type %temp%\ampmsi.log | findstr ERROR_INSTALL_REJECTED | findstr /V \-\-

REM Detect when installation fails because PowerShell is not installed.
if "%retcode%"=="1603" type %temp%\ampmsi.log | findstr /I /c:"This version of Windows is not supported. Installation will now abort. "

REM Report if the agent is installed, so the KACE SMA provisioning system can record success or failure.
REM The server will be looking for this string, so don't change it, without changing it as well.
set INSTALLED=0
if exist "%ProgramFiles%\Quest\KACE\AMPTools.exe" set INSTALLED=1
if exist "%ProgramFiles(x86)%\Quest\KACE\AMPTools.exe" set INSTALLED=2 

if "%INSTALLED%"=="0" echo [MSGCODE: 002] KACE SMA Agent is not installed.
if "%INSTALLED%"=="1" echo [MSGCODE: 001] KACE SMA Agent (64-bit) is installed.
if "%INSTALLED%"=="2" echo [MSGCODE: 001] KACE SMA Agent (32-bit) is installed.

REM Wait 20 seconds for KONEA to start and create kuid.txt.
ping 127.0.0.1 -n 20 -w 1000 > nul

echo [MSGCODE: 091] Agent installation succeeded.

REM Dump our KUID
if exist "%ALLUSERSPROFILE%\Quest\KACE\kuid.txt" set /p KUID=<"%ALLUSERSPROFILE%\Quest\KACE\kuid.txt"
if not "%KUID%"=="" echo [MSGCODE: 093] KUID value detected.
if not "%KUID%"=="" echo [MSGCODE: 094] KACE SMA agent KUID: %KUID%
if "%KUID%"=="" echo [MSGCODE: 095] KUID value not written by MSI installer.

:end

echo [MSGCODE: 100] End agent_msi_provision.bat processing.
