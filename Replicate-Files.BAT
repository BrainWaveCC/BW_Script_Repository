@ECHO OFF
 rem ==========================================================================
 rem === Replicate Files Between Local or Remote Servers
 rem ==========================================================================
 rem
 rem Created On: 16 Mar 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 30 Sep 2025 / 14 Aug 2025 / 27 Jun 2025 / 26 Sep 2024 / 03 Sep 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    Blat ................... http://www.blat.net/
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

 :::  This script copies files and folders between servers, using ROBOCOPY,
 :::  which is native to Windows 2003 and later, but can be found in the NT4
 :::  and Windows 2000 Resource Kits.  It is automatically scheduled using
 :::  the SYSTEM account (which is fine if the job is local to that server).
 :::
 :::  Source/Destination variables for this script are managed via the
 :::  ReplicationInfo.TXT input file.  You can choose up to 9 source and
 :::  destination paths per copy job.
 :::
 :::  As of May 2009, the script will not mirror the folders automatically
 :::  unless one of the values of the @OPTIONS variable is /MIR. Alternately,
 :::  it can be added as a command-line parameter.
 :::
 :::  It is now possible to copy from a single source to multiple destinations.
 :::  Source variables are named @SOURCE1 through @SOURCE9, with normally
 :::  corresponding variables of @DEST1 through @DEST9.  To copy a single
 :::  source to multiple destinations, use the @DEST#A to @DEST#H variables,
 :::  where # is a number from 1 through 9.  For example, if @DEST1A, @DEST1B
 :::  and @DEST1C are defined, they will all be the recipients of the data
 :::  found at @SOURCE1.  This means that you can have up to any combination
 :::  of 9 source/single-destination pairs and source/multi-destination pairs.
 :::
 :::  (Nov 2010) Changed the default log extension of the reports from .LOG to
 :::  .TXT so that the reports that are mailed to mobile devices can be read
 :::  automatically. (Not too many devices can natively handle .LOG files)
 :::
 :::  (Mar 2011) The DblCheck routine has been updated to use the CHOICE.EXE
 :::  command rather than the TIMEOUT command.  This allows more flexibility
 :::  to abort or continue with the script.
 :::
 :::  (Nov 2012) To compensate for a parsing bug in the task scheduler of
 :::  certain versions of Windows (including Windows 8), the script was
 :::  changed to eliminate the use of quotation marks in the job parameters.
 :::  For more details, see: http://support.microsoft.com/kb/951246
 :::
 :::  (Dec 2012) Made it possible for the scheduled tasks to be stored in their
 :::  own folder, rather than the default root folder of the Task Scheduler.
 :::
 :::  (Sep 2013) v5.0 -- The TIMINGS Logfile will be reduced to the minimum
 :::  row size whenever it exceeds the maximum log row size, as defined by the
 :::  following variables:  %@MAX_LOG_ROWS% and %@MIN_LOG_ROWS%
 :::
 :::  (Oct 2013) v5.3 -- The delimiter for all parameters can be either the
 :::  "-" or the "/" character.  This includes the help parameters.
 :::
 :::  (Nov 2013) v5.6 -- The parameters for truncating the logs have
 :::  been changed to synchronize them with MoveArchives.BAT.  At a later point,
 :::  these parameters will be synchronized with other major archive scripts such
 :::  as CreateArchives.BAT and RetainBackups.BAT.
 :::
 :::  (Nov 2013) v5.6 -- The script will now display any currently scheduled
 :::  Replicate-Files.BAT jobs on the current system, when the list of valid
 :::  jobs is displayed.  This requires an elevated prompt in 2008 and later
 :::  editions of Windows.
 :::
 :::  (Feb 2014) v5.8 -- Added the capability to send log data to one or more
 :::  Syslog servers using the SyslogGen or NeoLog utilities in conjunction
 :::  with the @SYSLOGx environment variables.
 :::
 :::  (Mar 2014) v5.9 -- Upgraded the DebugMode options to add another
 :::  variable (@PRINT_IF_DEBUG). Also revamped the routines for logging to
 :::  Syslog servers.
 :::
 :::  (Apr 2014) v5.10 -- Documented two parameters which have been available
 :::  for some time. One is for scheduling a copy job without running it, and
 :::  the other is for running a copy job without scheduling it.
 :::
 :::  (Dec 2014) v5.13 -- Added the ability to select from a list of possible
 :::  source folders for a single job.  The last valid folder in the list is
 :::  selected for the job.  The letters A through K are valid variables for
 :::  the list elements. (e.g. @SOURCE1A to @SOURCE1K)
 :::
 :::  (Jan 2015) v6.0 -- Updated to use timestamped logfiles, managed with the
 :::  new logfile maintenance routine.
 :::
 :::  (Mar 2015) v6.1 -- Migrated more variables to SetDrive.BAT
 :::
 :::  (Mar 2015) v6.2 -- Track total elapsed time of file copy job using a new
 :::  version of DATEINFO
 :::
 :::  (Nov 2015) v6.4 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Jan 2018) v6.6 -- Changed the HELP routine to use FINDSTR;
 :::  -- Fixed a new issue with using FINDSTR /R /C in checking for scheduled jobs;
 :::  -- Migrated :SaveJobHistory to a subroutine, for additional flexibility;
 :::  -- Invalid job attempts are now recorded in the .RECORDING.TXT file.
 :::
 :::  (Feb 2018) v6.7 -- Added @ATTEMPTS counter to the .RECORDING.TXT status file
 :::
 :::  (Feb 2018) v7.0 -- The processing of multiple SOURCE folders has been made
 :::  consistent across scripts: The FIRST valid SOURCE is the one selected;
 :::  -- A validation bug with the job parameters has been corrected.
 :::
 :::  (Apr 2018) v7.1 -- Improved the performance of reading variables from
 :::  the ReplicationInfo.*.TXT INPUT files, using FINDSTR;
 :::  -- The SYNTAX HELP routine has been updated;
 :::  -- Added filtered CMD Title Routine;
 :::  -- Support for NeoLogger has been eliminated from this script;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v7.2 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::  -- Support for NeoLogger has been eliminated from this script.
 :::
 :::  (Aug 2018) v7.3 -- Removed AT command support;
 :::
 :::  (Oct 2018) v7.4 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Mar 2019) v7.5 -- Enabled Code Page 1252 Support;
 :::  -- Record additional attributes in the Job History log;
 :::  -- Prevent DEBUG MODE data from being stored in the .RECORDING.TXT file
 :::
 :::  (Jul 2019) v8.0 -- Support specific file masks insteed of default *.*;
 :::  -- Allow file recursion to be overridden (instead of default /S /E);
 :::
 :::  (Oct 2019) v8.1 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v8.2 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Dec 2019) v8.3 -- Updated :ShowStatus routine to use BrainWave NOW.exe;
 :::
 :::  (Jan 2020) v8.4 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Added a routine for validating integer parameters;
 :::  -- Refactored the :Prepare4Syslog routine;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::
 :::  (Apr 2020) v8.5 -- Expanded the DEBUG logging to include a STEP parameter;
 :::  -- Replaced FINDSTR with BrainWave ReadConfig.exe for reading config file;
 :::
 :::  (May 2020) v8.6 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::  -- Streamlined Completion Status via NOW.EXE;
 :::  -- Added support for a MINI edition of the REPL-INFO config file;
 :::
 :::  (Nov 2020) v9.0 -- Added support for the @MULTIDEST variable to select
 :::  between the following backup behaviors:
 :::   ** Backup to ALL Valid Destinations (TRUE) -- Default Script Settings
 :::   ** Back Up to 1st Valid Destination (FALSE);
 :::
 :::  (Nov 2020) v9.1 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Jan 2022) v9.2 -- Modify the @NAMECHK verification to include \ prefix;
 :::  -- Correct Report of Copied Files;
 :::
 :::  (Oct 2023) v9.3 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (Apr 2024) v9.4 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::  (Jul 2024) v9.5 -- Replaced the :RunCMD routine with just a CALL command;
 :::
 :::  (Sep 2024) v9.6 -- Enable updates to local syslogs if requested;
 :::  -- Refactoring of the scheduled jobs verification routine;
 :::  -- Created :LogCriticalFailure routine for early job failures;
 :::
 :::  (Jun 2025) v10.0 -- Extend the number of supported jobs to almost 30, by
 :::  adding 00 to 09 and 10 to 19 to the existing single digit counters;
 :::
 :::  (Sep 2025) v10.1 -- Replaced instances of HEAD/TAIL/TYPE with READABLE;
 :::
 :::
 :::  SCRIPTING SYNTAX RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  https://ss64.com/ .......... CMD and Powershell syntax
 :::  https://www.dostips.com/ ... Windows Shell Scripting Tips
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 01 Nov 2020 / 25 Feb 2018
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 30 Sep 2025 / 27 Jun 2025 / 26 Sep 2024 / 28 Jul 2024
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v10.1.0.1010

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT" READABLE.EXE
 SET #MSUTILS=CHOICE.EXE FINDSTR.EXE ROBOCOPY.EXE SCHTASKS.EXE
 SET #O_UTILS=BLAT.EXE SYSLOGGEN.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES & GOTO :ExitBatch)

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @MAIL=FALSE
 SET @MAILPORT=25
 SET @MULTIDEST=TRUE

 rem -- Job Scheduling Variables
 SET @JOBNAME=Replicate Files - %~1
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=05:30:00
 SET @JOBDATE=
 SET @JOBPATH="%~f0" %~1 %2 %3 %4 %5 %6 %7 %8 %9
 SET @JOBVRFY=%~1
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Grab Appropriate Custom Variables from ReplicationInfo.*.TXT
 SET @INFO=INVALID JOB {%~1}
 FOR %%C IN ("%@REPL-INFO%" "%@REPL-INFO-MINI%") DO IF EXIST "%%~C" (
	 FOR /F "TOKENS=*" %%R IN ('READCONFIG "%%~C" -F "%~1" 2^>NUL') DO CALL %%R
	 FOR /F "TOKENS=1 DELIMS=;" %%J IN ('READCONFIG "%%~C" -N -S "@SKIPFILE" -P 2^>NUL') DO SET @VALIDJOB-REPL-%%~J=%%~J& SET @JOBLIST=TRUE
 )
 FOR %%N IN (JOBNAME INFO) DO CALL :ReplaceParentheses @%%N

 rem -- Main Variables
 SET @DELAY=20
 SET @MASK=*.*
 SET @RECURSION=/S /E
 SET @RUNMODE=
 SET @JOBCOUNT=0
 SET @ATTEMPTS=0
 SET @FILES-COPIED=0
 SET @PARAMS=%@OPTIONS% %2 %3 %4 %5 %6 %7 %8 %9
 SET @TREECMD=TREE /A& IF /I "%@SHOWTREE%"=="FULL" (SET @SHOWTREE=TRUE& SET @TREECMD=TREE /A /F)
 IF NOT "%@SKIPDIR%"=="" SET @SKIPDIR=/XD %@SKIPDIR%
 IF NOT "%@SKIPFILE%"=="" SET @SKIPFILE=/XF %@SKIPFILE%

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Replication
 SET @LFORMAT=%@LOGPATH%\%~n0-%~1
 SET @TIMINGS=%@LFORMAT%.RECORDING.TXT
 SET @LOGFILE=%@LFORMAT%.%@FILESTAMP%
 FOR %%L IN (SUMMARY TEMPLOG ERRORS) DO SET @%%L=%@LFORMAT%.%%L.%@FILESTAMP%
 SET @LOGLIST="%@LOGFILE%" "%@ERRORS%"
 SET @CLEANUP="%@TEMPLOG%" "%@ERRORS%" "%@SUMMARY%"

 rem -- Extend Max Job Counter to 20+
 SET @MORE_JOBS=00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19
 SET @ALL_JOB_NUMS=%@BASE10% %@MORE_JOBS%

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "@" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "-" & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @UNSCHED=TRUE& SET @DELAY=5)
 CALL :GetParams "." & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @SCHEDULEONLY=TRUE& SET @UPDATESCHED=TRUE)
 CALL :GetParams "*" & IF DEFINED @OK (SET @MINROWS=1& SET @MAXROWS=1)
 CALL :GetParams "~" & IF DEFINED @OK (SET @TESTMODE=TRUE& SET @DIAGMODE=TRUE)
 CALL :GetParams "#" & IF DEFINED @OK (SET @SHOWALL=TRUE& GOTO :HelpMessage)
 IF DEFINED @PARAMS SET @PARAMS=!@PARAMS:  = !

 rem -- Set Variables for Test Configurations
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
 SET @MULTIDEST_MSG=Copy to ALL Destinations& IF /I "%@MULTIDEST%"=="FALSE" SET @MULTIDEST_MSG=Copy to FIRST Valid Destination
 SET @USE_SYSLOGS_MSG=Forward to Syslog
 SET @MODES=& FOR %%M IN (DIAGMODE TESTMODE USE_SYSLOGS NOSCHED UNSCHED UPDATESCHED SCHEDULEONLY MULTIDEST) DO IF /I "!@%%~M!"=="TRUE" SET @MODES=!@%%~M_MSG! * !@MODES!
 IF "%@MODES%"=="" SET @MODES=NONE *

 rem -- Key Variable Verification
 SET @SOURCEDEST=%@UNSCHED%
 FOR %%C IN ("" %@ALL_JOB_NUMS%) DO FOR %%X IN ("" %@ALPHA11%) DO IF DEFINED @SOURCE%%~C%%~X (
	 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L SET @SOURCEDEST=PRESENT
 )
 FOR %%V IN (ALL_PARAMS SOURCEDEST TREECMD JOBTIME JOBFREQ ALPHA11 BASE10 ALL_JOB_NUMS MASK) DO IF NOT DEFINED @%%~V (
	 ECHO:
	 ECHO *** WARNING: The @%%~V variable is undefined.
	 ECHO:
	 ECHO  Please ensure that all configuration info is provided correctly
	 ECHO  within the file: "%@REPL-INFO%"
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
 rem === Select Valid Source from List
 rem === Updated On: 27 Jun 2025 / 20 Feb 2018 / 26 Jun 2017
 rem ==========================================================================
:SelectSourceFromList
 FOR %%C IN ("" %@ALL_JOB_NUMS%) DO (
	 SET @SOURCE%%~C_SET=
	 FOR %%X IN ("" %@ALPHA11%) DO IF NOT DEFINED @SOURCE%%~C_SET (
		 IF DEFINED @SOURCE%%~C%%~X IF EXIST "!@SOURCE%%~C%%~X!" (
			 SET @SOURCE%%~C_SET=TRUE
			 SET @SOURCE%%~C=!@SOURCE%%~C%%~X!
		 )
	 )
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Header and Allow User To Abort Operation
 rem === Updated On: 27 Jun 2025 / 10 May 2024 / 01 Nov 2020 / 21 Jul 2019
 rem ==========================================================================
:ShowHeader
 TITLE %@JOBNAME% [%@INFO%]
 FOR %%V IN ("%@LOGPATH%") DO IF NOT EXIST "%%~V" MD "%%~V" >NUL

 ECHO === Prepare to Execute the Following Replication Job ===

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER*%
	 ECHO *** %COMPUTERNAME% - [%DATE% at %TIME%] - %@VER%
	 ECHO *** Job Name .......... %@JOBNAME% [%@INFO%]
	 ECHO *** Job Schedule ...... %@JOBFREQ% at %@JOBTIME%  %@JOBDATE%
	 ECHO *** Job User .......... %@JOBUSER%
	 ECHO *** Global Modes ...... %@MODES:~0,-2%
	 ECHO %@DIVIDER*%
	 ECHO:
	 FOR %%C IN ("" %@ALL_JOB_NUMS%) DO IF DEFINED @SOURCE%%~C (
		 IF NOT DEFINED @MASK%%~C SET @MASK%%~C=%@MASK%
		 IF NOT DEFINED @RECURSION%%~C SET @RECURSION%%~C=%@RECURSION%

		 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L (
			 IF NOT DEFINED @MASK%%~C%%~L SET @MASK%%~C%%~L=!@MASK%%~C!
			 IF NOT DEFINED @RECURSION%%~C%%~L SET @RECURSION%%~C%%~L=!@RECURSION%%~C!
			 SET /A @JOBCOUNT+=1
			 CALL :FixDirectoryPath @SOURCE%%~C
			 CALL :FixDirectoryPath @DEST%%~C%%~L
			 CALL :DisplayCopy @SOURCE%%~C @DEST%%~C%%~L @MASK%%~C%%~L @RECURSION%%~C%%~L
		 )
	 )
	 ECHO:
 ) >"%@SUMMARY%" 2>&1

 TYPE "%@SUMMARY%"
 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 CHOICE /C YNQEX /T %@DELAY% /D Y /N /M "Continue running this script? (Y/N/Q) "
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
 rem === Replicate Data From Source(s) to Destination(s) (ROBOCOPY XP010 or later)
 rem === Updated On: 27 Jun 2025 / 25 Jan 2022 / 21 Jul 2019
 rem ==========================================================================
:Replicate
 FOR %%C IN ("" %@ALL_JOB_NUMS%) DO IF DEFINED @SOURCE%%~C (
	 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L IF EXIST "!@SOURCE%%~C!" (
		 CALL :ExecuteCopy @SOURCE%%~C @DEST%%~C%%~L @MASK%%~C%%~L @RECURSION%%~C%%~L
	 ) ELSE (
		 ECHO:
		 ECHO *** ERROR: Could Not Find Folder "!@SOURCE%%~C!"
		 ECHO:
	 )
 )

 FOR /F "TOKENS=4" %%C IN ('FIND " Files :  " "%@LOGFILE%"') DO SET @FILES-COPIED=%%C
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Footer
 rem === Updated On: 25 Jan 2022 / 01 Nov 2020
 rem ==========================================================================
:ShowFooter
 CALL :SaveJobHistory
 CALL :PadLeft @JC "!@JOBCOUNT!" "." 12
 CALL :PadLeft @FC "!@FILES-COPIED!" "." 12

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
	 ECHO Total Jobs Executed ...!@JC!
	 ECHO Total Files Copied ....!@FC!
	 ECHO %@DIVIDER~%
	 ECHO:
 ) >"%@TEMPLOG%" 2>&1

 FOR %%O IN (CON "%@SUMMARY%" "%@LOGFILE%") DO TYPE "%@TEMPLOG%" >>%%O 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Mail Log File To Appropriate Group
 rem === Updated On: 30 Apr 2015 / 20 Jan 2015
 rem ==========================================================================
:SendLog
 IF /I "%@MAIL%"=="TRUE" (
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

	 ECHO:
	 BLAT "%@SUMMARY%" -f %@MAILSENDER% %@RCPT-TO% -s "%~n0 Job on %COMPUTERNAME%: %@INFO%" -attach "%@LOGFILE%","%@TIMINGS%"
	 CALL :ForwardToSyslog "6" Mailed %~n0 Job Report on %COMPUTERNAME%: %@INFO% -- "%@LOGFILE%" >NUL
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Log Management/Maintenance (Or Copy Them for Debug Purposes)
 rem === Updated On: 19 Jan 2015
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
 ECHO To See All Jobs, type: %~n0 #
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Execute a Single Copy Stream
 rem === Updated On: 28 Jul 2024 / 01 Nov 2020 / 21 Jul 2019
 rem ==========================================================================
:ExecuteCopy
 rem %1 = Source Location variable for ROBOCOPY Command
 rem %2 = Destination Location variable for ROBOCOPY Command
 rem %3 = File Mask for ROBOCOPY Command
 rem %4 = Recursion Option for ROBOCOPY Command

 CALL SET @CURRENT_SOURCE=%%%~1%%
 CALL SET @CURRENT_DEST=%%%~2%%
 CALL SET @CURRENT_MASK=%%%~3%%
 CALL SET @CURRENT_RECURSION=%%%~4%%
 IF DEFINED @CURRENT_RECURSION SET @CURRENT_RECURSION=!@CURRENT_RECURSION:"=!

 rem -- Exit if Backup Already Successful for this Source
 IF /I NOT "%@MULTIDEST%"=="TRUE" IF DEFINED #!@CURRENT_SOURCE! EXIT /B

 ROBOCOPY "%@CURRENT_SOURCE%" "%@CURRENT_DEST%" %@CURRENT_MASK% %@THREADS% %@RETRIES% %@CURRENT_RECURSION% /XO /NP %@PARAMS% %@SKIPFILE% %@SKIPDIR% /LOG+:"%@LOGFILE%"
 IF %ERRORLEVEL% LSS 16 (
	 SET #!@CURRENT_SOURCE!=SUCCESS
	 SET /A @ATTEMPTS+=1
 )

 rem -- Display Source/Destination Folders in Tree Format
 IF /I "%@SHOWTREE%"=="TRUE" (
	 ECHO:
	 ECHO *** SOURCE FOLDER INFO ***
	 %@TREECMD% "%@CURRENT_SOURCE%"
	 ECHO:
	 ECHO *** DESTINATION FOLDER INFO ***
	 %@TREECMD% "%@CURRENT_DEST%"
	 ECHO:
 ) >>"%@LOGFILE%"

 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display All The Jobs In The Copy Stream
 rem === Updated On: 28 Jul 2024 / 21 Jul 2019 / 19 Jan 2015
 rem ==========================================================================
:DisplayCopy
 rem %1 = Source Location variable for ROBOCOPY Command
 rem %2 = Destination Location variable for ROBOCOPY Command
 rem %3 = File Mask for ROBOCOPY Command
 rem %4 = Recursion Option for ROBOCOPY Command
 rem %5 = Boolean value to determine format of output (LONG or SHORT)

 CALL SET @CURRENT_SOURCE=%%%~1%%
 CALL SET @CURRENT_DEST=%%%~2%%
 CALL SET @CURRENT_MASK=%%%~3%%
 CALL SET @CURRENT_RECURSION=%%%~4%%
 CALL :GetFreeDiskSpace "%@CURRENT_SOURCE%" @FREESPACE_S
 CALL :GetFreeDiskSpace "%@CURRENT_DEST%"   @FREESPACE_D TRUE

 IF "%~5"=="" ( rem -- Default to Long View
	 ECHO SOURCE ......... %@CURRENT_SOURCE% [!@FREESPACE_S!]
	 ECHO DESTINATION .... %@CURRENT_DEST% [!@FREESPACE_D!]
	 ECHO MASK/SUBDIRS ... %@CURRENT_MASK%  %@CURRENT_RECURSION%
 ) ELSE (
	 ECHO S: %@CURRENT_SOURCE% [!@FREESPACE_S!]
	 ECHO D: %@CURRENT_DEST% [!@FREESPACE_D!]
	 ECHO P: %@CURRENT_MASK%  %@CURRENT_RECURSION%
 )
 ECHO:
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Determine Free Disk Space
 rem === Updated On: 19 Jan 2015
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
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Convert Large Number to KB, MB, GB, TB or PB
 rem === Updated On: 23 Feb 2015 / 19 Jan 2015
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
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 16 Oct 2023 / 23 Mar 2015
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Replace Parentheses with Brackets in Variables
 rem === Updated On: 19 Jan 2015
 rem ==========================================================================
:ReplaceParentheses
 rem %1 = Variable Name

 IF NOT DEFINED %1 EXIT /B
 SET %~1=!%~1:(=[!
 SET %~1=!%~1:)=]!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Remove Trailing \ From Supplied Folder Path
 rem === Updated On: 25 Feb 2019 / 19 Jan 2015
 rem ==========================================================================
:FixDirectoryPath
 rem %1 = Folder Variable

 IF NOT DEFINED %1 EXIT /B
 IF "!%~1:~-1!"=="\" (
	 SET %~1=!%~1:~0,-1!
	 GOTO :FixDirectoryPath
 )
 %@PRINT_IF_DEBUG%
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
	 SET @PARAMS=!@PARAMS: %~1=!)
	 SET @JOBPATH=!@JOBPATH: %~1=!
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
 rem === Updated On: 30 Sep 2025 / 12 Apr 2024 / 07 Apr 2024 / 25 Jan 2022 / 27 Apr 2020
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @JC "!@JOBCOUNT!" " " 2
 CALL :PadLeft @AT "!@ATTEMPTS!" "0" 2
 CALL :PadLeft @FC "!@FILES-COPIED!" "." 6
 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 IF "%~1"=="" IF "!@JOBCOUNT!"=="0" SET @SPECIAL=!@SPECIAL! // ABORTED - SOURCE FOLDERS NOT FOUND
 SET @JOBHISTORY=%@INFO% // JOBS:%@JC% [%@AT%] // FILES COPIED.%@FC% // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %~n0 %@VERSION%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('READABLE "%@TIMINGS%" -F "/" --TO -Q') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY "%@TIMINGS%" "!@OLDTIME!" /V /Y >CON
	 READABLE "!@OLDTIME!" --ST -%@MINROWS% -O "%@TIMINGS%"
	 ECHO:
	 CALL :ForwardToSyslog "5" %@INFO%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>"%@LOGFILE%" 2>>"%@ERRORS%"

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@RUNMODE!!@TRUNCATED! >>"%@TIMINGS%" 2>>"%@ERRORS%"
 %@VERBOSE_ON%
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 25 Sep 2024 / 13 Jan 2020 / 07 Mar 2019
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
 rem === Updated On: 23 Jun 2024 / 14 Jan 2020 / 26 Jul 2018
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
 rem === Updated On: 30 Nov 2020 / 29 Apr 2018
 rem ==========================================================================
:HelpMessage
 ECHO Replicate Files Between Local or Remote Servers
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<name_of_copy_job^>  [additional ROBOCOPY parameters]
 ECHO  %~n0  ^<name_of_copy_job^>  [. ^| OPTIONS]
 ECHO  %~n0  -h^|-?^|-h2^|-??^|#
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO       .  ..... Schedule the Job, But Don't Execute It
 ECHO       @  ..... Execute the Job without Scheduling It
 ECHO       -  ..... Remove Job from Task Scheduler
 ECHO       *  ..... Truncate Job History Logfile
 ECHO       ~  ..... Test/Diagnostics Mode [execute test configuration]
 ECHO       #  ..... Display All Possible Backup Jobs Which are Valid for This Computer
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 MyCriticalFiles
	 ECHO  %~n0 "MyCriticalFiles" /L
	 ECHO  %~n0 TheObsoleteJob -
	 ECHO  %~n0 MyStuff /MIR
	 ECHO  %~n0 ZipCodeDatabase *
	 ECHO  %~n0 "ZipCodeDatabase" /MON:1
	 ECHO  %~n0 Repository @
	 ECHO  %~n0 TheTestJob ~
	 ECHO  %~n0 #
	 ECHO  %~n0 -?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO:
	 ECHO  * The name of the copy job cannot contain ANY spaces. Spaces are
	 ECHO    permissable in the job description, however. Shortnames *can* be
	 ECHO    surrounded by quotes if you choose, but it is not mandatory.
	 ECHO:
	 ECHO  * An elevated CMD promt is required in Windows 2008+ in order to display
	 ECHO    the list of scheduled archive tasks.
	 ECHO:
	 ECHO  * Do not use ^(^) in the values of @INFO, @JOBNAME or MSGx variables, as
	 ECHO    these characters will likely prevent the successful completion of this
	 ECHO    script. Please use {} or [] characters instead.
	 ECHO:
	 ECHO  * The recommended way to enter additional ROBOCOPY parameters is via
	 ECHO    the Replication-Info.TXT INPUT file.
 )

 IF DEFINED @SHOWALL IF DEFINED @JOBLIST (
	 ECHO:
	 ECHO:
	 ECHO The following are valid potential jobs for this system [%COMPUTERNAME%]:
	 ECHO %@DIVIDER%
	 FOR /F "TOKENS=1* DELIMS==" %%B IN ('SET @VALIDJOB-') DO ECHO  %~n0  %%~C @
	 ECHO:
	 ECHO:
	 ECHO  The following archive jobs are scheduled on this system [%COMPUTERNAME%]:
	 ECHO %@DIVIDER%
	 FOR /F "TOKENS=3*" %%B IN ('SCHTASKS ^| FIND /I "Replicate Files -"') DO ECHO   %%C
 )
 CALL :ShowStatus "FINISHED"
                         