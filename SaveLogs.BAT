@ECHO OFF
 rem ==========================================================================
 rem === Save Event Logs (using PSLOGLIST) and Firewall Rules (using NetSH)
 rem ==========================================================================
 rem
 rem Created On: 03 Apr 2001
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 13 Jan 2026 / 01 Jan 2026 / 30 Sep 2025 / 18 Aug 2025
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    InfoZip Utilities ...... http://sourceforge.net/projects/infozip/files/
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem
 rem    PSTOOLS ................ https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script dumps a copy of the selected Event Logs to a file, using the
 :::  current date, with the option of clearing the Event Logs if "-c" is used
 :::  as a parameter.
 :::
 :::  This version will work with whatever Eventlogs are in use on the system.
 :::  Some error checking is performed to verify which Logs actually contain
 :::  data.
 :::      Application
 :::      System
 :::      Security
 :::      DNS Server                (only on AD or DNS servers)
 :::      Directory Service         (only on AD servers)
 :::      File Replication Service  (only on AD servers)
 :::      Any Other Logs found via the REG command
 :::
 :::  This script has now been modified to save any FAILED LOGON attempts into
 :::  a separate file (EventLog-Failure.TXT) for easier parsing by the Daily
 :::  Server Operations Log script (OpsLogs.BAT).
 :::
 :::  (Nov 2010) Changed the default log extension of the reports from .LOG to
 :::  .TXT so that the reports that are mailed to mobile devices can be read
 :::  automatically. (Not too many devices can natively handle .LOG files)
 :::
 :::  (Dec 2011) Simplified the job scheduling section by way of environment
 :::  variables for verifying whether to use SCHTASKS or the AT command.
 :::
 :::  (Dec 2012) Made it possible for the scheduled tasks to be stored in their
 :::  own folder, rather than the default root folder of the Task Scheduler.
 :::
 :::  (Oct 2013) As of version 2.10, the delimiter for all parameters can be
 :::  either the "-" or the "/" character.  This includes the help parameters.
 :::
 :::  (Dec 2013) As of version 3.0, this script also uses the NETSH command to
 :::  save the current list of firewall rules from the Windows Firewall.  The
 :::  NetSH functionality will only work with Windows Vista/2008 and above.
 :::
 :::  (Mar 2015) v3.2 -- Log files are now compressed and stored in ZIP format
 :::  to ease the burden on storage.
 :::
 :::  (May 2018) v4.0 -- Changed the HELP routine to use FINDSTR;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Support for SysLog and JobHistory have been added to this script;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v4.1 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v4.2 -- Removed AT command support;
 :::
 :::  (Oct 2018) v4.3 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Mar 2019) v4.4 -- Enabled Code Page 1252 Support;
 :::  -- Record additional attributes in the Job History log;
 :::  -- Prevent DEBUG MODE data from being stored in the .RECORDING.TXT file;
 :::
 :::  (Oct 2019) v4.5 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v4.6 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Jan 2020) v4.7 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Added a routine for validating integer parameters;
 :::  -- Refactored the :Prepare4Syslog routine;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::
 :::  (May 2020) v4.8 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Jul 2020) v5.0 -- The list of potential event log files which is
 :::  derived from the registry, is now expanded by way of a recursive search;
 :::
 :::  (Nov 2020) v5.1 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::  -- Corrected EventLog archive history to 36 hours, default, vs ALL time);
 :::  -- Added the -A paramter to support generating archive of entire log;
 :::
 :::  (Jan 2022) v5.2 -- Modify the @NAMECHK verification to include \ prefix;
 :::
 :::  (Oct 2023) v5.3 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v5.4 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::  (Sep 2024) v5.5 -- Enable updates to local syslogs if requested;
 :::  -- Refactoring of the scheduled jobs verification routine;
 :::
 :::  (Sep 2025) v5.6 -- Replaced instances of HEAD/TAIL/TYPE with READABLE;
 :::
 :::  (Jan 2026) v5.7 -- Update Syslog logging routine for script metrics;
 :::
 :::
 :::  WINDOWS SHELL SCRIPTING RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  CMD and Powershell syntax ...... https://ss64.com/
 :::  Windows Shell Scripting Tips ... https://www.dostips.com/
 :::  Batch Script Linter ............ https://github.com/tboy1337/Blinter/
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 30 Nov 2020 / 15 May 2018
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 30 Sep 2025 / 26 Sep 2024 / 10 May 2024 / 10 Dec 2020
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v5.7.0.570

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT"
 SET #MSUTILS=FINDSTR.EXE NETSH.EXE SCHTASKS.EXE
 SET #O_UTILS=PSLOGLIST.EXE SYSLOGGEN.EXE ZIP.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES & GOTO :ExitBatch)

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @SKIPERR=A Kerberos service ticket was requested.
 SET @PARAMS=%1 %2 %3 %4 %5 %6 %7 %8 %9
 SET @H_PARAM=-H
 SET @EVENT_HISTORY=72
 SET @FAILED_HISTORY=36
 SET @CLEARCMD=
 SET @CLEARLOGS=FALSE

 rem -- Job Scheduling Variables
 SET @JOBNAME=Save Event Logs
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=01:00:00
 SET @JOBDATE=
 SET @JOBPATH=%~f0
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- EventLog and Registry Variables
 SET @LOGS=
 SET @EVENTKEY=HKLM\SYSTEM\CurrentControlSet\Services\Eventlog

 IF %@OSBUILD% LEQ 3790 (
	 FOR /F "TOKENS=6 DELIMS=\" %%L IN ('REG QUERY "%@EVENTKEY%" /F "" /K') DO SET #LOG.%%~L=%%~L
 ) ELSE (
	 FOR /F "TOKENS=5* DELIMS=\" %%K IN ('REG QUERY "%@EVENTKEY%" /S ^| FIND /I "\EventLog\"') DO SET #LOG.%%~L=%%~L
 )

 rem -- Standard Log Variables
 SET @LOGBASE=%@STORAGE%\Logs
 SET @LOGPATH=%@LOGBASE%\EventLogs
 SET @LOGFILE=%@LOGPATH%\EventLog.%@FILESTAMP%
 SET @TIMINGS=%@LOGPATH%\EventLog.RECORDING.TXT
 SET @FAILLOG=%@LOGPATH%\EventLog-Failure.%@FILESTAMP%

 rem -- Logs for Capturing Current Firewall Rules
 SET @FW_PATH=%@LOGBASE%\WinFW
 SET @LOGFILE_FW=%@FW_PATH%\WinFW_Rules.%@FILESTAMP%

 rem -- Standard Zip Variables
 SET @ZIPPATH=%@LOGBASE%\ZipFiles
 SET @ARCHIVE=%@ZIPPATH%\%COMPUTERNAME%-%~n0.%@ZIPSTAMP%
 SET @LOGLIST="%@FAILLOG%" "%@LOGFILE%" "%@LOGFILE_FW%"
 SET @CLEANUP="%@LOGFILE%"

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "D @" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "U -" & IF DEFINED @OK (SET @SCHEDULEONLY=TRUE&  SET @UNSCHED=TRUE)
 CALL :GetParams "N $" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "S ." & IF DEFINED @OK (SET @SCHEDULEONLY=TRUE&  SET @UPDATESCHED=TRUE)
 CALL :GetParams "C *" & IF DEFINED @OK (SET @CLEARLOGS=TRUE&     SET @CLEARCMD=-C)
 CALL :GetParams "A #" & IF DEFINED @OK (SET @EVENT_HISTORY=&     SET @H_PARAM=)

 rem -- Set Time Range Description
 IF DEFINED @EVENT_HISTORY (SET @HISTORY_MSG=Last %@EVENT_HISTORY% Hours) ELSE (SET @HISTORY_MSG=Entire Log Timeframe)
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 10 May 2024 / 22 Jan 2022 / 09 Mar 2019
 rem ==========================================================================
:ScheduleJobs
 IF /I NOT "%@SCHEDULEONLY%"=="TRUE" IF /I "%@NOSCHED%"=="TRUE" (
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
 rem === Generate Log Headers for EventLogs and Firewall Rules
 rem === Updated On: 04 Dec 2020 / 05 Feb 2015
 rem ==========================================================================
:LogHeader
 FOR %%V IN (%@LOGPATH% %@FW_PATH%) DO IF NOT EXIST "%%~V" MD "%%~V"

 ( rem -- Write to Log for EventLogs
	 ECHO [Generated By %@VER%]
	 ECHO %@DIVIDER*%
	 ECHO *** %@HISTORY_MSG% of EventLogs for %COMPUTERNAME% as of %@TIMESTAMP%
	 ECHO %@DIVIDER*%
	 ECHO:
 ) >>%@LOGFILE% 2>&1

 ( rem -- Write to Log for Firewall Rules
	 ECHO [Generated By %@VER%]
	 ECHO %@DIVIDER*%
	 ECHO *** Current Windows Firewall Rules for %COMPUTERNAME% as of %@TIMESTAMP%
	 ECHO %@DIVIDER*%
	 ECHO:
 ) >>%@LOGFILE_FW% 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Capture Failed Logons for Previous ## hours (Default = 36)
 rem === Updated On: 04 Dec 2020 / 07 Mar 2019
 rem ==========================================================================
:FailedLogons
 SET @FAILED_MSG=Archiving Last %@FAILED_HISTORY% Hours of Logon-Related Failures from Security Logs

	 ECHO %@FAILED_MSG%...

 ( rem -- Write to Log
	 ECHO %@DIVIDER*%
	 ECHO *** Logon Failure Events for %COMPUTERNAME% as of %DATE% @ %TIME%
	 ECHO %@DIVIDER*%
	 FOR /F "TOKENS=5* DELIMS=," %%S IN ('PSLOGLIST -H %@FAILED_HISTORY% -S SECURITY %@PSACCEPT% ^| FINDSTR "failed failure" ^| FIND /I /V "%@SKIPERR%"') DO ECHO %%S %%T
	 ECHO %@DIVIDER-%
	 ECHO [Generated By %@VER%]
	 ECHO:
 ) >>"%@FAILLOG%" 2>NUL

 ECHO FINISHED %@FAILED_MSG%!
 ECHO:
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Archive All Event Logs
 rem === Updated On: 18 Aug 2025 / 04 Dec 2020 / 02 Jul 2020
 rem ==========================================================================
:SaveEventLogs
 ECHO Archiving %@HISTORY_MSG% EventLogs on %COMPUTERNAME%...
 ECHO %@DIVIDER-%
 FOR /F "TOKENS=2 DELIMS==" %%V IN ('SET "#LOG." 2^>NUL') DO CALL :DumpLogs "%%~V"
 ECHO %@DIVIDER-%
 ECHO FINISHED Archiving %@HISTORY_MSG% EventLogs on %COMPUTERNAME%...
 ECHO:
 IF /I "%@CLEARLOGS%"=="TRUE" (
	 ECHO PLEASE NOTE: All Event Logs on %COMPUTERNAME% were Cleared Out...
	 ECHO:
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate List of Current Firewall Rules
 rem === Updated On: 05 Feb 2015 / 19 Dec 2013
 rem ==========================================================================
:SaveFirewallRules
 ECHO Archiving All Firewall Rules on %COMPUTERNAME%...

 ( rem -- Write to Log
	 NETSH ADVFIREWALL FIREWALL SHOW RULE NAME=ALL
	 ECHO -------------------- End of Firewall Rules --------------------
	 ECHO:
 ) >>"%@LOGFILE_FW%" 2>NUL

 ECHO FINISHED Archiving All Firewall Rules on %COMPUTERNAME%...
 ECHO:
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Log Footers for EventLogs and Firewall Rules
 rem === Updated On: 24 Mar 2015 / 05 Feb 2015
 rem ==========================================================================
:LogFooter
 FOR %%S IN ("%@LOGFILE%") DO SET /A @LOGSIZE=500 + %%~zS
 FOR %%S IN ("%@LOGFILE_FW%") DO SET /A @LOGSIZE_FW=372 + %%~zS

 ( rem -- Write to Log for EventLogs
	 ECHO:
	 ECHO:
	 NOW Batch Processing Completed - [Log Size: ~%@LOGSIZE% bytes]
	 ECHO %@DIVIDER*%
	 ECHO ***          DAILY EVENTLOG ARCHIVAL SCRIPT HAS FINISHED RUNNING...         ***
	 ECHO %@DIVIDER*%
	 ECHO [Generated By %@VER%]
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1

 ( rem -- Write to Log for Windows Firewall Rules
	 ECHO:
	 ECHO:
	 NOW Batch Processing Completed - [Log Size: ~%@LOGSIZE_FW% bytes]
	 ECHO %@DIVIDER*%
	 ECHO ***       DAILY FIREWALL RULES ARCHIVAL SCRIPT HAS FINISHED RUNNING...      ***
	 ECHO %@DIVIDER*%
	 ECHO [Generated By %@VER%]
	 ECHO:
 ) >>"%@LOGFILE_FW%" 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Compress Log Files
 rem === Updated On: 24 Mar 2015
 rem ==========================================================================
:ZipLogs
 ( rem -- Write to Log
	 PUSHD "%@LOGPATH%"
	 ZIP -9 -v -T -j "%@ARCHIVE%" %@LOGLIST%
	 POPD
	 ECHO:
	 ECHO Job Logs Compressed -- [!DATE! at !TIME!]
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Log Management/Maintenance (Or Copy Them for Debug Purposes)
 rem === Updated On: 15 May 2018 / 24 Mar 2015
 rem ==========================================================================
:LogMaint
 CALL :SaveJobHistory
 ECHO PERFORMING FINAL LOG MAINTENANCE...

 IF /I "%DEBUG%"=="COPY" FOR %%L IN (%@LOGLIST% %@CLEANUP%) DO IF EXIST %%L COPY %%L "%TEMP%" /Y

 FOR %%L IN (%@LOGLIST%) DO IF EXIST %%L (
	 SET @THISLOG=%%L
	 COPY %%L !@THISLOG:%@FILESTAMP%=TXT! /Y
	 IF %%L=="%@FAILLOG%" (ECHO: & TYPE %%L & DIR %%L) ELSE (DIR %%L)
 )
 FOR %%L IN (%@CLEANUP%) DO IF EXIST %%L DEL %%L >NUL
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 04 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Dump Each Valid Event Log
 rem === Updated On: 04 Dec 2020 / 19 Jan 2019
 rem ==========================================================================
:DumpLogs
 rem %1 = Current Log
 ECHO  Currently Archiving the "%~1" Event Log...

 ( rem -- Write to Log
	 PSLOGLIST -s "%~1" %@H_PARAM% %@EVENT_HISTORY% %@PSACCEPT% %@CLEARCMD%
	 ECHO -------------------- End of "%~1" Log --------------------
	 ECHO:
 ) >>"%@LOGFILE%" 2>NUL

 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 16 Oct 2023 / 14 May 2018
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 EXIT /B


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
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Use CheckParams.exe to Capture Selected Parameters
 rem === Updated On: 21 Jan 2020
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
 rem === Updated On: 30 Sep 2025 / 15 Oct 2019 / 09 Mar 2019
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 ECHO UPDATING JOB HISTORY.....
 FOR /F "TOKENS=4" %%S IN ('DIR "%@ARCHIVE%" ^| FIND /I ".ZIP"') DO SET @ZIPSIZE=%%S

 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @ZS "!@ZIPSIZE!" "." 11
 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 SET @JOBHISTORY=%@JOBNAME% // ZIP SIZE.%@ZS% // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %~n0 %@VERSION%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('READABLE "%@TIMINGS%" -F "/" --TO -Q 2^>NUL') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY "%@TIMINGS%" "!@OLDTIME!" /Y >CON
	 READABLE "!@OLDTIME!" --ST -%@MINROWS% -O "%@TIMINGS%" 2>&1
	 ECHO:
	 CALL :ForwardToSyslog "5" %@JOBNAME%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>"%@LOGFILE%" 2>&1

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@TRUNCATED! >>"%@TIMINGS%" 2>&1
 %@VERBOSE_ON%
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 13 Jan 2026 / 01 Jan 2026 / 25 Sep 2024 / 13 Jan 2020
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
			 "%@SYSLOGGEN%" -t:!@SYSLOG%%~s! -p:!@S_PORT! -f:19 -s:!@SEV! -tg:"%~n0" -m:"!@S_MSG2!" -q -hn:%@LOCALHOST% 2>NUL | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )

	 IF /I "%@SCRIPT_METRICS%"=="TRUE" (
		 FOR %%P IN (%@MY_SYSLOG_PORTS%) DO (
			 "%@SYSLOGGEN%" -t:127.0.0.1 -p:%%~P -f:19 -s:6 -tg:"%~n0+" -m:"%DATE% at %TIME: =0% -- !@S_MSG2!" -q -hn:localhost 2>NUL | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )
 )
 %@VERBOSE_ON%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Prepare Messages for Syslog Utility (SyslogGen)
 rem === Updated On: 23 Jun 2024 / 19 Jan 2020 / 14 May 2018
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
 rem === Updated On: 03 Sep 2024 / 15 May 2018 / 05 Feb 2015
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
 rem === Updated On: 22 Sep 2025 / 16 Oct 2023 / 24 Dec 2019
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
 rem === Updated On: 04 Dec 2020 / 30 Nov 2020 / 19 Jan 2020
 rem ==========================================================================
:HelpMessage
 ECHO Save and/or Clear Event Logs (using PSLOGLIST)
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [options]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO  /S,  .  ..... Schedule the Job, But Don't Execute It
 ECHO  /D,  @  ..... Execute the Job without Scheduling It
 ECHO  /N,  $  ..... Execute the Job, and Update the Schedule
 ECHO  /U,  -  ..... Unschedule the Job Only, Without Executing It First
 ECHO  /A,  #  ..... Archive All Logs  (default = last 36 hours)
 ECHO  /C,  *  ..... Clear Existing Logs
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 -c
	 ECHO  %~n0 -?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO:
	 ECHO  * Options are case-insensitive, and can be prefaced by "-" or "/".
 )
 CALL :ShowStatus "FINISHED"
                                                                                                  