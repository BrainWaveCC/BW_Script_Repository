@ECHO OFF
 rem ==========================================================================
 rem === Obtain Latest Windows Build Numbers from Microsoft (Web)
 rem ==========================================================================
 rem
 rem Created On: 15 Jun 2024
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 16 Oct 2025 / 30 Sep 2025 / 14 Aug 2025 / 04 Oct 2024 / 26 Sep 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 10/2016 or later
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    Blat ................... http://www.blat.net/
 rem    CURL (non-native) ...... https://curl.se/windows/
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem
 rem    CURL ................... Native in Windows 10/2016+
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script downloads key "Windows XXXX Update History" pages from
 :::  Microsoft and parses them to determine the build information for each
 :::  version of Windows, starting with Win7/2008-R2.  This data is used to
 :::  generate build files that the various monitoring scripts related to
 :::  OpsLogs.BAT use to track patch management in the environment.
 :::
 :::  (Jun 2024) v1.0 -- Initial Release;
 :::
 :::  (Jun 2024) v1.1 -- Added support for newer Windows 11 releases;
 :::  -- Added a process for dating Windows 2000 and 2003 builds;
 :::
 :::  (Jul 2024) v1.2 -- Compare initial download to determine if extra
 :::  processing is required, and log to @NOUPDATE file as appropriate;
 :::
 :::  (Jul 2024) v2.0 -- Expanded the script documentation;
 :::  -- Moved logs to central logging folder under the \\system\Logs$ share;
 :::  -- Expanded the Job History Component and replacing the @NOUPDATE routine;
 :::  -- Allow the sending of mail to be enabled or disabled from command-line;
 :::  -- Reverted back to SORT from CMSORT;
 :::
 :::  (Sep 2024) v2.1 -- Enable updates to local syslogs if requested;
 :::  -- Refactoring of the scheduled jobs verification routine;
 :::  -- Created :LogCriticalFailure routine for early job failures;
 :::
 :::  (Oct 2024) v2.2 -- Verify internet access before trying to process files;
 :::
 :::  (Sep 2025) v2.3 -- Replaced instances of HEAD/TAIL/TYPE with READABLE;
 :::
 :::  (Oct 2025) v3.0 -- Added new links for newer versions of Windows;
 :::  -- Added a process to generate an updated mini build list;
 :::
 :::
 :::  SCRIPTING SYNTAX RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  CMD and Powershell syntax ...... https://ss64.com/
 :::  Windows Shell Scripting Tips ... https://www.dostips.com/
 :::  Batch Script Linter ............ https://github.com/tboy1337/Blinter/
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 15 Jun 2024
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 16 Oct 2025 / 29 Sep 2025 / 04 Oct 2024 / 26 Sep 2024 / 21 Jul 2024
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v3.0.0.300

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT" "%~dp0TimeStamp.BAT" FILEHASH.EXE READABLE.EXE
 SET #MSUTILS=CURL.EXE FINDSTR.EXE SCHTASKS.EXE SORT.EXE
 SET #O_UTILS=BLAT.EXE SYSLOGGEN.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES & GOTO :ExitBatch)

 rem -- Job Scheduling Variables (Override via CustomVariables.*.TXT)
 SET @JOBNAME=Obtain Windows Build Lists
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=00:11:00
 SET @JOBDATE=
 SET @JOBPATH="%~f0" %*
 SET @JOBTYPE=

 rem -- Build List Variables (Override via CustomVariables.*.TXT)
 SET @WIN10=https://support.microsoft.com/en-us/topic/windows-10-update-history-e6058e7c-4116-38f1-b984-4fcacfba5e5d
 SET @WIN11-21H2=https://support.microsoft.com/en-us/topic/windows-11-version-21h2-update-history-a19cd327-b57f-44b9-84e0-26ced7109ba9
 SET @WIN11-22H2=https://support.microsoft.com/en-us/topic/windows-11-version-22h2-update-history-ec4229c3-9c5f-4e75-9d6d-9025ab70fcce
 SET @WIN11-23H2=https://support.microsoft.com/en-us/topic/windows-11-version-23h2-update-history-59875222-b990-4bd9-932f-91a5954de434
 SET @WIN11-24H2=https://support.microsoft.com/en-us/topic/windows-11-version-24h2-update-history-0929c747-1815-4543-8461-0160d16f15e5
 SET @WIN11-25H2=https://support.microsoft.com/en-us/topic/windows-11-version-25h2-update-history-99c7f493-df2a-4832-bd2d-6706baa0dec0
 SET @SERVER2016=https://support.microsoft.com/en-us/topic/windows-10-and-windows-server-2016-update-history-4acfbc84-a290-1b54-536a-1c0430e9f3fd
 SET @SERVER2019=https://support.microsoft.com/en-us/topic/windows-10-and-windows-server-2019-update-history-725fc2e1-4443-6831-a5ca-51ff5cbcb059
 SET @SERVER2022=https://support.microsoft.com/en-us/topic/windows-server-2022-update-history-e1caa597-00c5-4ab9-9f3e-8212fe80b2ee
 SET @SERVER23H2=https://support.microsoft.com/en-us/topic/windows-server-version-23h2-update-history-68c851ff-825a-4dbc-857b-51c5aa0ab248
 SET @SERVER2025=https://support.microsoft.com/en-us/topic/windows-server-2025-update-history-10f58da7-e57b-4a9d-9c16-9f1dcd72d7d7
 SET @MODERN_WIN=WIN10 WIN11-21H2 WIN11-22H2 WIN11-23H2 WIN11-24H2 WIN11-25H2 SERVER2016 SERVER2019 SERVER2022 SERVER23H2 SERVER2025
 SET @SERVER2008=https://support.microsoft.com/en-us/topic/windows-server-2008-sp2-update-history-9197740a-7430-f69f-19ff-4998a4e8b25b
 SET @SERVER2008R2=https://support.microsoft.com/en-us/topic/windows-7-sp1-and-windows-server-2008-r2-sp1-update-history-720c2590-fd58-26ba-16cc-6d8f3b547599
 SET @SERVER2012=https://support.microsoft.com/en-au/topic/windows-server-2012-update-history-abfb9afd-2ebf-1c19-4224-ad86f8741edd
 SET @SERVER2012R2=https://support.microsoft.com/en-us/topic/windows-8-1-and-windows-server-2012-r2-update-history-47d81dd2-6804-b6ae-4112-20089467c7a6
 SET @LEGACY_WIN=SERVER2008 SERVER2008R2 SERVER2012 SERVER2012R2

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "S ." & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE)
 CALL :GetParams "U -" & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @UNSCHED=TRUE)
 CALL :GetParams "N @" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "Z #" & IF DEFINED @OK (SET @DEL_REPL=TRUE) ELSE (SET @DEL_REPL=)
 CALL :GetParams "D $" & IF DEFINED @OK (SET @NOSCHED=TRUE& SET @DEBUGMODE=TRUE)
 CALL :GetParams "T /" & IF DEFINED @OK (SET @TESTMINI=TRUE& SET @JOBTYPE= // MINI-TEST) ELSE (SET @TESTMINI=)
 CALL :GetParams "M  " & IF DEFINED @OK (SET @MAIL=TRUE)
 CALL :GetParams "Q  " & IF DEFINED @OK (SET @MAIL=FALSE)

 rem -- Set One-Off Legacy Build Dates
 SET @WIN5.0=2010-07-13     5.0.2195
 SET @WIN5.1=2014-04-08     5.1.2600
 SET @WIN5.2=2014-04-08     5.2.3790
 SET @WIN5.3=2018-04-10     5.2.4500

 rem -- Set Other Variables
 SET @DRV=%~d0
 SET @UPDATED=N& SET @UPD=---
 SET @COUNT_LEGACY=0
 SET @COUNT_MODERN=0
 SET @HEADER=;Official Windows Versions/Builds as of
 SET @MSG=%@HEADER% %@TODAY_EXP%
 SET @BUILD_INFO=%~dp0Input\[WindowsBuilds].TXT
 SET @LATEST_BUILDS=%~dp0Input\[WindowsBuilds-Latest].TXT
 SET @EXT_BUILD_LIST=%~dp0Input\[WindowsBuilds-Plus].TXT

 rem -- Standard Log & Output Variables
 SET @DIAGDIR=%TEMP%\%~n0\%@DIRSTAMP_R%
 SET @LOGPATH=%@STORAGE%\Logs\WinBuildInfo
 SET @LFORMAT=%@LOGPATH%\%~n0
 SET @TIMINGS=%@LFORMAT%.RECORDING.TXT
 SET @LOGFILE=%@LFORMAT%.%@FILESTAMP%
 FOR %%L IN (BUILDFILE TEMPFILE SUMMARY TEMPLOG SORTLOG COMPARISON REPLACEMENT) DO SET @%%L=%@LFORMAT%.%%L.%@FILESTAMP%
 SET @LOGLIST="%@LOGFILE%" "%@BUILDFILE%" "%@SUMMARY%" "%@COMPARISON%" "%@REPLACEMENT%" "%@SORTLOG%"
 SET @CLEANUP="%@TEMPLOG%" "%@TEMPFILE%"  "%@SUMMARY%" "%@COMPARISON%" "%@REPLACEMENT%" "%@SORTLOG%"
 FOR %%W IN (%@MODERN_WIN% %@LEGACY_WIN%) DO SET @%%~W_FILE=%@LOGPATH%\%@DIRSTAMP_R%\%%~W-BuildInfo.TXT

 rem -- Special Settings
 IF /I "%@MAIL%"=="TRUE" (SET @SM=Y) ELSE (SET @SM=N)
 IF DEFINED @DEBUGMODE SET @MODERN_WIN=SERVER2022 SERVER23H2 SERVER2025
 IF DEFINED @TESTMINI GOTO :Update-Mini-Build


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 16 Jun 2024
 rem ==========================================================================
:ScheduleJobs
 IF /I "%@NOSCHED%"=="TRUE" IF /I NOT "%@UNSCHED%"=="TRUE" (
	 SET @JOBTYPE= // ONE-TIME
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
 IF /I "%@UPDATESCHED%"=="TRUE" (!@SET_SCHED!) ELSE (CALL :CheckSched "%~f0" " %@JOBVRFY%$")
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
 rem === Verify Internet Access to Continue
 rem === Updated On: 04 Oct 2024
 rem ==========================================================================
:ValidateInternetAccess
 CURL --silent https://ipinfo.io/ip
 IF NOT ERRORLEVEL 1 GOTO :ValidateInternetAccess_END
	 ECHO *** CANNOT CONTINUE: NO INTERNET ACCESS ***
	 CALL :LogCriticalFailure ABORTED - NO INTERNET CONNECTION
	 GOTO :ExitBatch
:ValidateInternetAccess_END
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Set READABLE replacement Information
 rem === Updated On: 18 Jul 2024 / 16 Jun 2024 / 15 Jun 2024
 rem ==========================================================================
:GenerateReplacementInfo
 MD "%@LOGPATH%\%@DIRSTAMP_R%" >NUL 2>NUL
 IF DEFINED @DEL_REPL DEL "%@REPLACEMENT%" >NUL 2>NUL
 IF NOT EXIST "%@REPLACEMENT%" (
	 ECHO -KB;^&#9999;KB
	 ECHO - KB;^&#9999;KB
 ) >"%@REPLACEMENT%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Get Latest Build Info for Each Windows Version (v5.0 to v10.x)
 rem === Updated On: 21 Jul 2024 / 16 Jul 2024 / 17-18 Jun 2024
 rem ==========================================================================
:GetBuildInfo
 (FOR %%V IN (%@DIGITS%) DO IF DEFINED @WIN5.%%~V ECHO !@WIN5.%%~V!) >"%@TEMPFILE%"

 rem -- Get Updates for Server 2008/2008-R2/2012/2012-R2
 CALL :GetLegacyBuildDate "%@SERVER2008%"   "%@SERVER2008_FILE%"   6.0.6000 6.0.6001 6.0.6002 6.0.6003
 CALL :GetLegacyBuildDate "%@SERVER2008R2%" "%@SERVER2008R2_FILE%" 6.1.7600 6.1.7601
 CALL :GetLegacyBuildDate "%@SERVER2012%"   "%@SERVER2012_FILE%"   6.2.9200 6.2.9201 6.2.9202
 CALL :GetLegacyBuildDate "%@SERVER2012R2%" "%@SERVER2012R2_FILE%" 6.3.9600 6.3.9601

 rem -- Get Updates for Win10/Server2016+
 FOR %%V IN (%@MODERN_WIN%) DO CALL :GetBuild-n-Date "!@%%~V!" "!@%%~V_FILE!"


 rem ==========================================================================
 rem === Process Downloaded Files to Build New Lists
 rem === Updated On: 16 Oct 2025 / 21 Jul 2024 / 18-19 Jul 2024 / 16 Jul 2024
 rem ==========================================================================
:GenerateNewFiles
 CALL :ShowHeader GENERATING WINDOWS BUILD LISTS
 READABLE "%@TEMPFILE%" -a -e -f "." -o "%@SORTLOG%" 2>NUL
 SORT /R "%@SORTLOG%" /O "%@BUILDFILE%" 2>NUL

 rem -- Verify if Further Processing is Needed
 IF EXIST "%@EXT_BUILD_LIST%" (
	 READABLE "%@EXT_BUILD_LIST%" -a --sk "%@HEADER%" -o "%@COMPARISON%" 2>NUL
	 FILEHASH --XX64 -K "%@BUILDFILE%" "%@COMPARISON%"
	 IF NOT ERRORLEVEL 1 GOTO :ShowFooter
 )
 SET @UPDATED=Y& SET @UPD=NEW
 IF EXIST "%@BUILDFILE%" ( ECHO %@MSG% & TYPE "%@BUILDFILE%" ) >"%@EXT_BUILD_LIST%"

 rem -- Generate List of Latest Build Dates
 CALL :ShowHeader GETTING LATEST DATE INFO FOR ALL WINDOWS BUILDS
 CALL :GetLatestBuildDate "%@EXT_BUILD_LIST%" "%@TEMPFILE%"
 IF EXIST "%@TEMPFILE%" ( ECHO %@MSG% & TYPE "%@TEMPFILE%" ) >"%@LATEST_BUILDS%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate an Updated Mini Build List
 rem === Updated On: 16 Oct 2025
 rem ==========================================================================
:Update-Mini-Build
 CALL :ShowHeader UPDATE MINI BUILD LIST
 IF EXIST "%@BUILD_INFO%" (
	 READABLE "%@BUILD_INFO%" -a -e -f "." -o "%@TEMPFILE%" 2>NUL
	 FOR /F "TOKENS=1-3 DELIMS=. " %%B IN ('READABLE "%@BUILD_INFO%" -a -e -f "." 2^>NUL') DO SET #MINI-%%~B.%%~C.%%~D=TRUE
 ) ELSE ( TYPE NUL >"%@TEMPFILE%" )

 IF EXIST "%@LATEST_BUILDS%" FOR /F "TOKENS=2-4 DELIMS=. " %%B IN ('READABLE "%@LATEST_BUILDS%" -a -e -f "." 2^>NUL') DO IF NOT DEFINED #MINI-%%~B.%%~C.%%~D (
	 SET #MINI-%%~B.%%~C.%%~D=TRUE
	 ECHO %%~B.%%~C.%%~D >>"%@TEMPFILE%"
 )

 rem -- Sorting and Processing
 IF EXIST "%@TEMPFILE%" (
	 SORT "%@TEMPFILE%" /O "%@SORTLOG%" 2>NUL
	 READABLE "%@SORTLOG%" -a -e -x -f "^5.;^6." >"%@TEMPFILE%"
	 READABLE "%@SORTLOG%" -a -e -x -f "^10."   >>"%@TEMPFILE%"
	 ( ECHO %@MSG% & TYPE "%@TEMPFILE%" )       >"%@BUILD_INFO%"
 )

 rem -- Cleanup Timestamps
 CALL :ShowHeader CLEANUP TIMESTAMPS
 CALL "%~dp0TimeStamp.BAT" /T:@ /P:%~d0\Scripts
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Footer
 rem === Updated On: 16 Oct 2025 / 20-21 Jul 2024 / 18 Jul 2024
 rem ==========================================================================
:ShowFooter
 CALL :SaveJobHistory

 ( rem -- Create Standard and Diagnostic Footer
	 NOW \n\*%~n0 Job Completed - [\v] - %@VER%\n\*\n
	 IF /I "!@DIAGMODE!"=="TRUE" (
		 ECHO:
		 ECHO %@DIVIDER*%
		 SET
		 ECHO %@DIVIDER*%
		 ECHO:
	 )
	 ECHO %@DIVIDER~%
	 ECHO  URLs Downloaded [Legacy] ..................!@LC!
	 ECHO  URLs Downloaded [Modern] ..................!@MC!
	 ECHO  New Data Processed ........................ !@UPDATED!
	 ECHO  Send Email Notification ^(for new lists^) ... !@SM!
	 ECHO  Size of Full Build File ...............!@FS!
	 ECHO  Size of Summary Build File .............!@LS!
	 ECHO  Size of Mini Build File ................!@MS!
	 ECHO %@DIVIDER-%
	 ECHO  List Processing Started On .................. %@SCRIPT_BEG%
	 ECHO  List Processing Ended On .................... %@SCRIPT_END%
	 DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "dys hrs mins secs.ms" -o " Total Job Duration Was ...................... " 2>NUL
	 ECHO %@DIVIDER~%
	 ECHO:
	 ECHO:
 ) >"%@SUMMARY%" 2>&1
 TYPE "%@SUMMARY%" >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Report
 rem === Updated On: 16 Oct 2025 / 21 Jul 2024 / 18 Jul 2024 / 16 Jul 2024
 rem ==========================================================================
:FinalReport
 CALL :ShowHeader GENERATING FINAL REPORT
 ( rem -- Write to Log
	 FOR %%W IN (%@MODERN_WIN% %@LEGACY_WIN%) DO IF EXIST "%%~W" DIR "!@%%~W_FILE!" | FIND /I ".TXT"
	 FOR %%F IN ("%@BUILDFILE%" "%@TEMPFILE%" "%@SORTLOG%" "%@BUILD_INFO%" "%@EXT_BUILD_LIST%" "%@LATEST_BUILDS%") DO IF EXIST "%%~F" DIR "%%~F" | FIND /I ".TXT"
 ) >>"%@LOGFILE%" 2>&1
 TYPE "%@LOGFILE%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Mail Log File To Appropriate Group
 rem === Updated On: 18 Jul 2024
 rem ==========================================================================
:SendLog
 IF /I "%@MAIL%/%@UPDATED%"=="TRUE/Y" IF DEFINED @RCPT-TO (
	 ( rem -- Write to Log
		 ECHO:
		 ECHO:
		 ECHO Sending Logs to: %@RCPT-TO:-to =%
		 ECHO              on: !DATE! at !TIME!
		 ECHO:
		 BLAT -install %@MAILSERVER% %@MAILSENDER% 2 %@MAILPORT%
		 ECHO %@DIVIDER#%
		 ECHO:
		 ECHO:
	 ) >"%@TEMPLOG%" 2>&1
	 FOR %%O IN (CON "%@LOGFILE%") DO TYPE "%@TEMPLOG%" >>%%O 2>&1

	 ECHO:
	 BLAT "%@SUMMARY%" -f %@MAILSENDER% %@RCPT-TO% -s "%@JOBNAME% Job on %COMPUTERNAME%" -attach "%@LOGFILE%","%@TIMINGS%"
	 CALL :ForwardToSyslog "6" Mailed %~n0 Job Report on %COMPUTERNAME%: %@INFO% -- "%@LOGFILE%" >NUL
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Log Management/Maintenance (Or Copy Them for Debug Purposes)
 rem === Updated On: 18 Jul 2024
 rem ==========================================================================
:LogMaint
 CALL :ShowHeader PERFORMING FINAL LOG MAINTENANCE...

 IF /I "%DEBUG%"=="COPY" (
	 MD "%@DIAGDIR%" >NUL 2>NUL
	 FOR %%L IN (%@LOGLIST% %@CLEANUP%) DO IF EXIST %%L COPY %%L "%@DIAGDIR%" /Y
 )

 FOR %%L IN (%@LOGLIST%) DO IF EXIST %%L (
	 SET @THISLOG=%%L
	 COPY %%L !@THISLOG:%@FILESTAMP%=TXT! /Y
	 IF %%L=="%@LOGFILE%" (ECHO: & DIR %%L)
 )
 FOR %%L IN (%@CLEANUP%) DO IF EXIST %%L DEL %%L >NUL
 ECHO %@DIVIDER~%
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 15 Jun 2024
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display Section Header
 rem === Updated On: 17 Jun 2024
 rem ==========================================================================
:ShowHeader
 rem %* = Message to Display

 IF "%~1"=="" EXIT /B
 TITLE %*
 ECHO:
 ECHO:
 ECHO %@DIVIDER*%
 ECHO *** !TIME: =0! -- %*
 ECHO %@DIVIDER*%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Convert Date to YYYY-MM-DD
 rem === Updated On: 16 Jun 2024 / 15 Jun 2024
 rem ==========================================================================
:ConvertDate
 rem %1 = Obtain Date in "MMM DD, YYYY" format
 rem %2 = Variable to Save New Date

 IF "%~1"=="" EXIT /B
 IF "%~2"=="" EXIT /B

 SET @BADDATE=
 SET @ZDATE=%~1
 SET @ZDATE=!@ZDATE:, =/!
 SET @ZDATE=!@ZDATE:January =01/!
 SET @ZDATE=!@ZDATE:February =02/!
 SET @ZDATE=!@ZDATE:March =03/!
 SET @ZDATE=!@ZDATE:April =04/!
 SET @ZDATE=!@ZDATE:May =05/!
 SET @ZDATE=!@ZDATE:June =06/!
 SET @ZDATE=!@ZDATE:July =07/!
 SET @ZDATE=!@ZDATE:August =08/!
 SET @ZDATE=!@ZDATE:September =09/!
 SET @ZDATE=!@ZDATE:October =10/!
 SET @ZDATE=!@ZDATE:November =11/!
 SET @ZDATE=!@ZDATE:December =12/!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@ZDATE% -F "yyyy-mm-dd" -Q 2^>NUL') DO SET %~2=%%~d
 IF ERRORLEVEL 64 SET @BADDATE=TRUE
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Build Date info for Legacy Windows
 rem === Updated On: 20-21 Jul 2024 / 18 Jul 2024 / 17-18 Jun 2024
 rem ==========================================================================
:GetLegacyBuildDate
 rem %1 = Appropriate URL
 rem %2 = Filename to Store Data In
 rem %3 = Build Info (Optional = %4 - %9)

 IF "%~1"=="" EXIT /B
 IF "%~2"=="" EXIT /B
 IF "%~3"=="" EXIT /B

 CALL :ShowHeader GETTING WINDOWS BUILD INFO FOR %~nx2

 rem -- Download Build Info
 TYPE NUL >"%~2"
 CURL -f "%~1" -o "%~2"
 CALL :GetFileSize "%~2" @FILESIZE
 IF "!@FILESIZE!"=="0" ( ECHO *** NO DATA OBTAINED *** & EXIT /B )

 rem -- Process Build Info
 SET /A @COUNT_LEGACY+=1
 FOR /F "TOKENS=3 DELIMS=<>()&" %%U IN ('READABLE "%~2" -a -e -f " (Monthly Rollup); (OS Build Monthly Rollup)" -r "%@REPLACEMENT%" 2^>NUL') DO (
	 CALL :ConvertDate "%%~U" @BUILD_DATE
	 IF NOT DEFINED #%~3-!@BUILD_DATE! (
		 SET #%~3-!@BUILD_DATE!=TRUE
		 IF NOT DEFINED @BADDATE FOR %%A IN (%~3 %~4 %~5 %~6 %~7 %~8 %~9) DO ECHO !@BUILD_DATE!     %%~A>>"%@TEMPFILE%"
	 )
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Build Date info for Modern Windows (Win10/2016+)
 rem === Updated On: 18 Jul 2024 / 15-17 Jun 2024
 rem ==========================================================================
:GetBuild-n-Date
 rem %1 = Appropriate URL
 rem %2 = Filename to Store Data In

 IF "%~1"=="" EXIT /B
 IF "%~2"=="" EXIT /B

 CALL :ShowHeader GETTING WINDOWS BUILD INFO FOR %~nx2

 rem -- Download Build Info
 TYPE NUL >"%~2"
 CURL -f "%~1" -o "%~2"
 CALL :GetFileSize "%~2" @FILESIZE
 IF "!@FILESIZE!"=="0" ( ECHO *** NO DATA OBTAINED *** & EXIT /B )

 rem -- Process Build Info
 SET /A @COUNT_MODERN+=1
 FOR /F "TOKENS=3,5 DELIMS=<>()&" %%U IN ('READABLE "%~2" -a -e -f " (OS Build" -r "%@REPLACEMENT%" 2^>NUL') DO (
	 SET @ORIGINAL_LINE=%%U %%V
	 SET @BUILD_NUM=%%~V
	 CALL :ConvertDate "%%~U" @BUILD_DATE
	 SET @BUILD_NUM=!@BUILD_NUM:os builds os=!
	 SET @BUILD_NUM=!@BUILD_NUM:os build os=!
	 SET @BUILD_NUM=!@BUILD_NUM:os builds=!
	 SET @BUILD_NUM=!@BUILD_NUM:os build=!
	 SET @BUILD_NUM=!@BUILD_NUM:and=!
	 FOR %%S IN (!@BUILD_NUM!) DO IF NOT DEFINED #%%~S (
		 SET #%%~S=TRUE
		 IF NOT DEFINED @BADDATE ECHO !@BUILD_DATE!    10.0.%%~S>>"%@TEMPFILE%"
	 )
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Obtain Latest Date Info for Each Windows Build
 rem === Updated On: 18 Jun 2024 / 17 Jun 2024
 rem ==========================================================================
:GetLatestBuildDate
 rem %1 = Main File
 rem %2 = Filename to Store Data In

 IF "%~1"=="" EXIT /B
 IF "%~2"=="" EXIT /B

 ( FOR /F "TOKENS=1-5 EOL=; DELIMS=. " %%D IN ('TYPE "%~1" 2^>NUL') DO (
	 IF %%~E LEQ 9 (SET @MYBUILD= %%~E.%%~F.%%~G) ELSE (SET @MYBUILD=%%~E.%%~F.%%~G.%%~H)
	 IF NOT DEFINED #LATEST#!@MYBUILD! (
		 SET #LATEST#!@MYBUILD!=TRUE
		 ECHO %%~D    !@MYBUILD!
	 )
 )) >"%~2"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get File Size
 rem === Updated On: 18 Jul 2024 / 15-16 Jun 2024
 rem ==========================================================================
:GetFileSize
 rem %1 = Filename to Evaluate
 rem %2 = Variable to store size in

 IF NOT EXIST "%~1"=="" EXIT /B
 IF "%~2"=="" EXIT /B

 SET %~2=0
 FOR %%S IN ("%~1") DO SET %~2=%%~zS
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 18 Jul 2024
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Determine if Parameter is a Valid Integer, Or Set to Zero
 rem === Updated On: 18 Jul 2024
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
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Use CheckParams.exe to Capture Selected Parameters
 rem === Updated On: 16 Jun 2024
 rem ==========================================================================
:GetParams
 rem %1 = Parameters to Search For
 rem %2 = Variable to Set

 SET @OK=& IF "%~1"=="" EXIT /B
 FOR /F "TOKENS=2-3*" %%v IN ('CHECKPARAMS -q -a -c "%~1" -s %@ALL_PARAMS% 2^>NUL') DO IF /I "%%~v"=="TRUE" (
	 SET @OK=T
	 SET @REQ=T
	 IF NOT "%~2"=="" SET %~2=%%~x
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Pad Variable Content to the Left/Right for Display in Logs
 rem === Updated On: 18 Jul 2024
 rem ==========================================================================
:PadLeft
:PadRight
 rem %1 = Variable to Store New Content
 rem %2 = Existing Value to Pad
 rem %3 = Character to use as padding [typically "." or " "]
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
 EXIT /B


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
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Update Job Execution Stats
 rem === Updated On: 16 Oct 2025 / 30 Sep 2025 / 21 Jul 2024 / 18-20 Jul 2024 / 16 Jun 2024
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 CALL :GetTime  @SCRIPT_END
 CALL :GetFileSize "%@EXT_BUILD_LIST%" @F_SIZE
 CALL :GetFileSize "%@LATEST_BUILDS%"  @L_SIZE
 CALL :GetFileSize "%@BUILD_INFO%"     @M_SIZE

 CALL :PadLeft  @LC "%@COUNT_LEGACY%"  "."  2
 CALL :PadLeft  @MC "%@COUNT_MODERN%"  "."  2
 CALL :PadLeft  @FS "!@F_SIZE!"        "."  6
 CALL :PadLeft  @LS "!@L_SIZE!"        "."  5
 CALL :PadLeft  @MS "!@M_SIZE!"        "."  5

 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 SET @JOBHISTORY=%@JOBNAME% // URLS [LEGACY.%@LC% MODERN.%@MC%] // LISTS [%@DRV% FULL.%@FS% LATEST.%@LS% MINI.%@MS%] %@UPD% // MAIL=%@SM% // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %~n0 %@VERSION%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('READABLE "%@TIMINGS%" -F "/" --TO -Q 2^>NUL') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY "%@TIMINGS%" "!@OLDTIME!" /V /Y >CON
	 READABLE "!@OLDTIME!" --ST -%@MINROWS% -O "%@TIMINGS%"
	 ECHO:
	 CALL :ForwardToSyslog "5" %@JOBNAME%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>"%@LOGFILE%" 2>&1

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@TRUNCATED! >>"%@TIMINGS%" 2>>"%@LOGFILE%"
 %@VERBOSE_ON%
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 25 Sep 2024 / 18 Jul 2024
 rem ==========================================================================
:ForwardToSyslog
 rem %1 = Syslog Severity Level (RFC 3164)
 rem %* = Message to Send to Display and Send to Syslog Server

 SET @S_MSG=%*& IF "%~2"=="" SET @S_MSG=%1 - This is a Syslog Test Message from %@VER%
 SET @SEV=6
 FOR %%a IN (0 EMERGENCY) DO   IF /I "%~1"=="%%~a" SET @SEV=0
 FOR %%a IN (1 ALERT) DO       IF /I "%~1"=="%%~a" SET @SEV=1
 FOR %%a IN (2 CRITICAL) DO    IF /I "%~1"=="%%~a" SET @SEV=2
 FOR %%a IN (3 ERROR) DO       IF /I "%~1"=="%%~a" SET @SEV=3
 FOR %%a IN (4 WARNING) DO     IF /I "%~1"=="%%~a" SET @SEV=4
 FOR %%a IN (5 NOTICE) DO      IF /I "%~1"=="%%~a" SET @SEV=5
 FOR %%a IN (6 INFORMATION) DO IF /I "%~1"=="%%~a" SET @SEV=6
 FOR %%a IN (7 DEBUG) DO       IF /I "%~1"=="%%~a" SET @SEV=7

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
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Prepare Messages for SyslogGen Syslog Utility
 rem === Updated On: 18 Jul 2024
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
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Check if Scheduled Job is Already Running
 rem === Updated On: 03 Sep 2024 / 16 Jun 2024
 rem ==========================================================================
:CheckSched
 rem %1 = Standard Search Criteria
 rem %2 = Advanced Search Criteria

 IF "%~3"=="$$" (SET @R=) ELSE (SET @R=/R)

 SET @CHK=%2
 IF DEFINED @CHK (
	 %@CHK_SCHED% 2>NUL | FIND /I "%~1" | FINDSTR /I %@R% /C:%2 >NUL
 ) ELSE (
	 %@CHK_SCHED% 2>NUL | FIND /I "%~1" >NUL
 )

 IF NOT ERRORLEVEL 1 EXIT /B
	 %@SET_SCHED%
	 IF NOT DEFINED @JOBTYPE SET @JOBTYPE= // SCHEDULED JOB CHANGED

 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Set/Display Script Version and Execution Status
 rem === Updated On: 22 Sep 2025 / 18 Jul 2024 / 16 Jun 2024
 rem ==========================================================================
:ShowStatus
 rem %1 = Run Status of Script
 rem %2 = Current Application Version

 IF NOT DEFINED @DATEFMT SET @DATEFMT=-F "mm/dd/yyyy hh:nn:ss.zzz"
 SET @SCRIPTSTATUS=%~1& IF "%~1"=="" SET @SCRIPTSTATUS=RUNNING
 IF NOT "%~2"=="" (SET @VER=%~nx0 %~2&     SET @VERSION=%~2)
 IF NOT "%~3"=="" (SET @VER=%~nx0 %~2 %~3& SET @VERSION=%~2 %~3)
 IF /I "%~1"=="STARTED" CALL :GetTime @SCRIPT_BEG
 IF /I "%~1"=="FINISHED" (
	 IF DEFINED $CODEPAGE FOR /F "TOKENS=1* DELIMS=:" %%B IN ('CHCP %$CODEPAGE%') DO SET @CHCP_STATUS= {Restoring Code Page:%%C}
	 IF DEFINED @END_DEBUG_MODE %@END_DEBUG_MODE:"=%
	 TITLE %@CUSTOM_TITLE% [%USERDOMAIN%\%USERNAME%]   !@DEBUG_MODE!
	 DATEINFO -t %@SCRIPT_BEG#% -e "hr:min:sec.ms" -o "\n*** DURATION: " 2>NUL
 )
 NOW \n*** %@SCRIPTSTATUS%: %@VER% [\v] *** %@CHCP_STATUS%\n!@CRLF-%~1!
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display Syntax Help if Required/Requested
 rem === Updated On: 16 Oct 2025 / 18 Jul 2024 / 16 Jun 2024 / 15 Jun 2024
 rem ==========================================================================
:HelpMessage
 ECHO Obtain Latest Windows Build Numbers from Microsoft (Web)
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0 [optional]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO  /S,  .  ..... Schedule the Job, But Don't Execute It
 ECHO  /U,  -  ..... Unschedule the Job Only, Without Executing It First
 ECHO  /N,  @  ..... Execute the Job without Scheduling It
 ECHO  /Z,  #  ..... Delete and Recreate the Replacement Input File
 ECHO  /D,  $  ..... Debug with a subset of Lists
 ECHO  /T,  /        Just Generate the Mini List
 ECHO  /M,     ..... Enable Email with Default Settings
 ECHO  /Q,     ..... Do Not Send Email
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 @
	 ECHO  %~n0 /D /N
	 ECHO  %~n0 /M
	 ECHO  %~n0 -?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
 )
 CALL :ShowStatus "FINISHED"
                                                                                      