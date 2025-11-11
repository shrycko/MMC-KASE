@echo off

REM    Copyright 2018 Quest Software Inc. All rights reserved.
REM
REM    File: agent_msi_remove.bat
REM
REM    This bat controls KACE SMA Agent auto-removal
REM    This file should be located in the KACE SMA
REM    client\agent_provisioning\window_platform
REM    shared directory.
REM
REM    Parameters:
REM      %1 - optional, if present and "1", then also removes all left-over configuration files
REM

echo [MSGCODE: 000] Begin agent_msi_remove.bat processing.

:: Check for 32-bit agent
SET KProgramFiles=%ProgramFiles(x86)%
IF NOT EXIST "%KProgramFiles%" SET KProgramFiles=%ProgramFiles%

IF EXIST "%KProgramFiles%\Quest\KACE\AMPTools.exe" goto detectedQuestPath
IF EXIST "%KProgramFiles%\Dell\KACE\AMPTools.exe" goto detectedDellPath

:: Check for 64-bit agent
SET KProgramFiles=%ProgramFiles%

IF EXIST "%KProgramFiles%\Quest\KACE\AMPTools.exe" goto detectedQuestPath

echo [MSGCODE: 002] KACE SMA Agent is not installed.
goto end

:detectedDellPath

REM *** KACE SMA AGENT REMOVAL (5.2 through 7.x) ***
REM  Launch AMPTools.exe in uninstall mode 
REM 
echo [MSGCODE: 005] KACE SMA Agent is detected in Dell path.
echo [MSGCODE: 006] Removing KACE SMA Agent.
cd /D "%KProgramFiles%\Dell\KACE"

REM Change the directory since AMPTools can't remove current directory.
cd ..

if "%1" == "1" (
    echo [MSGCODE: 010] Removing all agent files.
    start /wait KACE\AMPTools.exe -uninstall all-kuid 
) else ( 
    start /wait KACE\AMPTools.exe -uninstall
)

REM We need to wait 15 seconds for msiexec to complete agent uninstall
ping 127.0.0.1 -n 15 -w 1000 > nul

REM Report if the agent is installed, so the KACE SMA provisioning system can 
REM record success or failure. The server will be looking for this string, 
REM so don't change it without changing it as well.
if exist "%KProgramFiles%\Dell\KACE\AMPTools.exe" echo [MSGCODE: 003] Uninstall failed: KACE SMA Agent NOT removed.
if not exist "%KProgramFiles%\Dell\KACE\AMPTools.exe" echo [MSGCODE: 004] KACE SMA Agent successfully uninstalled.

goto end

:detectedQuestPath

REM *** KACE SMA AGENT REMOVAL (8.0+) ***
REM  Launch AMPTools.exe in uninstall mode 
REM 
echo [MSGCODE: 005] KACE SMA Agent is detected in Quest path.
echo [MSGCODE: 006] Removing KACE SMA Agent.
cd /D "%KProgramFiles%\Quest\KACE"

REM Change the directory since AMPTools can't remove current directory
cd ..

if "%1" == "1" (
    echo [MSGCODE: 010] Removing all agent files.
    start /wait KACE\AMPTools.exe -uninstall all-kuid 
) else ( 
    start /wait KACE\AMPTools.exe -uninstall
)

REM We need to wait 15 seconds for msiexec to complete agent uninstall
ping 127.0.0.1 -n 15 -w 1000 > nul

REM Report if the agent is installed, so the KACE SMA provisioning system can 
REM record success or failure. The server will be looking for this string, 
REM so don't change it without changing it as well.
if exist "%KProgramFiles%\Quest\KACE\AMPTools.exe" echo [MSGCODE: 003] Uninstall failed: KACE SMA Agent NOT removed.
if not exist "%KProgramFiles%\Quest\KACE\AMPTools.exe" echo [MSGCODE: 004] KACE SMA Agent successfully uninstalled.

goto end

:end
echo [MSGCODE: 100] End agent_msi_remove.bat processing.
