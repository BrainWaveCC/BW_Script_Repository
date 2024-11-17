@ECHO OFF
 rem ==========================================================================
 rem === Manage Retention of Archived SQL and Other Database Backups
 rem ==========================================================================
 rem
 rem Created On: 29 Feb 2012
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 26 Sep 2024 / 03 Sep 2024 / 28 Jul 2024 / 10 May 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2003 and later
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    Blat ................... http://www.blat.net/
 rem    DIFF ................... http://gnuwin32.sourceforge.net/packages/diffutils.htm
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem
 rem    CHOICE ................. Native in Windows 2003+ / Reskit in NT/2000
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    ReplicationInfo.TXT .... List of source and destination folder(s)
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script was originally created to manage backups with specific
 :::  retention requirements, such as SQL or TFS backups.  It has been expanded
 :::  to support various general data backups that have multi-level, long-term
 :::  retention policies, such as the following:
 :::
 :::  -- 30 days of Daily backups
 :::  -- 12 months of Weekly Backups
 :::  -- 52 weeks of Weekly backups
 :::
 :::  This script differs from the Replicate-Files.BAT script in that it
 :::  supports the deletion of old files from both source and destination,
 :::  based on user-definied criteria.
 :::
 :::  (Mar 2012) Added support for skipping the file/folder deletion routines
 :::  entirely, by setting the appropriate @KEEP_ variable to 9999.
 :::
 :::  (Apr 2012) v3.6 -- synchronized several subroutines across
 :::  the entire family of SQL*.BAT and *Archive*.BAT scripts, including the
 :::  routines for calculating/displaying free disk space before and after
 :::  copy/delete operations.
 :::
 :::  (Sep 2012) v4.0 -- added a routine for sending alert emails
 :::  whenever a copy failure has been detected. The @ALERT-TO variable has
 :::  been added to allow destinations which differ from the normal job status
 :::  address.
 :::
 :::  (Nov 2012) Added a new variable, @SILENT-ON-ZERO, v4.2, to
 :::  allow the suppression of "ZERO FILES COPIED" error alerts if no source
 :::  files were found for copying to the destination.
 :::
 :::  (Nov 2012) v4.4 -- Added an option for a delay between scheduled job
 :::  time and actual job execution, using the @JOBDELAY variable.  Also
 :::  expanded the logging of environment variables for diagnostics, including
 :::  the indication of whether XCOPY or ROBOCOPY is being used for a particular
 :::  job.
 :::
 :::  (Nov 2012) Changed the way the parameters are scheduled, substituting
 :::  a high ASCII character for quotation marks, since several versions of
 :::  Windows (including Windows 8) have a bug in the job scheduler where
 :::  they won't properly parse parameters with quotation marks.
 :::
 :::  (Dec 2012) Made it possible for the scheduled tasks to be stored in their
 :::  own folder, rather than the default root folder of the Task Scheduler.
 :::
 :::  (Aug 2013) A generated scheduled task can now be deleted by using a
 :::  command-line parameter.  Additionally, the script will now generate an
 :::  entry via email and the logfile if the source folder is not accessible.
 :::
 :::  (Sep 2013) v5.0 -- The DIFF.exe port from Unix was added to
 :::  improve the "some files NOT copied" error alert message, by providing
 :::  a list of the files which were not copied successfully.  Made other
 :::  improvements to the general job reporting display routines.
 :::
 :::  (Sep 2013) v5.1 -- The TIMINGS Logfile will be reduced to the minimum
 :::  row size whenever it exceeds the maximum log row size, as defined by the
 :::  following variables:  %@MAX_LOG_ROWS% and %@MIN_LOG_ROWS%
 :::
 :::  (Oct 2013) v5.4 -- The delimiter for all parameters can be either the
 :::  "-" or the "/" character.  This includes the help parameters.
 :::
 :::  (Nov 2013) v6.0 -- the script will now display any currently scheduled
 :::  RetainBackups.BAT jobs on the current system, when the list of valid
 :::  jobs is displayed.  This requires an elevated prompt in 2008 and later
 :::  editions of Windows.
 :::
 :::  (Feb 2014) v6.2 -- Added the capability to send log data to one or more
 :::  Syslog servers using the SyslogGen or NeoLog utilities in conjunction
 :::  with the @SYSLOGx environment variables.
 :::
 :::  (Mar 2014) v6.3 -- Upgraded the DebugMode options to add another
 :::  variable (@PRINT_IF_DEBUG). Also revamped the routines for logging to
 :::  Syslog servers.
 :::
 :::  (Dec 2014) v6.7 -- Added the ability to select from a list of possible
 :::  source folders for a single job.  The last valid folder in the list is
 :::  selected for the job.  The letters A through K are valid variables for
 :::  the list elements. (e.g. @SOURCE1A to @SOURCE1K)
 :::
 :::  (Jan 2015) v6.8 -- Updated to use timestamped logfiles, managed with the
 :::  new logfile maintenance routine.
 :::
 :::  (Mar 2015) v6.10 -- Migrated more variables to SetDrive.BAT
 :::
 :::  (Mar 2015) v6.11 -- Track total elapsed time of backup job using a new
 :::  version of DATEINFO
 :::
 :::  (Nov 2015) v6.13 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Apr 2017) v7.0 -- Enabled Mapped Drives for FORFILES comparisons; Added
 :::  option for custom file/folder exemptionsfor XCOPY and ROBOCOPY processes
 :::
 :::  (Oct 2017) v7.1 -- Auto-generate config options for multi-destinations
 :::
 :::  (Jan 2018) v7.2 -- Changed the HELP routine to use FINDSTR;
 :::  Fixed a new issue with using FINDSTR /R /C in checking for scheduled jobs;
 :::  Invalid job attempts are now recorded in the .RECORDING.TXT file.
 :::
 :::  (Feb 2018) v8.0 -- The processing of multiple SOURCE folders has been
 :::  made consistent across scripts: The FIRST SOURCE is the one selected.
 :::
 :::  (Apr 2018) v8.1 -- Improved the performance of reading variables from
 :::  the ArchiveInfo.*.TXT INPUT files, using FINDSTR;
 :::  -- The SYNTAX HELP routine has been updated;
 :::  -- Added filtered CMD Title Routine;
 :::  -- Support for NeoLogger has been eliminated from this script;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v8.2 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v8.3 -- Removed AT command support;
 :::
 :::  (Oct 2018) v8.4 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Mar 2019) v8.5 -- Enabled Code Page 1252 Support;
 :::  -- Record additional attributes in the Job History log;
 :::  -- Prevent DEBUG MODE data from being stored in the .RECORDING.TXT file;
 :::
 :::  (Oct 2019) v8.6 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v8.7 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Nov 2019) v8.8 -- Refactored the :GetParams routine using the
 :::  CheckParams.exe utility;
 :::
 :::  (Dec 2019) v9.0 -- Updated :ShowStatus routine to use BrainWave NOW.exe;
 :::  -- Updated all DATEINFO-based routines to use current options and syntax;
 :::  -- Simplified the calculation of TOTAL_COPIED files;
 :::
 :::  (Jan 2020) v9.1 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Added a routine for validating integer parameters;
 :::  -- Refactored the :Prepare4Syslog routine;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::
 :::  (Apr 2020) v9.2 -- Expanded the DEBUG logging to include a STEP parameter;
 :::  -- Replaced FINDSTR with BrainWave ReadConfig.exe for reading config file;
 :::
 :::  (May 2020) v9.3 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::  -- Streamlined Completion Status via NOW.EXE;
 :::  -- Added support for a MINI edition of the ARCHIVE-INFO config file;
 :::
 :::  (Nov 2020) v9.4 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Jan 2022) v9.5 -- Modify the @NAMECHK verification to include \ prefix;
 :::
 :::  (Oct 2023) v9.6 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (Apr 2024) v9.7 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::  (Jul 2024) v9.8 -- Replaced the :RunCMD routine with just a CALL command;
 :::
 :::  (Sep 2024) v9.9 -- Enable updates to local syslogs if requested;
 :::  -- Refactoring of the scheduled jobs verification routine;
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
 rem === Updated On: 30 Nov 2020 / 19 Apr 2018
 rem ==========================================================================
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 26 Sep 2024 / 28 Jul 2024 / 10 May 2024 / 02 May 2024
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v9.9.0.1390 b

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT"
 SET #MSUTILS=CHOICE.EXE FINDSTR.EXE FORFILES.EXE ROBOCOPY.EXE SCHTASKS.EXE TIMEOUT.EXE XCOPY.EXE
 SET #O_UTILS=BLAT.EXE SYSLOGGEN.EXE TAIL.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES& GOTO :ExitBatch)

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @NODELETE=
 SET @MAIL=FALSE
 SET @MAILPORT=25

 rem -- Job Scheduling Variables
 SET @JOBNAME=Archive Backups - %~1
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=23:55:00
 SET @JOBDATE=
 SET @JOBPATH="%~f0" %~1
 SET @JOBVRFY=%~1
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Grab Appropriate Custom Variables from ArchiveInfo.*.TXT
 SET @INFO=INVALID JOB {%~1}
 FOR %%C IN ("%@ARCHIVE-INFO%" "%@ARCH-INFO-MINI%") DO IF EXIST "%%~C" (
	 FOR /F "TOKENS=*" %%R IN ('READCONFIG "%%~C" -F "%~1" 2^>NUL') DO CALL %%R
	 FOR /F "TOKENS=1 DELIMS=;" %%J IN ('READCONFIG "%%~C" -N -S "#RETAINBACKUPS" -P 2^>NUL') DO SET @VALIDJOB-%%~J=%%~J& SET @JOBLIST=TRUE
 )
 FOR %%N IN (JOBNAME INFO) DO CALL :ReplaceParentheses @%%N

 rem -- Main Variables
 SET @RUNMODE=
 SET @COPYSTATUS=
 SET @JOBCOUNT=0
 SET @JOBNUM=0
 SET @TOTAL_FILES=0
 SET @TOTAL_COPIED=0
 SET @TOTAL_PURGED=0
 SET @TOTAL_DELETED=0

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Replication
 SET @LFORMAT=%@LOGPATH%\%~n0-%~1
 SET @NO_COPY=%@LFORMAT%.Exclusion.TXT
 SET @TIMINGS=%@LFORMAT%.RECORDING.TXT
 SET @LOGFILE=%@LFORMAT%.%@FILESTAMP%
 FOR %%L IN (ALERTS SUMMARY TEMPLOG ERRORS) DO SET @%%L=%@LFORMAT%.%%L.%@FILESTAMP%
 SET @LOGLIST="%@LOGFILE%" "%@ERRORS%" "%@ALERTS%"
 SET @CLEANUP="%@TEMPLOG%" "%@ERRORS%" "%@SUMMARY%"

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "D" @THISDAY & IF NOT DEFINED @THISDAY (SET @THISDAY=%@TODAY_EXP%)
 CALL :GetParams "T" @MINROWS & IF DEFINED @OK (
	 SET @MAXROWS=1
	 CALL :GetInteger @MINROWS "%@MINROWS%" 1 1 10
 )
 CALL :GetParams "N" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "S" & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE)
 CALL :GetParams "U" & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @UNSCHED=TRUE)
 CALL :GetParams "R" & IF DEFINED @OK (SET @USE_ROBOCOPY=TRUE)
 CALL :GetParams "X" & IF DEFINED @OK (SET @USE_ROBOCOPY=FALSE)
 CALL :GetParams "M" & IF DEFINED @OK (SET @MAIL=TRUE)
 CALL :GetParams "Q" & IF DEFINED @OK (SET @MAIL=FALSE)
 CALL :GetParams "F" & IF DEFINED @OK (SET @USE_SYSLOGS=TRUE)
 CALL :GetParams "O" & IF DEFINED @OK (SET @USE_SYSLOGS=FALSE)
 CALL :GetParams "Z" & IF DEFINED @OK (SET @TESTMODE=TRUE& SET @NODELETE=-- FILE DELETION DISABLED)
 CALL :GetParams "L" & IF DEFINED @OK (SET @DIAGMODE=TRUE)
 CALL :GetParams "V" & IF DEFINED @OK (SET @SHOWALL=TRUE& GOTO :HelpMessage)
 CALL :GetGoodDates "%@THISDAY%"
 SET @COPYMODE=XCOPY& IF DEFINED @ROBOCOPY IF /I "%@USE_ROBOCOPY%"=="TRUE" SET @COPYMODE=ROBOCOPY
 SET @RERUNCMD=%~f0 %~1 /d:%@THISDAY%

 rem -- Set Variables for Test Configurations
 IF /I "%@DIAGMODE%"=="TRUE" SET @RUNMODE= // VERBOSE
 IF /I "%@TESTMODE%"=="TRUE" (
	 CALL :GetInteger @MINROWS "%@T_MIN_LOG_ROWS%" 003 001 010
	 CALL :GetInteger @MAXROWS "%@T_MAX_LOG_ROWS%" 030 010 049
	 SET @MAILSENDER=LogAdmin-Test%@ORGFQDN%
	 SET @RCPT-TO=%@TEST-RCPTS%
	 SET @ALERT-TO=%@TEST-RCPTS%
	 SET @RUNMODE=!@RUNMODE! // TESTMODE
 )

 rem -- Set Variables for Special Modes
 SET @NOSCHED_MSG=Don't Schedule
 SET @UNSCHED_MSG=Unschedule
 SET @UPDATESCHED_MSG=Update Schedule
 SET @SCHEDULEONLY_MSG=Schedule ONLY
 SET @DIAGMODE_MSG=Diagnostics Logs
 SET @TESTMODE_MSG=Testing Mode
 SET @MAIL_MSG=Send Email
 SET @USE_SYSLOGS_MSG=Forward to Syslog
 SET @MODES=& FOR %%M IN (DIAGMODE TESTMODE MAIL USE_SYSLOGS NOSCHED UNSCHED UPDATESCHED SCHEDULEONLY) DO IF /I "!@%%~M!"=="TRUE" SET @MODES=!@%%~M_MSG! * !@MODES!
 IF "%@MODES%"=="" SET @MODES=NONE *

 rem -- Key Variable Verification
 SET @SOURCEDEST=
 FOR %%V IN ("%@UNSCHED%" "%@SCHEDULEONLY%") DO IF /I "%%~V"=="TRUE" GOTO :ScheduleJobs
 FOR %%C IN ("" %@BASE10%) DO FOR %%X IN ("" %@ALPHA11%) DO IF DEFINED @SOURCE%%~C%%~X (
	 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L SET @SOURCEDEST=PRESENT
 )
 FOR %%V IN (ALL_PARAMS THISDAY COPYMODE SOURCEDEST INFO JOBTIME JOBFREQ ALPHABET ALPHA11 BASE10) DO IF NOT DEFINED @%%~V (
	 ECHO:
	 ECHO *** WARNING: The @%%~V variable is undefined.
	 ECHO:
	 ECHO  Please ensure that all configuration info is provided correctly
	 ECHO  within the file: "%@ARCHIVE-INFO%"
	 ECHO:
	 ECHO  Alternatively, this information can be entered directly into this script,
	 ECHO  although this is not recommended because it undermines portability.
	 ECHO %@DIVIDER*%
	 ECHO:
	 CALL :SaveJobHistory ABORTED - UNDEFINED VARIABLE
	 GOTO :HelpMessage
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Select Valid Source and Destinations from List (plus configs)
 rem === Updated On: 20 Feb 2018 / 20 Oct 2017
 rem ==========================================================================
:SelectValidOptions
 FOR %%C IN ("" %@BASE10%) DO (
	 SET @SOURCE%%~C_SET=
	 FOR %%X IN ("" %@ALPHA11%) DO (
		 IF NOT DEFINED @SOURCE%%~C_SET IF DEFINED @SOURCE%%~C%%~X IF EXIST "!@SOURCE%%~C%%~X!" (
			 SET @SOURCE%%~C_SET=TRUE
			 SET @SOURCE%%~C=!@SOURCE%%~C%%~X!
		 )

		 FOR %%V IN (MSG DEST KEEP_SOURCE KEEP_DEST FILESPEC RECURSION DATEINFO) DO (
			 IF DEFINED @DEST%%~C%%~X IF DEFINED @%%~V%%~C IF NOT DEFINED @%%~V%%~C%%~X SET @%%~V%%~C%%~X=!@%%~V%%~C!
		 )
	 )
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Header and Allow User To Abort Operation
 rem === Updated On: 10 May 2024 / 17 Apr 2017 / 30 Mar 2015
 rem ==========================================================================
:ShowHeader
 TITLE %@JOBNAME% [%@INFO%]
 FOR %%V IN ("%@LOGPATH%") DO IF NOT EXIST "%%~V" MD "%%~V" >NUL

 ECHO === Prepare to Execute the Following Backup Archival Job ===

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER*%
	 ECHO *** %COMPUTERNAME% - [%DATE% at %TIME%] - %@VER%
	 ECHO *** Job Name .......... %@JOBNAME% [%@INFO%]
	 ECHO *** Job Schedule ...... %@JOBFREQ% at %@JOBTIME%  %@JOBDATE%
	 ECHO *** Job User .......... %@JOBUSER%
	 ECHO *** Backup Mode ....... %@COPYMODE%
	 ECHO *** Global Modes ...... %@MODES:~0,-2%
	 IF DEFINED @JOBDELAY ECHO *** Initial Delay ..... %@JOBDELAY% Seconds
	 ECHO %@DIVIDER*%
	 ECHO:
	 FOR %%C IN ("" %@BASE10%) DO IF DEFINED @SOURCE%%~C (
		 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L (
			 CALL :FixDirectoryPath @SOURCE%%~C
			 CALL :FixDirectoryPath @DEST%%~C%%~L
			 CALL :CreateExceptionLists %%~C%%~L
			 CALL :DisplayJobInfo %%~C %%~L
		 )
	 )
	 ECHO Total Jobs = !@JOBCOUNT!
	 ECHO %@DIVIDER-%
	 ECHO:
 ) >"%@SUMMARY%" 2>&1

 TYPE "%@SUMMARY%"
 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 CHOICE /C YNQEX /T 20 /D Y /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :ExitBatch
 )
 COPY "%@SUMMARY%" "%@LOGFILE%" /Y
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 12 Apr 2024 / 22 Jan 2022 / 09 Mar 2019
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
 rem === Optional Waiting Period Before Starting Archival Job
 rem === Updated On: 11 Jan 2015 / 20 Nov 2012
 rem ==========================================================================
:OptionalDelay
 rem -- Optional waiting period before starting archival job
 IF DEFINED @JOBDELAY (
	 CALL :EchoALL *** !DATE! at !TIME! -- Pausing Script for %@JOBDELAY% Seconds ***
	 TIMEOUT %@JOBDELAY% >NUL
	 CALL :EchoALL *** !DATE! at !TIME! -- Resuming Script Operation ***
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1


 rem ==========================================================================
 rem === Enumerate and Execute All Archive Jobs with Retention
 rem === Updated On: 26 Apr 2012 / 12 Mar 2012
 rem ==========================================================================
:ExecuteAllArchives
 FOR %%C IN ("" %@BASE10%) DO IF DEFINED @SOURCE%%~C (
	 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L CALL :ExecuteOneJob %%~C %%~L
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Footer
 rem === Updated On: 30 Nov 2020 / 13 May 2020 / 19 Jan 2015
 rem ==========================================================================
:ShowFooter
 ( rem -- Create Standard and Diagnostic Footer
	 NOW \n\*%~n0 Job Completed - [\v] - %@VER%\n\*\n
	 ECHO To re-run this archive job, type the following at an elevated command prompt on %COMPUTERNAME%:
	 ECHO    %@RERUNCMD%
	 ECHO:
	 IF /I "!@DIAGMODE!"=="TRUE" (
		 ECHO:
		 ECHO %@DIVIDER*%
		 SET
		 ECHO %@DIVIDER*%
		 ECHO:
	 )
	 ECHO %@DIVIDER~%
	 ECHO  Total Files ..........!@TF!
	 ECHO  Total Files Copied ...!@TC!
	 ECHO  Total Files Deleted .....!@TD!
	 ECHO %@DIVIDER~%
	 ECHO:
 ) >"%@TEMPLOG%" 2>&1

 FOR %%O IN (CON "%@SUMMARY%" "%@LOGFILE%") DO TYPE "%@TEMPLOG%" >>%%O 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Log Management/Maintenance (Or Copy Them for Debug Purposes)
 rem === Updated On: 12 Jan 2015
 rem ==========================================================================
:LogMaint
 ECHO PERFORMING FINAL LOG MAINTENANCE...

 IF /I "%DEBUG%"=="COPY" FOR %%L IN (%@LOGLIST% %@CLEANUP%) DO IF EXIST %%L COPY %%L "%TEMP%" /Y

 FOR %%L IN (%@LOGLIST%) DO IF EXIST %%L (
	 SET @THISLOG=%%L
	 COPY %%L !@THISLOG:%@FILESTAMP%=TXT! /Y
	 IF %%L=="%@LOGFILE%" (ECHO: & TYPE %%L & DIR %%L)
 )
 FOR %%L IN (%@CLEANUP%) DO IF EXIST %%L DEL %%L >NUL
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 04 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 ECHO:
 ECHO To See All Jobs, type: %~n0 -v
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Echo Output to Multiple Destinations
 rem === Updated On: 16 Mar 2015 / 19 Jan 2015
 rem ==========================================================================
:EchoAll
 rem %* = Message to Display

 SET @OUT=%*
 SET @OUT=!@OUT: = !
 SET @CHK=%~1
 IF DEFINED @CHK SET @CHK=!@CHK:"=!
 IF /I "%@DIAGMODE%"=="TRUE" SET @OUT=!TIME: =0!: !@OUT!
 IF "%~0"==":EchoALL" (ECHO: >CON & ECHO:)
 IF "!@CHK!"=="" (
	 ECHO: >CON
	 ECHO:
 ) ELSE (
	 ECHO !@OUT! >CON
	 ECHO !@OUT!
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Display a Single Job in the Batch
 rem === Updated On: 28 Jul 2024 / 17 Apr 2017 / 19 Jan 2015
 rem ==========================================================================
:DisplayJobInfo
 rem %1 = Outer Loop Variable
 rem %2 = Inner Loop Variable

 SET /A @JOBCOUNT+=1
 CALL SET @X_SOURCE=%%@SOURCE%~1%%
 FOR %%V IN (MSG DEST KEEP_SOURCE KEEP_DEST FILESPEC RECURSION DATEINFO) DO (
	 SET @VAR=@%%~V%~1%~2
	 CALL SET @X_%%V=%%!@VAR!%%
 )

 SET @X_SOURCE_BASE=%@X_SOURCE%
 SET @X_DEST_BASE=%@X_DEST%
 SET @RECURSE=/S& IF "%@X_RECURSION%"=="" SET @RECURSE=
 CALL :ReplaceParentheses @X_MSG

 rem -- Determine where to Add Dated Folders (Use - suffix to remove dashes from the date)
 FOR %%V IN (BOTH  BOTH+- SOURCE) DO IF /I "%@X_DATEINFO%"=="%%~V" SET @X_SOURCE=%@X_SOURCE_BASE%\%@THISDAY%
 FOR %%V IN (BOTH- BOTH-+ SOURCE-) DO IF /I "%@X_DATEINFO%"=="%%~V" (SET @X_SOURCE=%@X_SOURCE_BASE%\%@THISDAY:-=%& SET @S_DIRSPEC=2???????)
 FOR %%V IN (BOTH  BOTH-+ DESTINATION) DO IF /I "%@X_DATEINFO%"=="%%~V" SET @X_DEST=%@X_DEST_BASE%\%@THISDAY%
 FOR %%V IN (BOTH- BOTH+- DESTINATION-) DO IF /I "%@X_DATEINFO%"=="%%~V" (SET @X_DEST=%@X_DEST_BASE%\%@THISDAY:-=%& SET @D_DIRSPEC=2???????)
 CALL :GetFreeDiskSpace "%@X_SOURCE%" @FREESPACE_S
 CALL :GetFreeDiskSpace "%@X_DEST%"   @FREESPACE_D TRUE

 IF "%~3"=="" ( rem -- Default to Long View
	 ECHO:
	 ECHO JOB INFO ....... %@X_MSG%
	 ECHO  COPY UTILITY .. %@COPYMODE%
	 ECHO  SOURCE ........ %@X_SOURCE% [!@FREESPACE_S!]
	 ECHO  DESTINATION ... %@X_DEST% [!@FREESPACE_D!]
	 ECHO  CRITERIA ...... %@X_FILESPEC%  %@RECURSE%
	 IF DEFINED @EXEMPT-DIRS  ECHO  IGNORE DIRS ... !@EXEMPT-DIRS!
	 IF DEFINED @EXEMPT-FILES ECHO  IGNORE FILES .. !@EXEMPT-FILES!
	 ECHO  BACKUP DATE ... %@THISDAY%& IF NOT "%@X_DATEINFO%"=="" ECHO  SET DATE ON ... %@X_DATEINFO% FOLDER[S]
	 ECHO  KEEP SOURCE ... %@X_KEEP_SOURCE%
	 ECHO  KEEP DEST ..... %@X_KEEP_DEST%
 ) ELSE (
	 ECHO JOB: %@X_MSG%
	 ECHO APP: %@COPYMODE%
	 ECHO   S: %@X_SOURCE% [!@FREESPACE_S!]
	 ECHO   D: %@X_DEST% [!@FREESPACE_D!]
	 ECHO   ?: %@THISDAY%& IF NOT "%@X_DATEINFO%"=="" ECHO  DF: %@X_DATEINFO%
	 IF NOT "!@EXEMPT-DIRS!!@EXEMPT-FILES!"=="" ECHO   -: !@EXEMPT-DIRS! !@EXEMPT-FILES!
	 ECHO  KS: %@X_KEEP_SOURCE%
	 ECHO  KD: %@X_KEEP_DEST%
	 ECHO  **: %@X_FILESPEC%  %@RECURSE%
 )
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Execute a Single Job in the Batch
 rem === Updated On: 28 Jul 2024 / 17 Apr 2017 / 13 Feb 2015
 rem ==========================================================================
:ExecuteOneJob
 rem %1 = Outer Loop Variable
 rem %2 = Inner Loop Variable

 SET /A @JOBNUM+=1
 CALL SET @X_SOURCE=%%@SOURCE%~1%%
 FOR %%V IN (MSG DEST KEEP_SOURCE KEEP_DEST FILESPEC RECURSION DATEINFO) DO (
	 SET @VAR=@%%~V%~1%~2
	 CALL SET @X_%%V=%%!@VAR!%%
 )

 SET @S_DIRSPEC=????-??-???
 SET @D_DIRSPEC=????-??-???
 SET @X_SOURCE_BASE=%@X_SOURCE%
 SET @X_DEST_BASE=%@X_DEST%
 CALL :ReplaceParentheses @X_MSG
 CALL :CreateExceptionLists %~1%~2

 rem -- Determine where to Add Dated Folders (Use - suffix to remove dashes from the date)
 FOR %%V IN (BOTH  BOTH+- SOURCE) DO IF /I "%@X_DATEINFO%"=="%%~V" SET @X_SOURCE=%@X_SOURCE%\%@THISDAY%
 FOR %%V IN (BOTH- BOTH-+ SOURCE-) DO IF /I "%@X_DATEINFO%"=="%%~V" (SET @X_SOURCE=%@X_SOURCE%\%@THISDAY:-=%& SET @S_DIRSPEC=2???????)
 FOR %%V IN (BOTH  BOTH-+ DESTINATION) DO IF /I "%@X_DATEINFO%"=="%%~V" SET @X_DEST=%@X_DEST%\%@THISDAY%
 FOR %%V IN (BOTH- BOTH+- DESTINATION-) DO IF /I "%@X_DATEINFO%"=="%%~V" (SET @X_DEST=%@X_DEST%\%@THISDAY:-=%& SET @D_DIRSPEC=2???????)

 CALL :ResetLogFile "%@SUMMARY%"
 FOR %%V IN (SOURCE DEST) DO (
	 IF /I "%%~V"=="DEST" MD "!@X_%%~V!" >NUL 2>&1

	 IF NOT EXIST "!@X_%%~V!" (
		 SET @NOFOLDER=%%~V FOLDER NOT FOUND
		 SET @COPYSTATUS=!@COPYSTATUS!;FAILURE
		 CALL :EchoALL *** !@NOFOLDER! [!@X_%%~V!] *** >>"%@SUMMARY%" 2>&1
		 CALL :EchoALL %@DIVIDER-% >>"%@SUMMARY%" 2>&1
		 CALL :SendAlert "File Copy Alert -- %COMPUTERNAME% -- ERROR: !@NOFOLDER! [!@X_%%~V!]"
		 CALL :SendLog "%COMPUTERNAME% - %@X_MSG% -- ABORTED"
		 GOTO :EOF
	 )
 )

 rem -- Map Folders for Source and Destination, Using NET USE or SUBST
 CALL :MapDrive @D_DRIVE "%@X_DEST%" "DESTINATION"
 CALL :MapDrive @S_DRIVE "%@X_SOURCE%" "SOURCE"

 rem -- Execute Archive of Backups plus File/Folder Pruning
 IF /I "%@X_DEST_BASE%"=="%@X_DEST%" (
	 CALL :PurgeOldFiles @D_DRIVE %@X_FILESPEC% %@X_KEEP_DEST% "DELETING OLD ARCHIVES from %@D_DRIVE%" %@X_RECURSION%
 ) ELSE (
	 CALL :PurgeOldFolders "%@X_DEST_BASE%" "%@D_DIRSPEC%" %@X_KEEP_DEST% "DELETING OLDEST FOLDERS on %@D_DRIVE%"
 )
 CALL :CopyBackups "%@X_SOURCE%" "%@X_DEST%" %@X_FILESPEC% "ARCHIVING NEW BACKUPS from %@S_DRIVE% to %@D_DRIVE%" %@X_RECURSION%
 IF "%@CANTCOPY%"=="FALSE" (
	 IF /I "%@X_SOURCE_BASE%"=="%@X_SOURCE%" (
		 CALL :PurgeOldFiles @S_DRIVE %@X_FILESPEC% %@X_KEEP_SOURCE% "DELETING OLD ARCHIVES from %@S_DRIVE%" %@X_RECURSION%
	 ) ELSE (
		 CALL :PurgeOldFolders "%@X_SOURCE_BASE%" "%@S_DIRSPEC%" %@X_KEEP_SOURCE% "DELETING OLDEST FOLDERS on %@S_DRIVE%"
	 )
 )

 rem -- Disconnect from Previously Defined NET USE and SUBST Drives
 CALL :UnMapDrive @S_DRIVE "SOURCE"
 CALL :UnMapDrive @D_DRIVE "DESTINATION"

 rem -- Email Job Status Logs
 CALL :SendLog "%COMPUTERNAME% - %@X_MSG%"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Copy Backup Files to Archive
 rem === Updated On: 03 Feb 2020 / 24 Dec 2019
 rem ==========================================================================
:CopyBackups
 rem %1 = Source Folder
 rem %2 = Destination Folder
 rem %3 = Filespec to Copy
 rem %4 = Message to Display
 rem %5 = Enable Recursion with any Non-Blank Value

 SET @ALERTMSG=
 SET @ALERTBODY=
 SET @CANTCOPY=FALSE
 SET @RECURSE=/S& IF "%~5"=="" SET @RECURSE=
 CALL :GetFreeDiskSpace "%~1" @FREESPACE_S
 CALL :GetFreeDiskSpace "%~2" @FREESPACE_D TRUE

 ( rem -- Write to Log
	 CALL :EchoALL -- START: %~4 [%~3] -- via %@COPYMODE% -- !DATE! at !TIME!
	 ECHO:
	 ECHO  Source Folder ........ %~1 [!@FREESPACE_S!]
	 ECHO  Destination Folder ... %~2 [!@FREESPACE_D!]
	 ECHO  Backup Criteria ...... %~3  %@RECURSE%
	 IF DEFINED @EXEMPT-DIRS  ECHO  Ignore Directories ... !@EXEMPT-DIRS!
	 IF DEFINED @EXEMPT-FILES ECHO  Ignore Files ......... !@EXEMPT-FILES!

	 rem -- Determine Number of Valid Files in SOURCE Location
	 CALL :SearchForFiles "%~1" %~3 "%@XCOPYDATE:-=/%" %@RECURSE%
	 SET @FILES-TO-COPY=!@FILECOUNT!
	 SET /A @TOTAL_FILES+=@FILECOUNT

	 IF /I "%@COPYMODE%"=="ROBOCOPY" (
		 %@ROBOCOPY% "%~1" "%~2" %~3 %@THREADS% %@RETRIES% %@RECURSE% /NJH /NDL /NC /NP /XJ /XX /XO /MAXAGE:%@THISDAY:-=% /MINAGE:%@MINAGE% %@SKIP-FILE% %@SKIP-DIR%
	 ) ELSE (
		 XCOPY "%~1\%~3" "%~2" %@RECURSE% /I /C /Y /D:%@XCOPYDATE% /EXCLUDE:%@NO_COPY%
	 )

	 rem -- Determine Number of Valid Files Copied to DESTINATION Location
	 CALL :SearchForFiles "%~2" %~3 "%@XCOPYDATE:-=/%" %@RECURSE%
	 SET @THISCOPY=SUCCESS
	 SET @FILES-COPIED=!@FILECOUNT!
	 SET /A @TOTAL_COPIED+=@FILECOUNT

	 rem -- How to Handle SOME Files Copied Successfully
	 IF !@FILES-COPIED! LSS !@FILES-TO-COPY! (
		 SET @THISCOPY=INCOMPLETE
		 SET @ALERTMSG=SOME FILES FAILED TO COPY
		 SET @ALERTBODY=Only !@FILES-COPIED! of !@FILES-TO-COPY! Files Copied Successfully
	 )

	 rem -- How to Handle when ZERO Files are Copied Successfully
	 IF /I NOT "%@SILENT-ON-ZERO%/!@FILES-TO-COPY!"=="TRUE/0" IF "!@FILES-COPIED!"=="0" (
		 SET @CANTCOPY=TRUE
		 SET @THISCOPY=FAILURE
		 SET @ALERTMSG=ZERO FILES COPIED SUCCESSFULLY
		 SET @ALERTBODY=Could Not Successfully Copy ANY Files
	 )

	 rem -- Generate ERROR Alert If Needed
	 SET @COPYSTATUS=!@COPYSTATUS!;!@THISCOPY!
	 IF DEFINED @ALERTMSG (
		 CALL :EchoALL *** ERROR: !@ALERTBODY! ***
 		 IF NOT "!@FILES-COPIED!"=="0" CALL :CompareDirectories "%~1" "%~2" %~3 "%@XCOPYDATE:-=/%" %@RECURSE%
	 )

	 CALL :GetFreeDiskSpace "%~2"
	 CALL :EchoALL  "%~2" now has !@FREESPACE!
	 CALL :EchoALL -- END: %~4  [%~3] -- !DATE! at !TIME!
	 CALL :EchoALL %@DIVIDER-%
	 ECHO:
 ) >>"%@SUMMARY%" 2>&1

 IF DEFINED @ALERTMSG CALL :SendAlert "File Copy Alert -- %COMPUTERNAME% -- ERROR: !@ALERTMSG!"
 ECHO:
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Purge Old Files from Backup Folder
 rem === Updated On: 31 Oct 2013 / 23 Oct 2013
 rem ==========================================================================
:PurgeOldFiles
 rem %1 = Target Folder
 rem %2 = Filespec to Delete
 rem %3 = Max Age of Files [9999 = exit subroutine]
 rem %4 = Message to Display
 rem %5 = Enable Recursion with any Non-Blank Value

 IF "%~3"=="9999" GOTO :EOF

 CALL :CalculateOldDate %3
 SET @DRV=!%~1!
 SET @DPATH=!%~1-PATH!
 SET @RECURSE=-s& IF "%~5"=="" SET @RECURSE=
 SET @FILECOUNT=0
 SET @TOTALCOUNT=0
 SET @FORFILES=FORFILES -p"%@DRV%" -m%~2 -d-%@DELETE_DATE% %@RECURSE% -c"CMD /C IF @ISDIR==FALSE ECHO @PATH\@FILE"
 IF EXIST "%SystemRoot%\System32\FORFILES.EXE" (
	 SET @FORFILES=%SystemRoot%\System32\FORFILES -p "%@DRV%" -m %~2 -d -%@DELETE_DATE% %@RECURSE% -c "CMD /C IF @ISDIR==FALSE ECHO @PATH"
 )
 SET @ALL-FILES=!@FORFILES:-d-%@DELETE_DATE%=!
 SET @ALL-FILES=!@ALL-FILES:-d -%@DELETE_DATE%=!

 ( rem -- Write to Log
	 CALL :EchoALL -- START: %~4  [over %~3 DAYS] -- !DATE! at !TIME!
	 ECHO:
	 ECHO  Pruning Old Files from "%@DPATH%"

	 FOR /F "TOKENS=*" %%v IN ('%@ALL-FILES% 2^>NUL') DO SET /A @TOTALCOUNT+=1
	 FOR /F "TOKENS=*" %%v IN ('%@FORFILES% 2^>NUL') DO (
		 SET /A @FILECOUNT+=1
		 CALL :EchoAll  - Deleting "%%~v"
		 IF "%@NODELETE%"=="" DEL "%%~v"
	 )

	 SET /A @TOTAL_DELETED+=!@FILECOUNT!
	 CALL :GetFreeDiskSpace "%@DRV%"
	 CALL :EchoALL  !@FILECOUNT! of !@TOTALCOUNT! %@FILESPEC% Files Deleted from %@DPATH% [%@DRV%] -- !@FREESPACE!
	 CALL :EchoALL -- END: %~4  [over %~3 DAYS] -- !DATE! at !TIME!
	 CALL :EchoALL %@DIVIDER-%
	 ECHO:
 ) >>"%@SUMMARY%" 2>&1

 ECHO:
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Purge Old Folders from Backup Location
 rem === Updated On: 03 Feb 2020 / 31 Oct 2013
 rem ==========================================================================
:PurgeOldFolders
 rem %1 = Target Folder
 rem %2 = Directory Spec to Delete
 rem %3 = Max Number of Folders [9999 = exit subroutine]
 rem %4 = Message to Display

 IF "%~3"=="9999" GOTO :EOF

 SET @FOLDERCOUNT=0
 SET @TOTALCOUNT=0

 ( rem -- Write to Log
	 CALL :EchoALL -- START: %~4  [Keep %~3 Copies] -- !DATE! at !TIME!
	 ECHO:
	 ECHO  Pruning Old Folders from "%~1"

	 FOR /F "TOKENS=*" %%v IN ('DIR "%~1\%~2" /AD /O-N /B 2^>NUL') DO SET /A @TOTALCOUNT+=1
	 FOR /F "SKIP=%~3 TOKENS=*" %%v IN ('DIR "%~1\%~2" /AD /O-N /B 2^>NUL') DO (
		 SET /A @FOLDERCOUNT+=1
		 CALL :EchoAll  - Deleting "%~1\%%~v"
		 IF "%@NODELETE%"=="" RD /S /Q "%~1\%%~v"
	 )

	 SET /A @TOTAL_PURGED+=@FOLDERCOUNT
	 CALL :GetFreeDiskSpace "%~1"
	 CALL :EchoALL  !@FOLDERCOUNT! of !@TOTALCOUNT! Folders Deleted from "%~1" -- !@FREESPACE!
	 CALL :EchoALL -- END: %~4  [Keep %~3 Copies] -- !DATE! at !TIME!
	 CALL :EchoALL %@DIVIDER-%
	 ECHO:
 ) >>"%@SUMMARY%" 2>&1

 ECHO:
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Send Email Status
 rem === Updated On: 20 Jan 2015 / 11 Jan 2015
 rem ==========================================================================
:SendLog
 rem %1 = Subject of Email

 TYPE "%@SUMMARY%" >>"%@LOGFILE%"
 IF %@JOBNUM% LSS %@JOBCOUNT% (
	 SET @ATTACHMENTS="%@LOGFILE%"
 ) ELSE (
	 SET @ATTACHMENTS="%@LOGFILE%","%@TIMINGS%"
	 CALL :SaveJobHistory
 )

 rem -- Mail Log File To Appropriate Group
 IF /I "%@MAIL%"=="TRUE" IF DEFINED @RCPT-TO (
	 ( rem -- Write to Log
		 ECHO Sending Logs to: %@RCPT-TO:-to =%
		 ECHO              on: !DATE! at !TIME!
		 ECHO:
		 BLAT -install %@MAILSERVER% %@MAILSENDER% 2 %@MAILPORT%
		 ECHO %@DIVIDER#%
		 ECHO:
		 ECHO:
	 ) >"%@TEMPLOG%" 2>&1
	 FOR %%O IN (CON "%@LOGFILE%") DO TYPE "%@TEMPLOG%" >>%%O 2>&1
	 BLAT "%@SUMMARY%" -f %@MAILSENDER% %@RCPT-TO% -s "%~1" -attach !@ATTACHMENTS!
	 CALL :ForwardToSyslog "6" Mailed %~n0 Job Report for %~1 -- %@INFO% -- "%@LOGFILE%" >NUL
 )
 ECHO:
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Send Job Alert via Email
 rem === Updated On: 20 Jan 2015 / 11 Jan 2015
 rem ==========================================================================
:SendAlert
 rem %1 = Subject of Email

 CALL :ForwardToSyslog "3" %~1

 ( rem -- Write to Log
	 ECHO %@DIVIDER#%
	 ECHO %@ALERTBODY% - [%DATE% at %TIME%] -- %@JOBNAME%
	 ECHO %@DIVIDER#%
	 ECHO:
	 ECHO Please investigate this issue, and re-run the job as necessary...
	 ECHO:
	 ECHO To re-run this archive job, type the following at an elevated command prompt on %COMPUTERNAME%:
	 ECHO    %@RERUNCMD%
	 ECHO:
 ) >"%@ALERTS%"
 TYPE "%@SUMMARY%" >>"%@ALERTS%"

 IF /I "%@MAIL%"=="TRUE" IF DEFINED @ALERT-TO (
	 ( rem -- Write to Log
		 ECHO Sending Alert to: %@ALERT-TO:-to =%
		 ECHO               on: !DATE! at !TIME!
		 ECHO:
		 BLAT -install %@MAILSERVER% %@MAILSENDER% 2 %@MAILPORT%
		 CALL :EchoALL %@DIVIDER#%
		 ECHO:
		 ECHO:
	 ) >>"%@ALERTS%" 2>&1

	 BLAT "%@ALERTS%" -f %@MAILSENDER% %@ALERT-TO% -s "%~1"
 )
 ECHO:
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Search for Files Matching Filespec
 rem === Updated On: 17 Apr 2017 / 13 Sep 2013
 rem ==========================================================================
:SearchForFiles
 rem %1 = Folder to Search for Files
 rem %2 = Filespec to Search
 rem %3 = Search Criteria
 rem %4 = Enable Recursion with any Non-Blank Value

 SET @FILECOUNT=0
 SET @RECURSE=/S& IF "%~4"=="" SET @RECURSE=

 FOR /F "TOKENS=*" %%F IN ('DIR "%~1\%~2" /OGN /A-D %@RECURSE% ^| FIND /I "%~3" ^| FINDSTR /I /V /L "!@SKIPTHESE!"') DO SET /A @FILECOUNT+=1
 CALL :EchoALL  !@FILECOUNT! valid %~2 files dated %@XCOPYDATE:-=/% were found in "%~1"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Create a Mapped or SUBST Drive and Obtain Drive Letter
 rem === Updated On: 17 Apr 2017 / 10 May 2012
 rem ==========================================================================
:MapDrive
 rem %1 = Variable to Assign the Drive Letter to
 rem %2 = UNC Path to Connect
 rem %3 = Description

 SET @DESCRIPTION=[%~3] & IF "%~3"=="" SET @DESCRIPTION=
 SET @DRV=
 SET @DPATH=%~2
 IF "%@DPATH:~0,2%"=="\\" (
	 FOR /F "TOKENS=2" %%D IN ('NET USE * "%~2" /PERSISTENT:NO ^| FIND ":"') DO (
		 SET @DRV=%%~D
		 SET %~1=%%~D
		 SET %~1-PATH=%~2
		 SET %~1-METHOD=NETUSE
	 )
 ) ELSE (
	 FOR %%a IN (%@ALPHABET%) DO IF NOT DEFINED @DRV (
		 SUBST %%a: "%~2" >NUL
		 FOR /F "TOKENS=1,3* DELIMS=\ " %%D IN ('SUBST ^| FIND /I "%~2"') DO (
			 SET @DRV=%%~D
			 SET %~1=%%~D
			 SET %~1-PATH=%~2
			 SET %~1-METHOD=SUBST
		 )
	 )
 )
 ECHO Mapping Drive %@DRV% to %@DESCRIPTION%"%@DPATH%"
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Delete an Existing Mapped or SUBST Drive
 rem === Updated On: 28 Jul 2024 / 10 May 2012 / 06 May 2012
 rem ==========================================================================
:UnMapDrive
 rem %1 = Current Variable
 rem %2 = Description

 SET @DESCRIPTION=[%~2] & IF "%~2"=="" SET @DESCRIPTION=
 CALL SET @DRV=%%%~1%%
 CALL SET @DPATH=%%%~1-PATH%%
 CALL SET @METHOD=%%%~1-METHOD%%
 IF /I "%@METHOD%"=="NETUSE" (
	 NET USE %@DRV% /D /Y >NUL 2>&1
 ) ELSE (
	 SUBST %@DRV% /D
 )
 ECHO Unmapping Drive %@DRV% from %@DESCRIPTION%"%@DPATH%"
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine Free Disk Space
 rem === Updated On: 28 Oct 2013 / 13 Oct 2013
 rem ==========================================================================
:GetFreeDiskSpace
 rem %1 = Disk Path to Evaluate
 rem %2 = Variable to Set with Free Space Info
 rem %3 = If Parameter Exists, Create Desired Folder

 IF /I "%~3"=="TRUE" MD "%~1" >NUL 2>&1
 SET @ACCESSIBLE=& IF NOT EXIST "%~1" SET @ACCESSIBLE=*** Path Not Found ***
 SET @BYTES_FREE=0

 IF NOT DEFINED @ACCESSIBLE (
	 FOR /F "TOKENS=2 DELIMS=)" %%f IN ('DIR /A "%~1" ^| FIND /I "bytes free"') DO SET @BYTES_FREE=%%f
	 CALL :ConvertFreeSpace "!@BYTES_FREE!"
	 IF "%~2"=="" (SET @FREESPACE=!@FREEDISK!) ELSE (SET %~2=!@FREEDISK!)
 ) ELSE (
	 IF "%~2"=="" (SET @FREESPACE=!@ACCESSIBLE!) ELSE (SET %~2=!@ACCESSIBLE!)
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Convert Large Number to KB, MB, GB, TB or PB
 rem === Updated On: 23 Feb 2015 / 22 Apr 2012
 rem ==========================================================================
:ConvertFreeSpace
 rem %1 = Number to convert to KB, MB, GB, TB or PB

 SET @BYTES=%~1
 SET @BYTES=%@BYTES:bytes free=%
 SET @COUNT=0& FOR %%z IN (%@BYTES%) DO (SET /A @COUNT+=1& SET @S!@COUNT!=%%z)

 IF %@COUNT% EQU 1 (SET @UNIT=Bytes& SET @VALUE=%@S1%)

 IF %@COUNT% EQU 2 IF %@S1% GEQ 10 (
	 SET @UNIT=KB& SET @VALUE=%@S1%
 ) ELSE (
	 SET @UNIT=Bytes& SET @VALUE=%@S1%,%@S2%
 )

 IF %@COUNT% EQU 3 IF %@S1% GEQ 10 (
	 SET @UNIT=MB& SET /A @VALUE=%@S1%%@S2% / 1049
 ) ELSE (
	 SET @UNIT=KB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1024
 )

 IF %@COUNT% EQU 4 IF %@S1% GEQ 10 (
	 SET @UNIT=GB& SET /A @VALUE=%@S1%%@S2% / 1074
 ) ELSE (
	 SET @UNIT=MB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1049
 )

 IF %@COUNT% EQU 5 IF %@S1% GEQ 10 (
	 SET @UNIT=TB& SET /A @VALUE=%@S1%%@S2% / 1098
 ) ELSE (
	 SET @UNIT=GB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1074
 )

 IF %@COUNT% EQU 6 IF %@S1% GEQ 10 (
	 SET @UNIT=PB& SET /A @VALUE=%@S1%%@S2% / 1168
 ) ELSE (
	 SET @UNIT=TB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1098
 )

 SET @FREEDISK=%@VALUE% %@UNIT% free
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Copy Backup Files to Archive
 rem === Updated On: 20 Jan 2015 / 14 Nov 2014
 rem ==========================================================================
:ResetLogFile
 rem %1 = Log to Reset

 SET @TESTMSG=& FOR %%Z IN (%@DIAGMODE% %@TESTMODE%) DO IF /I "%%~Z"=="TRUE" SET @TESTMSG=TRUE

 ( rem -- Write to Log
   IF DEFINED @TESTMSG (
		 ECHO %@DIVIDER*%
		 ECHO *** Diagnostics Mode Enabled %@NODELETE% ***
		 ECHO %@DIVIDER*%
		 ECHO:
	 )
	 CALL :EchoALL %@INFO% [JOB #%@JOBNUM% of %@JOBCOUNT%] -- %@X_MSG%
	 CALL :EchoAll %@DIVIDER*%
 ) >"%~1" 2>&1
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Compare Directories and Output Differences
 rem === Updated On: 14 May 2018 / 17 Apr 2017
 rem ==========================================================================
:CompareDirectories
 rem %1 = Source Folder
 rem %2 = Destination Folder
 rem %3 = Filespec to Search
 rem %4 = Date to Search
 rem %5 = Enable Recursion with any Non-Blank Value

 SET @SUBDIRS=/S& IF "%~5"=="" SET @SUBDIRS=
 SET @FNAME=%~1-%~2& CALL :SanitizeName @FNAME

 FOR %%n IN (1 2) DO (
	 SET @COMP%%n=%TEMP%\Compare%%n-!@FNAME!#%@RANDOM%.TXT
	 SET @RESULT%%n=%TEMP%\Result%%n-!@FNAME!#%@RANDOM%.TXT
 )

 rem -- Obtain Directory Listing Based on Relevant Date
 CALL :GetFolderList "%@COMP1%" "%~1" "%~3" "%~4" %@SUBDIRS%
 CALL :GetFolderList "%@COMP2%" "%~2" "%~3" "%~4" %@SUBDIRS%

 rem -- Generate Temp Files for Comparison
 DIFF -i "%@COMP1%" "%@COMP2%" | FIND "<" >"%@RESULT1%" 2>&1
 CALL :CleanOutput "%@RESULT1%" @FAILED-COUNT

 rem -- Display Output for Folder #1
 ECHO:
 ECHO --- The Following !@FAILED-COUNT! Files Could Not Be Copied to the Destination Folder
 ECHO %@DIVIDER-%
 TYPE "%@RESULT1%"
 ECHO %@DIVIDER-%
 ECHO:

 rem -- Delete Temp Files
 FOR %%f IN (COMP RESULT) DO FOR %%n IN (1 2) DO IF EXIST "!@%%f%%n!" DEL "!@%%f%%n!" >NUL
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Get Folder Listing
 rem === Updated On: 17 Apr 2017 / 23 Oct 2013
 rem ==========================================================================
:GetFolderList
 rem %1 = Output File
 rem %2 = Source Folder
 rem %3 = Filespec to Search
 rem %4 = Date to Search
 rem %5 = Enable Recursion with any Non-Blank Value

 rem -- Map Drive to Eliminate UNC Path
 CALL :MapDrive @COMPDRIVE "%~2"

 SET @SUBDIRS=-s& IF "%~5"=="" SET @SUBDIRS=
 SET @FF-DATE=%~4& FOR /L %%d IN (0,1,9) DO (SET @FF-DATE=!@FF-DATE:0%%d/=%%d/!& SET @FF-DATE=!@FF-DATE:/0%%d=/%%d!)
 SET @FORFILES=FORFILES -p"!@COMPDRIVE!" -m%~3 -d+%~4 %@SUBDIRS% -c"CMD /C IF @ISDIR==FALSE ECHO @FDATE	@FTIME	@RELPATH\@FILE"
 IF EXIST "%SystemRoot%\System32\FORFILES.EXE" (
	 SET @FORFILES=%SystemRoot%\System32\FORFILES -p "!@COMPDRIVE!" -m %~3 -d +%~4 %@SUBDIRS% -c "CMD /C IF @ISDIR==FALSE ECHO @FDATE	@FTIME	@RELPATH"
 )

 ECHO: >"%~1"
 FOR /F "TOKENS=*" %%a IN ('%@FORFILES% ^| FIND "!@FF-DATE!" ^| FINDSTR /I /V /L "!@SKIPTHESE!" 2^>NUL') DO ECHO %%~a >>"%~1" 2>&1

 rem -- UnMap Comparison Drive
 CALL :UnMapDrive @COMPDRIVE
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Cleanup DIFF Output for Display
 rem === Updated On: 23 Oct 2013 / 16 Oct 2013
 rem ==========================================================================
:CleanOutput
 rem %1 = Name of File
 rem %2 = New Variable for Count

 SET @NEWCOUNT=0

 IF EXIST "%@RESULT2%" DEL "%@RESULT2%" >NUL
 FOR /F "USEBACKQ TOKENS=1* DELIMS=<>" %%Z IN ("%~1") DO (
	 SET /A @NEWCOUNT+=1
	 SET @THISLINE=%%Z
	 ECHO !@THISLINE:.\=\!
 ) >> "%@RESULT2%" 2>&1

 SET %~2=!@NEWCOUNT!
 COPY "%@RESULT2%" "%~1" /V >NUL
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 16 Oct 2023 / 23 Mar 2015
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Calculate Interval Between Today and Another Date
 rem === Updated On: 24 Dec 2019 / 16 Nov 2012
 rem ==========================================================================
:GetDateOffset
 rem %1 = Date to Compare (in MM/DD/YYYY format)

 FOR /F %%c IN ('DATEINFO -b %~1 -q 2^>NUL') DO SET @INTERVAL=%%c
 FOR /F %%e IN ('DATEINFO -s %~1 -a 1 -f "yyyymmdd" -q 2^>NUL') DO SET @MINAGE=%%e
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine New Date From Old Date + Interval [via DATEINFO]
 rem === Updated On: 24 Dec 2019 / 16 Nov 2012
 rem ==========================================================================
:CalculateOldDate
 rem %1 = Date Offset

 FOR /F %%d IN ('DATEINFO -s %@XCOPYDATE:-=/% -p %~1 -q 2^>NUL') DO SET @DELETE_DATE=%%d
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Ensure that User-Supplied Dates Have Correct Format
 rem === Updated On: 24 Dec 2019 / 23 Oct 2013
 rem ==========================================================================
:GetGoodDates
 rem %1 = Date to Validate

 SET @THISDAY=
 FOR /F "TOKENS=1-3 DELIMS=-/" %%v IN ('ECHO %~1') DO SET @TDATE=%%w/%%x/%%v
 FOR /F %%d IN ('DATEINFO -s "%@TDATE%" -f "yyyy-mm-dd" -q 2^>NUL') DO SET @THISDAY=%%~d

 IF "!@THISDAY!"=="" (
	 ECHO The Provided Date [%~1] is NOT in the Proper yyyy-mm-dd Format...
	 TIMEOUT 30
	 ECHO:
 ) ELSE (
	 FOR /F "TOKENS=1-3 DELIMS=-" %%V IN ('ECHO !@THISDAY!') DO SET @XCOPYDATE=%%W-%%X-%%V
	 CALL :GetDateOffset "!@XCOPYDATE:-=/!"
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Create Exception List for ROBOCOPY and XCOPY commands
 rem === Updated On: 17 Apr 2017
 rem ==========================================================================
:CreateExceptionLists
 rem %1 = Current Configuration Suffix to Evaluate

 SET @EXEMPT-DIRS=
 SET @EXEMPT-FILES=
 SET @CURRENT_SD=%@SKIPDIR%&   IF DEFINED @SKIPDIR%~1    SET @CURRENT_SD=!@SKIPDIR%~1!
 SET @CURRENT_SF=%@SKIPFILE%&  IF DEFINED @SKIPFILE%~1   SET @CURRENT_SF=!@SKIPFILE%~1!
 SET @CURRENT_EX=%@EXEMPTION%& IF DEFINED @EXEMPTION%~1  SET @CURRENT_EX=!@EXEMPTION%~1!
 SET @SKIP-DIR=&  IF NOT "%@CURRENT_SD%"=="" SET @SKIP-DIR=/XD %@CURRENT_SD%
 SET @SKIP-FILE=& IF NOT "%@CURRENT_SF%"=="" SET @SKIP-FILE=/XF %@CURRENT_SF%

 ( FOR %%e IN (%@CURRENT_EX%) DO (
	 SET @THISONE=%%~e
	 SET @THISONE=!@THISONE:+=!
	 FOR /F %%f IN ('ECHO %%~e ^| FIND "\"') DO SET @EXEMPT-DIRS=%%~f !@EXEMPT-DIRS!
	 FOR /F %%f IN ('ECHO %%~e ^| FIND /V "\"') DO SET @EXEMPT-FILES=%%~f !@EXEMPT-FILES!
	 ECHO !@THISONE!
 ) ) >"%@NO_COPY%"

 IF DEFINED @EXEMPT-FILES SET @EXEMPT-FILES=!@EXEMPT-FILES:+=!
 IF DEFINED @EXEMPT-DIRS (
	 SET @EXEMPT-DIRS=!@EXEMPT-DIRS:+\+=!
	 SET @EXEMPT-DIRS=!@EXEMPT-DIRS:\+=\!
	 SET @EXEMPT-DIRS=!@EXEMPT-DIRS:+\=\!
	 SET @EXEMPT-DIRS=!@EXEMPT-DIRS:+=!
 )
 IF "%@EXEMPT-FILES%%@EXEMPT-DIRS%"=="" ( SET @SKIPTHESE=~{%@RANDOM%.%@ALPHABET%}~ ) ELSE ( SET @SKIPTHESE=%@EXEMPT-DIRS% %@EXEMPT-FILES% )
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Replace Parentheses with Brackets in Variables
 rem === Updated On: 19 Jan 2015
 rem ==========================================================================
:ReplaceParentheses
 rem %1 = Variable Name

 IF NOT DEFINED %1 GOTO :EOF
 SET %~1=!%~1:(=[!
 SET %~1=!%~1:)=]!
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Remove Trailing \ From Supplied Folder Path
 rem === Updated On: 25 Feb 2019 / 19 Jan 2015
 rem ==========================================================================
:FixDirectoryPath
 rem %1 = Folder Variable

 IF NOT DEFINED %1 GOTO :EOF
 IF "!%~1:~-1!"=="\" (
	 SET %~1=!%~1:~0,-1!
	 GOTO :FixDirectoryPath
 )
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Generate Safe Job Schedule Name
 rem === Updated On: 17 Apr 2017
 rem ==========================================================================
:SanitizeName
 rem %1 = Name of Variable to CleanUp

 IF NOT DEFINED %1 GOTO :EOF
 SET %~1=!%~1:(=[!
 SET %~1=!%~1:)=]!
 SET %~1=!%~1::\=_!
 SET %~1=!%~1:\=_!
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
 rem === Updated On: 21 Jan 2020 / 26 Nov 2019
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
 rem === Updated On: 12 Apr 2024 / 07 Apr 2024 / 27 Apr 2020 / 24 Dec 2019
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 rem -- Determine Overall Job Status Count
 FOR %%A IN (SUCCESS FAILURE INCOMPLETE) DO (
	 SET @COUNT_%%A=0
	 FOR %%B IN (%@COPYSTATUS%) DO IF /I "%%~B"=="%%~A" SET /A @COUNT_%%A+=1
 )

 rem -- Update Job Execution Logfile
 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @JC "!@JOBCOUNT!" " " 2
 CALL :PadLeft @CS "!@COUNT_SUCCESS!" "." 2
 CALL :PadLeft @CF "!@COUNT_FAILURE!" "." 2
 CALL :PadLeft @CI "!@COUNT_INCOMPLETE!" "." 2
 CALL :PadLeft @TF "!@TOTAL_FILES!" "." 6
 CALL :PadLeft @TC "!@TOTAL_COPIED!" "." 6
 CALL :PadLeft @TP "!@TOTAL_PURGED!" "." 3
 CALL :PadLeft @TD "!@TOTAL_DELETED!" "." 3
 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 IF "%~1"=="" IF "!@JOBCOUNT!"=="0" SET @SPECIAL=!@SPECIAL! // ABORTED - SOURCE FOLDERS NOT FOUND
 SET @JOBHISTORY=%@INFO% // %COMPUTERNAME% // JOBS:%@JC% [S.%@CS% I.%@CI% F.%@CF%] // FILES COPIED.%@TC% of %@TF% // DELETED [FOLDERS.%@TP% FILES.%@TD%] // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %@COPYMODE% // %~n0 %@VERSION%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('TYPE "%@TIMINGS%" ^| FIND /C "/"') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY "%@TIMINGS%" "!@OLDTIME!" /V /Y >CON
	 TAIL -%@MINROWS% "!@OLDTIME!" >"%@TIMINGS%"
	 ECHO:
	 CALL :ForwardToSyslog "5" %@INFO%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>"%@LOGFILE%" 2>>"%@ERRORS%"

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@RUNMODE!!@TRUNCATED! >>"%@TIMINGS%" 2>>"%@ERRORS%"
 %@VERBOSE_ON%
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 25 Sep 2024 / 26 Nov 2019 / 07 Mar 2019
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
 rem === Updated On: 23 Jun 2024 / 19 Apr 2018 / 16 Dec 2014
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
 rem === Updated On: 03 Sep 2024 / 15 May 2018 / 15 Oct 2014
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
 rem === Updated On: 30 Nov 2020 / 29 Apr 2018
 rem ==========================================================================
:HelpMessage
 FOR %%V IN (YESTERDAY LASTWEEK) DO IF NOT DEFINED @%%V_EXP SET @%%V_EXP=2010-10-10

 ECHO Manage Retention of Archived SQL and Other Database Backups
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<name_of_archive_job^>  [-d:^<yyyy-mm-dd to backup^>]  [OPTIONS]
 ECHO  %~n0  ^<name_of_archive_job^>  [-t^|-t:#]
 ECHO  %~n0  [-h^|-?^|-h2^|-??^|-v]
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO       /D  .... Execute Archive Job for Files Created on This Date
 ECHO       /S  .... Schedule the Job Only, Without Executing It First
 ECHO       /U  .... Unschedule the Job Only, Without Executing It First
 ECHO       /N  .... Execute the Job, But Do Not Schedule It
 ECHO       /R  .... Use ROBOCOPY instead of XCOPY  ***DEFAULT***
 ECHO       /X  .... Use XCOPY instead of ROBOCOPY
 ECHO       /M  .... Send an Email on Job Completion, If Possible  ***DEFAULT***
 ECHO       /Q  .... Do NOT Send and Email on Job Completion
 ECHO       /F  .... Forward to Syslog Servers, If Available  ***DEFAULT***
 ECHO       /O  .... Do NOT Forward to Syslog Servers
 ECHO       /T  .... Truncate Job History Logfile {or /T:# where # is from 1-10}
 ECHO       /V  .... Display All Possible Backup Jobs Which are Valid for This Computer
 ECHO       /Z  .... Test/Diagnostics Mode {execute test configuration}
 ECHO       /L  .... Enable Verbose Logging for Diagnostics
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 SQL-Daily
	 ECHO  %~n0 SQL_Weekly /N
	 ECHO  %~n0 SomeStuff /T
	 ECHO  %~n0 OtherStuff /T:3
	 ECHO  %~n0 AllDataBases -d:%@YESTERDAY_EXP%
	 ECHO  %~n0 "ZipCodes" /d:%@LASTWEEK_EXP% -X
	 ECHO  %~n0 CriticalArchive -R
	 ECHO  %~n0 AllZipFiles /z
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
	 ECHO  * The name of the archive job cannot contain ANY spaces. Spaces are
	 ECHO    permissable in the job description, however. Shortnames *can* be
	 ECHO    surrounded by quotes if you choose, but it is not mandatory.
	 ECHO:
	 ECHO  * An elevated CMD promt is required in Windows 2008+ in order to display
	 ECHO    the list of scheduled archive tasks.
	 ECHO:
	 ECHO  * Do not use ^(^) in the values of @INFO, @JOBNAME or MSGx variables, as
	 ECHO    these characters will likely prevent the successful completion of this
	 ECHO    script. Please use {} or [] characters instead.
 )

 IF DEFINED @SHOWALL IF DEFINED @JOBLIST (
	 ECHO:
	 ECHO:
	 ECHO The following are valid potential jobs for this system [%COMPUTERNAME%]:
	 ECHO %@DIVIDER%
	 FOR /F "TOKENS=1* DELIMS==" %%B IN ('SET @VALIDJOB-') DO ECHO  %~n0  %%~C -n
	 ECHO:
	 ECHO:
	 ECHO The following archive jobs are scheduled on this system [%COMPUTERNAME%]:
	 ECHO %@DIVIDER%
	 FOR /F "TOKENS=3*" %%B IN ('SCHTASKS ^| FIND /I "Archive Backups -"') DO ECHO   %%C
 )
 CALL :ShowStatus "FINISHED"
                                                                                     