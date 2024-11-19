@ECHO OFF
 rem ==========================================================================
 rem === Create a Rotating Schedule of SystemState Backups via ZIP
 rem ==========================================================================
 rem
 rem Created On: 06 Mar 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 26 Sep 2024 / 08 Sep 2024 / 10 May 2024 / 16 Oct 2023
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2003 and later
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    InfoZip Utilities ...... http://sourceforge.net/projects/infozip/files/
 rem    ShadowSpawn ............ https://github.com/candera/shadowspawn/downloads
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script originally created a schedule of daily SystemState backups on
 :::  Windows 2000/XP/2003 system using the native NTBACKUP utility, named for
 :::  each day of the week.  This functionality was changed by Microsoft several
 :::  times starting with Windows 2008 and WBADMIN.  Ultimately, we have moved
 :::  away from using the Microsoft Native tools here.
 :::
 :::  As for version 5 of this script, the SystemState backup is reduced to the
 :::  following:
 :::  1. NTUSER.DAT files under the C:\Users folder tree
 :::  2. The major registry hives under the %WINDIR%\System32\Config folder tree
 :::
 :::  (Jul 2019) v5.0 -- Major change away from Microsoft Native options;
 :::  -- Backups now consist of the NTUSER.DAT files plus the registry hives
 :::  found in %WINDIR%\System32\Config, using ShadowSpawn to access open files,
 :::  and compressed as ZIP files with the .Archive extension;
 :::  -- Added JobHistory and Syslog reporting to the script;
 :::
 :::  (Aug 2019) v5.1 -- Capture ErrorLevel of ShadowSpawn processes and record
 :::  them in the JobHistory log;
 :::
 :::  (Oct 2019) v5.2 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v5.3 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Jan 2020) v5.4 -- Added a routine for validating integer parameters;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::
 :::  (Mar 2020) v5.5 -- Search "Documents and Settings" on pre-2008 systems;
 :::
 :::  (May 2020) v5.6 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Jul 2020) v5.7 -- Validate Existing Archive Before Adding New Files;
 :::
 :::  (Nov 2020) v5.8 -- Moved backups to SystemState folder under Backups$ share;
 :::
 :::  (Nov 2020) v5.9 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Jan 2022) v6.0 -- Modify the @NAMECHK verification to include \ prefix;
 :::
 :::  (Oct 2023) v6.1 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v6.2 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::  (Sep 2024) v6.3 -- Call SetDrive.BAT with option for 1252 as code page;
 :::  -- Extended :ForwardToSyslog to update any locally running syslog service;
 :::  -- Created :LogCriticalFailure routine for early job failures;
 :::
 :::
 :::  ADDITIONAL SCRIPTING TOOLS/INFO:
 :::  -------------------------------------------------------------------------
 :::  https://www.BrainWaveCC.com/knowledge-base/scripting-and-automation-options-for-windows/
 :::  https://www.BrainWaveCC.com/knowledge-base/must-have-utilities-for-windows-usersadmins/
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 22 Jul 2020 / 16 May 2018
 rem ==========================================================================
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 26 Sep 2024 / 08 Sep 2024 / 10 May 2024 / 30 Nov 2020 / 02 Nov 2020
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v6.4.0.640 b

 rem -- Need This Variable for HELP Message
 SET @SS_EXT=.Archive

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT"
 SET #MSUTILS=FINDSTR.EXE SCHTASKS.EXE
 SET #O_UTILS=SYSLOGGEN.EXE SHADOWSPAWN.EXE TAIL.EXE ZIP.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES& GOTO :ExitBatch)

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 FOR %%D IN ("Documents and Settings" "Users") DO IF EXIST "%SystemDrive%\%%~D" SET @NTUSER_ROOT=%SystemDrive%\%%~D
 SET @NTUSER_DATA=NTUSER*.*
 SET @HIVES_ROOT=%WINDIR%\System32\Config
 SET @HIVES_DATA=DEFAULT ELAM COMPONENTS DRIVERS SAM SECURITY SOFTWARE SYSTEM
 SET @EXCLUDE="*SystemProfile*" "*AppData*" "*Dropbox*" "*OneDrive*" "*Box*" "*Google*" "*RegBack*"

 rem -- Job Scheduling Variables
 SET @JOBNAME=SystemState Backup
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=00:01:00
 SET @JOBDATE=
 SET @JOBPATH=%~f0
 SET @JOBTYPE=
 SET @UPDATESCHED=TRUE

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0" 1252

 rem -- Obtain Free Drive for Use with VSS or EXIT
 SET @ERR1=*
 SET @ERR2=*
 SET @VSS_VERBOSITY=/VERBOSITY=2
 SET @VSS=& FOR %%F IN ("%@UTILS64%" "%@UTILS%") DO IF EXIST "%%~F\ShadowSpawn.exe" SET @VSS=ShadowSpawn
 CALL :FindFreeDrive @DRV
 IF NOT DEFINED @DRV (
	 CALL :SaveJobHistory ABORTED - NO FREE DRIVE
	 GOTO :ExitBatch
 )

 rem -- Main Variables
 SET @ECHO=
 SET @ARCHIVES_PRUNED=0

 rem -- Archive-Related Variables
 IF NOT DEFINED @MAXBACKUPS SET @MAXBACKUPS=2
 SET @BACKUPDIR=%@BACKUPS%\SystemState
 SET @BK_PREFIX=%@BACKUPDIR%\SystemState-
 SET @BACKUPFILE=!@BK_PREFIX!%~1!@SS_EXT!& IF "%~1"=="" SET @BACKUPFILE=!@BK_PREFIX!%@DAY%!@SS_EXT!

 rem -- Zip-Related Variables
 IF DEFINED @EXCLUDE SET @EXCLUDE=-x !@EXCLUDE:-x=!
 SET @ZIPTEST=ZIP -c -b "%TEMP%"
 SET @ZIPCMD=ZIP !@EXCLUDE! -9 -v -dgds 1m -S -R -dt -b "%TEMP%"
 SET @RUNTHIS=%TEMP%\ExecuteZip#%@RANDOM%.BAT
 ( ECHO @PUSHD "!@DRV!"
   ECHO @ECHO !@ZIPCMD! %%*
   ECHO @!@ZIPCMD! %%*
   ECHO @POPD
 ) >%@RUNTHIS%
 SET @ZIPCMD=%@RUNTHIS%

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Backups
 SET @LFORMAT=%@LOGPATH%\SystemStateBackups
 SET @TIMINGS=%@LFORMAT%.RECORDING.TXT
 SET @LOGFILE=%@LFORMAT%.%@FILESTAMP%
 FOR %%L IN (SUMMARY TEMPLOG ERRORS) DO SET @%%L=%@LFORMAT%.%%L.%@FILESTAMP%
 SET @LOGLIST="%@LOGFILE%" "%@ERRORS%"
 SET @CLEANUP="%@TEMPLOG%" "%@ERRORS%" "%@SUMMARY%" "%@RUNTHIS%"

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "S" & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE)
 CALL :GetParams "U" & IF DEFINED @OK (SET @UNSCHED=TRUE)
 CALL :GetParams "N" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "Z" & IF DEFINED @OK (SET @TESTMODE=TRUE& SET @ECHO=ECHO& SET @JOBTYPE= // TEST)
 CALL :GetParams "D" & IF DEFINED @OK (SET @DELETE=TRUE) ELSE (SET @DELETE=)
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 10 May 2024 / 22 Jan 2022 / 11 Aug 2019
 rem ==========================================================================
:ScheduleJobs
 IF /I "%@NOSCHED%"=="TRUE" IF /I NOT "%@UNSCHED%"=="TRUE" (
	 SET @JOBTYPE=!@JOBTYPE! // ONE-TIME
	 ECHO:
	 ECHO *** Job Scheduling Disabled ***
	 ECHO:
	 GOTO :ScheduleJobs_END
 )

 ECHO:
 ECHO Scheduling "%@JOBNAME%" on %COMPUTERNAME%...
 ECHO:

 IF %@OSBUILD% LSS 6000 SET @TASKFOLDER=
 SET @NAMECHK=%@JOBNAME:[=\[%
 SET @NAMECHK=!@NAMECHK:]=\]!
 SET @CHK_SCHED=SCHTASKS /QUERY /V /FO LIST
 SET @SET_SCHED=SCHTASKS /CREATE /TN "!@TASKFOLDER!%@JOBNAME%" /TR "%@JOBPATH%" /RU "%@JOBUSER%" /SC %@JOBFREQ% %@JOBDATE% /ST %@JOBTIME% %@JOBLEVEL% %@FORCE%

 rem -- Delete Scheduled Task from Old Custom Folders on Vista/2008+
 IF %@OSBUILD% GEQ 6000 (
	 FOR /F "TOKENS=1* DELIMS=\ " %%s IN ('%@CHK_SCHED% 2^>NUL ^| FIND "TaskName:" ^| FINDSTR /I /R /C:"\\%@NAMECHK%$"') DO (
		 IF /I NOT "%@TASKFOLDER%%@JOBNAME%"=="%%t" SCHTASKS /DELETE /TN "%%t" /F >NUL 2>&1
	 )
 )

 rem -- Check to Remove Scheduled Job
 IF /I "%@UNSCHED%"=="TRUE" (
	 SCHTASKS /DELETE /TN "!@TASKFOLDER!%@JOBNAME%" %@FORCE% 2>NUL
	 ECHO Task has been UNscheduled.  Now exiting script...
	 CALL :SaveJobHistory JOB UNSCHEDULED ONLY
	 GOTO :ExitBatch
 )

 rem -- Check for Schedule Update Parameters
 IF /I "%@UPDATESCHED%"=="TRUE" (!@SET_SCHED!) ELSE (CALL :CheckSched "%~f0")
 ECHO %@DIVIDER-%
 ECHO:
 IF /I "%@SCHEDULEONLY%"=="TRUE" (
	 ECHO Task has been scheduled.  Now exiting script...
	 IF %@OSBUILD% LSS 6000 (SCHTASKS) ELSE (%@CHK_SCHED% /TN "!@TASKFOLDER!%@JOBNAME%")
	 CALL :SaveJobHistory JOB SCHEDULED ONLY
	 GOTO :ExitBatch
 )
:ScheduleJobs_END
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Backup NTUSER files and Windows Registry Hives
 rem === Updated On: 22 Jul 2020 / 11 Aug 2019
 rem ==========================================================================
:MakeBackups
 CALL :ShowHeader CREATE SYSTEMSTATE BACKUPS
 FOR %%V IN ("%@BACKUPDIR%" "%@LOGPATH%" "%TEMP%") DO IF NOT EXIST "%%~V" MD "%%~V" >NUL
 SET @VERIFY_BACKUP=%@ZIPTEST% "%@BACKUPFILE%"
 SET @BACKUP_NTUSER=%@VSS% %@VSS_VERBOSITY% "%@NTUSER_ROOT%" !@DRV! %@ZIPCMD% -FS "%@BACKUPFILE%" %@NTUSER_DATA%
 SET @BACKUP_SYSTEM=%@VSS% %@VSS_VERBOSITY% "%@HIVES_ROOT%"  !@DRV! %@ZIPCMD% -T  "%@BACKUPFILE%" %@HIVES_DATA%

 rem -- Create Compressed Archive of NTUSER files and Windows Registry Hives...
 ( NOW \**** %COMPUTERNAME% - [\v] - %@VER%\n\*\n

   ECHO  - Testing Archive... >CON
   ECHO !@VERIFY_BACKUP!
   FOR /F "TOKENS=*" %%B IN ('!@VERIFY_BACKUP! ^| FIND /I "zip error: " ') DO SET @DELETE=TRUE
   IF DEFINED @DELETE (
	  %@ECHO% ECHO - Deleting Invalid Archive: "%@BACKUPFILE%"
	  %@ECHO% DEL "%@BACKUPFILE%"
   )
   ECHO %@DIVIDER-%
   ECHO:

   ECHO  - Backing Up User Registry... >CON
   ECHO !@BACKUP_NTUSER!
   %@ECHO% !@BACKUP_NTUSER!
   %@ECHO% SET @ERR1=!ERRORLEVEL!
   ECHO %@DIVIDER-%
   ECHO:

   ECHO  - Backing Up System Registry... >CON
   ECHO !@BACKUP_SYSTEM!
   %@ECHO% !@BACKUP_SYSTEM!
   %@ECHO% SET @ERR2=!ERRORLEVEL!
   ECHO %@DIVIDER-%
   ECHO:
  ) >>"%@LOGFILE%" 2>>"%@ERRORS%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Prune Backup Files Which Exceed The Maximum Number of Backups
 rem === Updated On: 11 Aug 2019 / 08 Aug 2019
 rem ==========================================================================
:PruneOlderFiles
 CALL :ShowHeader PRUNE SYSTEMSTATE ARCHIVES - KEEP THE %@MAXBACKUPS% MOST RECENT BACKUPS

 FOR %%V IN (1 2 3 4 5 6 7 8 9 10) DO IF "%%~V"=="%@MAXBACKUPS%" (
	 ECHO:
	 ECHO Keeping The %@MAXBACKUPS% Most Recent Backups...
	 FOR /F "SKIP=%@MAXBACKUPS% TOKENS=*" %%E IN ('DIR /OG-D /B /A "%@BK_PREFIX%*.*" ') DO (
		 ECHO  - Deleting Old Backup File: "%%~E" >CON
		 ECHO  - Deleting Old Backup File: "%%~E"
		 %@ECHO% DEL "%@BACKUPDIR%\%%~E"
		 SET /A @ARCHIVES_PRUNED+=1
	 )
	 ECHO:
 ) >>"%@LOGFILE%" 2>>"%@ERRORS%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Report Summary
 rem === Updated On: 20 Oct 2019 / 30 Jul 2019
 rem ==========================================================================
:ReportSummary
 CALL :ShowHeader SAVE JOB HISTORY
 CALL :SaveJobHistory

 ( rem -- Write to Log
	 DIR /OGD "%@BACKUPDIR%"
	 ECHO:
	 ECHO %@DIVIDER~%
	 ECHO  Total Files Archived ...!@FA!
	 ECHO  Old Archives Pruned .....!@AP!
	 ECHO %@DIVIDER~%
 ) >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Log Management/Maintenance (Or Copy Them for Debug Purposes)
 rem === Updated On: 26 Jun 2019
 rem ==========================================================================
:LogMaint
 CALL :ShowHeader PERFORMING FINAL LOG MAINTENANCE

 IF /I "%DEBUG%"=="COPY" FOR %%L IN (%@LOGLIST% %@CLEANUP%) DO IF EXIST %%L COPY %%L "%TEMP%" /Y

 FOR %%L IN (%@LOGLIST%) DO IF EXIST %%L (
	 SET @THISLOG=%%L
	 COPY %%L !@THISLOG:%@FILESTAMP%=TXT! /Y
	 IF /I %%L=="%@LOGFILE%" (ECHO: & DIR %%L)
 )
 FOR %%L IN (%@CLEANUP%) DO IF EXIST %%L DEL %%L >NUL
 ECHO %@DIVIDER~%
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Job Report
 rem === Updated On: 04 Aug 2019 / 26 Jun 2019 / 25 Feb 2015
 rem ==========================================================================
:FinalReport
 CALL :ShowHeader GENERATE FINAL REPORT
 DIR "%@BK_PREFIX%*.*" /OD /A-D


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 04 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 16 Oct 2023 / 30 Jul 2019
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Display Section Header
 rem === Updated On: 30 Jul 2019
 rem ==========================================================================
:ShowHeader
 rem %* = Message to Display

 IF "%~1"=="" GOTO :EOF
 ECHO:
 ECHO:
 ECHO %@DIVIDER*%
 ECHO *** %*
 ECHO %@DIVIDER*%
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Find Free Drive Letter
 rem === Updated On: 23 Jun 2019
 rem ==========================================================================
:FindFreeDrive
 rem %1 = Drive Variable

 PUSHD \\%COMPUTERNAME%\ADMIN$
 IF %ERRORLEVEL% EQU 0 (
	 IF "%~1"=="" (SET @DRV=%CD%) ELSE (SET %~1=%CD%)
 ) ELSE (
	 ECHO *** ERROR SETTING DRIVE ***
	 IF "%~1"=="" (SET @DRV=) ELSE (SET %~1=)
 )
 POPD
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine if Parameter is a Valid Integer, Or Set to Zero
 rem === Updated On: 21 Jan 2020
 rem ==========================================================================
:GetInteger
 rem %1 = Variable to Store Integer
 rem %2 = Parameter to Evaluate
 rem %3 = Value to Default to, If Zero
 rem %4 = Optional: Lowest Value
 rem %5 = Optional: Highest Value

 SET @V1=%2& IF DEFINED @V1 SET @V1=!@V1:"=!
 SET @V2=%3& IF DEFINED @V2 SET @V2=!@V2:"=!
 SET @V3=%4& IF DEFINED @V3 SET @V3=!@V3:"=!
 SET @V4=%5& IF DEFINED @V4 SET @V4=!@V4:"=!
 FOR /F "TOKENS=3" %%i IN ('CHECKPARAMS -o --min "!@V3!" --max "!@V4!" -n "!@V1!" "!@V2!" 2^>NUL') DO SET %~1=%%i
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Use CheckParams.exe to Capture Selected Parameters
 rem === Updated On: 21 Jan 2020 / 24 Sep 2019
 rem ==========================================================================
:GetParams
 rem %1 = Parameters to Search For
 rem %2 = Variable to Set

 SET @OK=& IF "%~1"=="" GOTO :EOF
 FOR /F "TOKENS=2-3*" %%v IN ('CHECKPARAMS -q -a -c "%~1" -s %@ALL_PARAMS% 2^>NUL') DO IF /I "%%~v"=="TRUE" (
	 SET @OK=T
	 SET @REQ=T
	 IF NOT "%~2"=="" SET %~2=%%~x
 )
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Pad Variable Content to the Left/Right for Display in Logs
 rem === Updated On: 22 Jan 2020 / 14 Oct 2019
 rem ==========================================================================
:PadLeft
:PadRight
 rem %1 = Variable to Store New Content
 rem %2 = Existing Value to Pad
 rem %3 = Character to use as padding [typically " ", "." or "0"]
 rem %4 = New String Length

 SET @STR=%~2
 SET @LEN=& FOR /L %%c IN (0,1,199) DO IF "!@STR:~%%c,1!"=="" IF NOT DEFINED @LEN SET @LEN=%%c
 IF 1%@LEN% GEQ 1%~4 (
	 SET %~1=%~2
 ) ELSE (
	 IF /I "%~0"==":PadLeft" (
		 SET @TEMPVAR=& FOR /L %%c IN (1,1,%~4) DO SET @TEMPVAR=!@TEMPVAR!%~3
		 SET @TEMPVAR=!@TEMPVAR!%~2
		 SET %~1=!@TEMPVAR:~-%~4!
	 )
	 IF /I "%~0"==":PadRight" (
		 SET @TEMPVAR=%~2& FOR /L %%c IN (1,1,%~4) DO SET @TEMPVAR=!@TEMPVAR!%~3
		 SET %~1=!@TEMPVAR:~0,%~4!
	 )
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Log Early Job Execution Failures
 rem === Updated On: 26 Sep 2024
 rem ==========================================================================
:LogCriticalFailure
 rem %* = Optional Message to include in Job History

 SET @TEMPLOG="%TEMP%\%~n0.Errors.TXT"
 CALL :ForwardToSyslog "6" %~n0 // ENDED: !DATE! at !TIME: =0! // %* >>%@TEMPLOG%
 ECHO:
 ECHO For more details, see: %@TEMPLOG%
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Update Job Execution Stats
 rem === Updated On: 15 Oct 2019 / 08 Oct 2019
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 SET @FILES_ARCHIVED=0& FOR /F "TOKENS=1" %%A IN ('TYPE "%@LOGFILE%" ^| FIND /C "  testing: "') DO SET /A @FILES_ARCHIVED+=%%~A

 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @FA "%@FILES_ARCHIVED%" "." 3
 CALL :PadLeft @AP "%@ARCHIVES_PRUNED%" "." 2
 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 SET @JOBHISTORY=%@JOBNAME% // FILES ZIPPED.%@FA% // ARCHIVES PRUNED.%@AP% // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // VSS=%@DRV:~0,2% ERRLVL1=%@ERR1% ERRLVL2=%@ERR2% // %~n0 %@VERSION%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('TYPE "%@TIMINGS%" ^| FIND /C "/"') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY "%@TIMINGS%" "!@OLDTIME!" /V /Y >CON
	 TAIL -%@MINROWS% "!@OLDTIME!" >"%@TIMINGS%"
	 ECHO:
	 CALL :ForwardToSyslog "5" %@JOBNAME%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>"%@LOGFILE%" 2>>"%@ERRORS%"

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@RUNMODE!!@TRUNCATED! >>"%@TIMINGS%" 2>>"%@ERRORS%"
 %@VERBOSE_ON%
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 25 Sep 2024 / 13 Jan 2020 / 23 Jun 2019
 rem ==========================================================================
:ForwardToSyslog
 rem %1 = Syslog Severity Level (RFC 3164)
 rem %* = Message to Send to Display and Send to Syslog Server

 SET @S_MSG=%*& IF "%~2"=="" SET @S_MSG=%1 - This is a Syslog Test Message from %@VER%
 SET @SEV=6
 FOR %%a IN (0 EMERGENCY) DO IF /I "%~1"=="%%~a" SET @SEV=0
 FOR %%a IN (1 ALERT) DO IF /I "%~1"=="%%~a" SET @SEV=1
 FOR %%a IN (2 CRITICAL) DO IF /I "%~1"=="%%~a" SET @SEV=2
 FOR %%a IN (3 ERROR) DO IF /I "%~1"=="%%~a" SET @SEV=3
 FOR %%a IN (4 WARNING) DO IF /I "%~1"=="%%~a" SET @SEV=4
 FOR %%a IN (5 NOTICE) DO IF /I "%~1"=="%%~a" SET @SEV=5
 FOR %%a IN (6 INFORMATION) DO IF /I "%~1"=="%%~a" SET @SEV=6
 FOR %%a IN (7 DEBUG) DO IF /I "%~1"=="%%~a" SET @SEV=7

 %@VERBOSE_OFF%
 CALL :Prepare4Syslog %@S_MSG%

 ECHO !@S_MSG!
 IF DEFINED @SYSLOG_UTIL (
	 IF /I "%@USE_SYSLOGS%"=="TRUE" (
		 FOR %%s IN ("" 0 1 2 3 4) DO IF DEFINED @SYSLOG%%~s (
			 SET @S_PORT=514& IF DEFINED @SYSLOG%%s_PORT SET @S_PORT=!@SYSLOG%%~s_PORT!
			 "%@SYSLOGGEN%" -t:!@SYSLOG%%~s! -p:!@S_PORT! -f:19 -s:!@SEV! -tg:"%~n0" -m:"!@S_MSG2!" -q -hn:%@LOCALHOST% | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )

	 IF /I "%@SCRIPT_METRICS%"=="TRUE" (
		 FOR %%P IN (%@MY_SYSLOG_PORTS%) DO (
			 "%@SYSLOGGEN%" -t:127.0.0.1 -p:%%~P -f:19 -s:6 -tg:"%~n0+" -m:"!@S_MSG2!" -q -hn:localhost 2>NUL | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )
 )
 %@VERBOSE_ON%
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Prepare Messages for SyslogGen Syslog Utility
 rem === Updated On: 23 Jun 2024 / 11 Aug 2019 / 23 Jun 2019
 rem ==========================================================================
:Prepare4Syslog
 rem %* = Syslog Message to be Cleaned Up

 SET @PREFIX=°°°%1
 SET @S_MSG=°°°%*
 SET @S_MSG=!@S_MSG:%@PREFIX% =!

:TrimLeadingSpaces
 IF "!@S_MSG:~0,1!"==" " (
	 SET @S_MSG=!@S_MSG:~1!
	 GOTO :TrimLeadingSpaces
 )

 SET @S_MSG2=!@S_MSG:\=\x5B!
 SET @S_MSG2=!@S_MSG2:"=\x22!
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Check if Scheduled Job is Already Running
 rem === Updated On: 03 Sep 2024 / 16 May 2018 / 05 Feb 2015
 rem ==========================================================================
:CheckSched
 rem %1 = Standard Search Criteria
 rem %2 = Advanced Search Criteria

 IF "%~3"=="$$" (SET "@R=") ELSE (SET "@R=/R")

 SET "@CHK=%2"
 IF DEFINED @CHK (
	 %@CHK_SCHED% 2>NUL | FIND /I "%~1" | FINDSTR /I %@R% /C:%2 >NUL
 ) ELSE (
	 %@CHK_SCHED% 2>NUL | FIND /I "%~1" >NUL
 )

 IF NOT ERRORLEVEL 1 GOTO :EOF
	 %@SET_SCHED%
	 IF NOT DEFINED @JOBTYPE SET "@JOBTYPE= // SCHEDULED JOB CHANGED"

 %@PAUSE_IF_DEBUG%
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
 IF /I "%~1"=="STARTED" CALL :GetTime @SCRIPT_BEG
 IF /I "%~1"=="FINISHED" (
	 IF DEFINED $CODEPAGE FOR /F "TOKENS=1* DELIMS=:" %%B IN ('CHCP %$CODEPAGE%') DO SET "@CHCP_STATUS= {Restoring Code Page:%%C}"
	 IF DEFINED @END_DEBUG_MODE %@END_DEBUG_MODE:"=%
	 TITLE %@CUSTOM_TITLE% [%USERDOMAIN%\%USERNAME%]   !@DEBUG_MODE!
	 DATEINFO -t %@SCRIPT_BEG#% -e "hr:min:sec.ms" -o "\n*** DURATION: " 2>NUL
 )
 NOW \n*** %@SCRIPTSTATUS%: %@VER% [\v] *** %@CHCP_STATUS%\n!@CRLF-%~1!
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Display Syntax Help if Required/Requested
 rem === Updated On: 30 Nov 2020 / 29 Nov 2020
 rem ==========================================================================
:HelpMessage
 ECHO Create a Rotating Schedule of SystemState Backups via ZIP
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [destination_file]
 ECHO  %~n0  [-h^|-?^|-h2^|-??]
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO       /S ..... Schedule the Job, But Don't Execute It
 ECHO       /U ..... Unschedule the Job Only, Without Executing It First
 ECHO       /N ..... Execute the Job, But Do Not Schedule It
 ECHO       /Z ..... Test/Diagnostics Mode {execute test configuration}
 ECHO       /D ..... Delete Current Archive Before Adding New Files
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 "" -n
	 ECHO  %~n0 MyBackup!@SS_EXT!
	 ECHO  %~n0 SpecialBackups!@SS_EXT!"
	 ECHO  %~n0 -u
	 ECHO  %~n0 -?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO:
	 ECHO  * Options are case-insensitive, and can be prefaced by "-" or "/".
	 ECHO:
	 ECHO  * Any parameters which contain spaces should be surrounded by quotes.
	 ECHO    Shortnames *can* be surrounded by quotes if you choose, but it is not
	 ECHO    mandatory by any means.
	 ECHO:
	 ECHO  * Test mode ^(/Z^) will result in a recorded errorlevel of *.
	 ECHO:
	 ECHO  * To save an archive from being pruned, it must be moved to a different
	 ECHO    folder, or saved with a name that does not include "SystemState-".
 )
 CALL :ShowStatus "FINISHED"
                                       