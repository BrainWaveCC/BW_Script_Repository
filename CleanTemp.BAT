@ECHO OFF
 rem ==========================================================================
 rem === Clean Temp Folders on All Local Drives
 rem ==========================================================================
 rem
 rem Created On: 09 Jul 2001
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 01 Feb 2025 / 28 Jul 2024 / 09 Jun 2024 / 04 Jun 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2003 and later
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    DU ..................... https://learn.microsoft.com/en-us/sysinternals/downloads/du
 rem    PSTOOLS ................ https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script deletes the contents of any of the following TEMP folders,
 :::  if they exist:
 :::
 :::  	x:\TEMP
 :::  	%SystemRoot%\TEMP
 :::  	%USERPROFILE%\Local Settings\TEMP
 :::  	%USERPROFILE%\AppData\Local\Application Data\Temp
 :::    %SystemRoot%\ProgramData\Microsoft\Windows\WER\...
 :::  	x:\RecoveryBin
 :::
 :::  You can add other locations to the @TEMPDIRS variable, OR via the
 :::  CustomVariables.TXT file in the \Scripts\Bat\Input folder
 :::
 :::  As much as you might be tempted to put this script in the startup group,
 :::  be advised that some installation routines leave files in the TEMP folder
 :::  in order to continue their installations after a reboot, and cleaning
 :::  this folder during the logon process would interfere with such an
 :::  installation.
 :::
 :::  (Nov 2010) Changed the default log extension of the reports from .LOG to
 :::  .TXT so that the reports that are mailed to mobile devices can be read
 :::  automatically. (Not too many devices can natively handle .LOG files)
 :::
 :::  (Oct 2014) v3.0 -- Added the option of COMPINFO to detect valid local
 :::  drive letters.  Falls back to using NET SHARE if COMPINFO.EXE is not
 :::  available.
 :::
 :::  (Mar 2015) v3.1 -- The @NODELETE variable facilitates the automatic
 :::  skipping of TEMP folders from deletion.  It should contain the list
 :::  of folders to be skipped (each enclosed in quotes).
 :::
 :::  (Jul 2018) v4.0 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Oct 2018) v4.1 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Sep 2019) v4.2 -- Attempt to clean up the TEMP folder for all Users;
 :::
 :::  (Oct 2019) v4.3 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (May 2020) v4.4 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Nov 2020) v4.5 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Dec 2020) v5.0 -- Added the Microsoft WER Logs files to be cleaned;
 :::
 :::  (May 2022) v5.1 -- Clean WER Logs folders and not just the files;
 :::
 :::  (Oct 2023) v5.2 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v5.3 -- Check for essential utilities with FINDFILES;
 :::
 :::  (Jun 2024) v5.4 -- Verify Operation before Cleaning Temp Folders;
 :::  -- Add TEMP folder capacity info (of main TEMP folders);
 :::
 :::  (Feb 2025) v5.5 -- Replaced COMPINFO with PSINFO to avoid process crashes;
 :::
 :::
 :::  ADDITIONAL SCRIPTING TOOLS/INFO:
 :::  -------------------------------------------------------------------------
 :::  https://www.BrainWaveCC.com/knowledge-base/scripting-and-automation-options-for-windows/
 :::  https://www.BrainWaveCC.com/knowledge-base/must-have-utilities-for-windows-usersadmins/
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 30 Nov 2020 / 26 Jul 2018
 rem ==========================================================================
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 01 Feb 2025 / 04 Jun 2024 / 10 May 2024 / 18 May 2022
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v5.5.0.550 a

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 (
	 ECHO Clean Temp Folders on All Local Drives
	 ECHO:
	 ECHO    YOU TYPED: %0 %*
	 ECHO:
	 ECHO   CMD SYNTAX: %~n0
	 ECHO               %~n0  [-e^|--errorlogs]
	 ECHO               %~n0  [-h^|-?]
	 ECHO:
	 ECHO  OPTION DEFINITIONS:
	 ECHO    -?, -H ............ Display this help message
	 ECHO    -e, --ErrorLogs ... Delete WER logs
	 ECHO:
	 ECHO  USAGE NOTES:
	 ECHO    * Parameters surrounded by ^<^> are mandatory.
	 ECHO    * Parameters surrounded by [] are optional.
	 ECHO    * Options are case-insensitive, and can be prefaced by "-" or "/".
	 GOTO :ExitBatch
 )

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f "%~dp0SetDrive.BAT" CCALC.EXE CHOICE.EXE DU.EXE NET.EXE -o PSINFO.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 FOR %%T IN (TMP TEMP) DO IF /I "!%%~T!"=="" SET %%~T=%SystemDrive%\Temp
 SET @TEMPDIRS="%USERPROFILE%\Local Settings" "%USERPROFILE%\AppData\Local\Application Data" "%TEMP%\.." "%TMP%\.." "%SystemDrive%" "%SystemRoot%"
 SET @TEMPINET="%USERPROFILE%\Local Settings\Temporary Internet Files" "%USERPROFILE%\AppData\Local\Microsoft\Windows\Temporary Internet Files"
 SET @RECYCLE=$Recycle.Bin RECYCLER RECYCLED RecoveryBin
 SET @NODELETE="File Service" "FileService"
 SET @LOCALTMP=%WinDir%\Temp

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- %SystemDrive%\Users Temp Folder Variables
 SET @TDEFAULT=
 SET @UDEFAULT=%SystemDrive%\Users
 FOR /F "TOKENS=*" %%D IN ('DIR "!@UDEFAULT!" /B /AD') DO SET @TDEFAULT=!@TDEFAULT! "!@UDEFAULT!\%%~D\AppData\Local"

 rem -- Temp Folder Variables
 SET @NETTRASH=
 FINDFILES --RC -F PSINFO && FOR /F "TOKENS=1-2 DELIMS=: " %%L IN ('PSINFO %@PSPARAMS% -D 2^>NUL ^| FIND ": Fixed"') DO (
	 SET @TEMPDIRS=!@TEMPDIRS! %%~L:
	 SET @NETTRASH=!@NETTRASH! %%~L
	 IF EXIST "%%~L:\Temp" SET @LOCALTMP=!@LOCALTMP!  %%~L:\Temp
 )
 IF NOT DEFINED @NETTRASH FOR /F "TOKENS=2 DELIMS=:\ " %%L IN ('NET SHARE ^| FIND ":\ "') DO (
	 SET @TEMPDIRS=!@TEMPDIRS! %%~L:
	 SET @NETTRASH=!@NETTRASH! %%~L
	 IF EXIST "%%~L:\Temp" SET @LOCALTMP=!@LOCALTMP!  %%~L:\Temp
 )
 SET @TEMPDIRS=!@TDEFAULT! !@TEMPDIRS!
 SET @WER_LOGS=%SystemDrive%\ProgramData\Microsoft\Windows\WER

 rem -- Get Used Temp Space
 FOR %%D IN ("%TEMP%" %@LOCALTMP%) DO CALL :AddCapacityUsed @DISKSPACE "%%~D"
 CALL :FormatNumber !@DISKSPACE! GB @DISKSPACE

 rem -- Add Windows Error Logs
 CHECKPARAMS --rc -t -c "E ERRORLOGS" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 8 SET @CLEAN_WER=TRUE

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Maint
 SET @LOGFILE=%@LOGPATH%\%~n0.%@FILESTAMP%
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Verify Folder and File Selection
 rem === Updated On: 09 Jun 2024 / 04 Jun 2024
 rem ==========================================================================
:VerifySelection
 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 ECHO %@DIVIDER-%
	 ECHO --- Preparing to Clean Temp Folders on All Local Drives
	 ECHO %@DIVIDER-%
	 ECHO --- USER TEMP FOLDER ....... %TEMP%
	 ECHO --- SYSTEM TEMP FOLDERS .... %@LOCALTMP%
	 ECHO --- TEMP STORAGE USED ...... %@DISKSPACE%
	 ECHO %@DIVIDER-%
	 ECHO:
	 CHOICE /C YNQEX /T 30 /D Y /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :ExitBatch
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Clean Temp Folders And Create Log
 rem === Updated On: 18 May 2022 / 25 Dec 2020
 rem ==========================================================================
:CleanUp
 IF NOT EXIST "%@LOGPATH%" MD "%@LOGPATH%"

 ECHO Cleaning Temp Directories: %@TODAY%-%@NOW% -- Please Stand By...
 ECHO Cleaning Temp Directories: %@TODAY%-%@NOW% >"%@LOGFILE%"
 FOR %%V IN (%@TEMPDIRS%) DO                            CALL :ViewTempFolder "%%~V\Temp"
 FOR %%V IN (%@NETTRASH%) DO FOR %%X IN (%@RECYCLE%) DO CALL :ViewTempFolder "%%~V:\%%~X"
 FOR %%V IN (%@TEMPINET%) DO                            CALL :ViewTempFolder "%%~V"
 FOR %%V IN (%@WER_LOGS%) DO                            CALL :ViewTempFolder "%%~V"

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO Cleaning Temp Directories
 ) >>"%@LOGFILE%"

 FOR %%V IN (%@TEMPDIRS%) DO                            CALL :CleanTempFolder   "%%~V\Temp"
 FOR %%V IN (%@NETTRASH%) DO FOR %%X IN (%@RECYCLE%) DO CALL :CleanTempFolder   "%%~V:\%%~X"
 FOR %%V IN (%@TEMPINET%) DO                            CALL :CleanIETempFolder "%%~V"
 FOR %%V IN (%@TEMPINET%) DO                            CALL :CleanIETempFolder "%%~V\Low"

 IF DEFINED @CLEAN_WER FOR /F %%V IN ('DIR /B /AD "%@WER_LOGS%"') DO CALL :CleanTempFolder "%@WER_LOGS%\%%~V"
:²CleanUp
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Report of Cleanup
 rem === Updated On: 25 Dec 2020
 rem ==========================================================================
:FinalReport
 ECHO Finished Cleaning Temp Directories: >>"%@LOGFILE%"
 FOR %%V IN (%@TEMPDIRS%) DO                            CALL :ViewTempFolder "%%~V\Temp"
 FOR %%V IN (%@NETTRASH%) DO FOR %%X IN (%@RECYCLE%) DO CALL :ViewTempFolder "%%~V:\%%~X"
 FOR %%V IN (%@TEMPINET%) DO                            CALL :ViewTempFolder "%%~V"
 FOR %%V IN (%@WER_LOGS%) DO                            CALL :ViewTempFolder "%%~V"

 TYPE "%@LOGFILE%"
 DIR "%@LOGFILE%"


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 25 Dec 2020 / 04 Oct 2019
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: View Each Temp Folder
 rem === Updated On: 05 Feb 2015 / 15 Aug 2011
 rem ==========================================================================
:ViewTempFolder
 rem %1 = Current Temp Folder

 SET @FOLDER=%~f1
 IF EXIST "%@FOLDER%" (
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO Enumerating Temp Directory: "%@FOLDER%"
	 DIR /S /A "%@FOLDER%"
 ) >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Clean Each Standard Temp Folder unless Exemption Found
 rem === Updated On: 05 Mar 2015 / 23 Mar 2009
 rem ==========================================================================
:CleanTempFolder
 rem %1 = Current Temp Folder

 SET @FOLDER=%~f1

 rem -- Search for Files of Folders to Exempt the Folder from Deletion
 FOR %%E IN (%@NODELETE%) DO IF EXIST "%@FOLDER%\%%~E" (
	 ECHO:
	 ECHO *** SKIPPING %@FOLDER%" ***
	 ECHO:
	 GOTO :EOF
 ) >>"%@LOGFILE%" 2>&1

 IF EXIST "%@FOLDER%" (
	 ECHO:
	 ECHO  Cleaning Temp Files From "%@FOLDER%"
	 PUSHD "%@FOLDER%"
	 RD /Q /S "%@FOLDER%"
	 POPD
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Clean Each IE Temp & Outlook Temp Folder
 rem === Updated On: 15 Aug 2011 / 23 Mar 2009
 rem ==========================================================================
:CleanIETempFolder
 rem %1 = Current Temp Folder

 SET @FOLDER=%~f1
 FOR %%S IN (OLK CONTENT) DO FOR /F %%T IN ('DIR /B /A "%@FOLDER%\%%~S*"') DO (
	 ECHO:
	 ECHO  Cleaning Temp Files From "%@FOLDER%\%%~T"
	 PUSHD "%@FOLDER%\%%~T"
	 RD /Q /S "%@FOLDER%\%%~T"
	 POPD
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Add Disk Capacity of Temp folders Used
 rem === Updated On: 09 Jun 2024
 rem ==========================================================================
:AddCapacityUsed
 rem %1 = Variable to Store Data
 rem %2 = Current Temp Folder

 IF "%~1"=="" GOTO :EOF
 IF NOT EXIST "%~2" GOTO :EOF

 FOR /F "TOKENS=2" %%S IN ('DU -L 1 "%~2" 2^>NUL ^| FIND "Size: "') DO (
	 SET @ZZZ=%%~S
	 SET @ZZZ=!@ZZZ:,=!
	 FOR /F %%C IN ('CCALC !%~1! + !@ZZZ! 2^>NUL') DO SET %~1=%%~C
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Format Numbers with Thousands Separator
 rem === Updated On: 09 Jun 2024
 rem ==========================================================================
:FormatNumber
 rem %1 = Current Number to be Formatted
 rem %2 = Unit of Measurement to be Used
 rem %3 = New Variable To Store Formatted Number

 IF "%~3"=="" GOTO :EOF
                   SET @OPERAND=+ 0
 IF /I "%~2"=="KB" SET @OPERAND=/ 1024
 IF /I "%~2"=="MB" SET @OPERAND=/ 1024 / 1024
 IF /I "%~2"=="GB" SET @OPERAND=/ 1024 / 1024 / 1024
 IF /I "%~2"=="TB" SET @OPERAND=/ 1024 / 1024 / 1024 / 1024

 FOR /F %%N IN ('CCALC %~1 %@OPERAND% -F 2^>NUL') DO SET %~3=%%~N %~2
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Set/Display Script Version and Execution Status
 rem === Updated On: 16 Oct 2023 / 24 Dec 2019
 rem ==========================================================================
:ShowStatus
 rem %1 = Run Status of Script
 rem %2 = Current Application Version

 IF NOT DEFINED @DATEFMT SET "@DATEFMT=-F "mm/dd/yyyy hh:nn:ss.zzz""
 SET "@SCRIPTSTATUS=%~1" & IF "%~1"=="" SET "@SCRIPTSTATUS=RUNNING"
 IF NOT "%~2"=="" (SET "@VER=%~nx0 %~2" & SET "@VERSION=%~2")
 IF /I "%~1"=="STARTED" FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET "@SCRIPT_BEG#="%%~d""
 IF /I "%~1"=="FINISHED" (
	 IF DEFINED $CODEPAGE FOR /F "TOKENS=1* DELIMS=:" %%B IN ('CHCP %$CODEPAGE%') DO SET "@CHCP_STATUS= {Restoring Code Page:%%C}"
	 IF DEFINED @END_DEBUG_MODE %@END_DEBUG_MODE:"=%
	 TITLE Command Prompt [%USERDOMAIN%\%USERNAME%]   !@DEBUG_MODE!
	 DATEINFO -t %@SCRIPT_BEG#% -e "hr:min:sec.ms" -o "\n*** DURATION: " 2>NUL
 )
 NOW \n*** %@SCRIPTSTATUS%: %@VER% [\v] *** %@CHCP_STATUS%\n!@CRLF-%~1!
 GOTO :EOF
         