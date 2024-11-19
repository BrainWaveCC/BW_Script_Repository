@ECHO OFF
 rem ==========================================================================
 rem === Move Local Archive Files to the Network (default: older than 30 days)
 rem ==========================================================================
 rem
 rem Created On: 03 Nov 2011
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
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem
 rem    CHOICE ................. Native in Windows 2003+ / Reskit in NT/2000
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    ArchiveInfo.TXT ........ List of source and destination folder(s)
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This purpose of this script is to move existing zip archives in a folder
 :::  tree to a central remote location, and to delete those in the network
 :::  location that are older than a certain age.
 :::
 :::  This is a companion script to the Zip*.BAT and *Archive.BAT scripts, and
 :::  uses the same input file (ArchiveInfo.TXT) that they do.  By default, the
 :::  script runs daily and uses the SYSTEM account for credentials, but will
 :::  need different credentials if the archival shares are remote.
 :::
 :::  (Dec 2011) v1.1 -- added support for converting UNC paths to
 :::  a mapped drive letter to accomodate the FORFILES command (which does not
 :::  appreciate UNC paths).
 :::
 :::  (Dec 2011) Simplified the job scheduling section by way of environment
 :::  variables for verifying whether to use SCHTASKS or the AT command.
 :::
 :::  (Feb 2012) v1.5 -- Enabled to option to save backup files to the root
 :::  destination folder (without jobname or computer name) by setting the
 :::  @SIMPLEDEST variable to "TRUE" in the ArchiveInfo.TXT config file. Also
 :::  added the ability to email the job logs to recipients using the variables
 :::  from the CustomVariables.TXT input file.
 :::
 :::  (Apr 2012) v1.9 -- Synchronized several subroutines across the entire
 :::  family of SQL*.BAT and *Archive*.BAT scripts, including the routines for
 :::  calculating/displaying free disk space before and after copy/delete
 :::  operations.
 :::
 :::  (Nov 2012) To compensate for a parsing bug in the task scheduler of
 :::  certain versions of Windows (including Windows 8), the script was
 :::  changed to eliminate the use of quotation marks in the job parameters.
 :::  For more details, see: http://support.microsoft.com/kb/951246
 :::
 :::  (Dec 2012) Made it possible for the scheduled tasks to be stored in their
 :::  own folder, rather than the default root folder of the Task Scheduler.
 :::
 :::  (Sep 2013) v2.0 -- The TIMINGS Logfile will be reduced to the minimum
 :::  row size whenever it exceeds the maximum log row size, as defined by the
 :::  following variables:  %@MAX_LOG_ROWS% and %@MIN_LOG_ROWS%
 :::
 :::  (Oct 2013) v2.3 -- The delimiter for all parameters can be either the
 :::  "-" or the "/" character.  This includes the help parameters.
 :::
 :::  (Nov 2013) v2.6 -- The script will now display any currently scheduled
 :::  MoveArchives.BAT jobs on the current system, when the list of valid
 :::  jobs is displayed.  This requires an elevated prompt in 2008 and later
 :::  editions of Windows.
 :::
 :::  (Feb 2014) v2.8 -- Added the capability to send log data to one or more
 :::  Syslog servers using the SyslogGen or NeoLog utilities in conjunction
 :::  with the @SYSLOGx environment variables.
 :::
 :::  (Mar 2014) v2.9 -- Upgraded the DebugMode options to add another
 :::  variable (@PRINT_IF_DEBUG). Also revamped the routines for logging to
 :::  Syslog servers.
 :::
 :::  (Apr 2014) v2.10 -- Documented two parameters which have been available
 :::  for some time. One is for scheduling a move job without running it, and
 :::  the other is for running a move job without scheduling it.
 :::
 :::  (Dec 2014) v2.14 -- Added the ability to select from a list of possible
 :::  source folders for a single job.  The last valid folder in the list is
 :::  selected for the job.  The letters A through K are valid variables for
 :::  the list elements. (e.g. @SOURCE1A to @SOURCE1K)
 :::
 :::  (Jan 2015) v3.0 -- Updated to use timestamped logfiles, managed with the
 :::  new logfile maintenance routine.
 :::
 :::  (Jan 2015) v3.1 -- Moved the file pruning operation to occur prior to
 :::  the zip archiving, to ensure adequate free space for new jobs, and to
 :::  avoid pruning old files in a single pass. Improved job reporting
 :::
 :::  (Feb 2015) v3.3 -- Added options for controlling how the destination
 :::  folder is named based upon the @DESTFORMAT variable.  Valid options are
 :::  {INFO}, {HOST}, {INFO}\{HOST}, {INFO}-{HOST}, {HOST}\{INFO} and
 :::  {HOST}-{INFO}. This variable is only active if @SIMPLEDEST is FALSE.
 :::
 :::  (Mar 2015) v3.5 -- Migrated more variables to SetDrive.BAT;  Simplified
 :::  log output for normal mode, and expanded log output for diagnostics mode.
 :::
 :::  (Mar 2015) v3.6 -- Added the $ parameter to allow a one-time move of all
 :::  selected files, with no purging.
 :::
 :::  (Mar 2015) v3.7 -- Track total elapsed time of archive migration job
 :::  using a new version of DATEINFO
 :::
 :::  (Nov 2015) v3.9 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Oct 2017) v3.10 -- Can now process multiple destinations (the first valid
 :::  destination will receive the files; all valid destinations are pruned)
 :::
 :::  (Jan 2018) v3.11 -- Changed the HELP routine to use FINDSTR;
 :::  -- Fixed a new issue with using FINDSTR /R /C in checking for scheduled jobs;
 :::  -- Migrated :SaveJobHistory to a subroutine, for additional flexibility;
 :::  -- Invalid job attempts are now recorded in the .RECORDING.TXT file.
 :::
 :::  (Feb 2018) v3.12 -- Added filtered CMD Title Routine;
 :::  -- Added @ATTEMPTS counter to the .RECORDING.TXT status file
 :::
 :::  (Feb 2018) v4.0 -- The processing of multiple SOURCE folders has been made
 :::  consistent across scripts: The FIRST valid SOURCE is the one selected;
 :::
 :::  (Apr 2018) v4.1 -- Improved the performance of reading variables from
 :::  the ArchiveInfo.*.TXT INPUT files, using FINDSTR;
 :::  -- The SYNTAX HELP routine has been updated;
 :::  -- Support for NeoLogger has been eliminated from this script;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v4.2 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v4.3 -- Removed AT command support;
 :::
 :::  (Oct 2018) v4.4 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Mar 2019) v4.5 -- Enabled Code Page 1252 Support;
 :::  -- Record additional attributes in the Job History log;
 :::  -- Prevent DEBUG MODE data from being stored in the .RECORDING.TXT file
 :::
 :::  (May 2019) v5.0 -- Add the ability to skip files via @SKIPFILE;
 :::
 :::  (Oct 2019) v5.1 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v5.2 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Dec 2019) v5.3 -- Updated :ShowStatus routine to use BrainWave NOW.exe;
 :::
 :::  (Jan 2020) v5.4 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Added a routine for validating integer parameters;
 :::  -- Refactored the :Prepare4Syslog routine;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::
 :::  (Apr 2020) v5.5 -- Expanded the DEBUG logging to include a STEP parameter;
 :::  -- Replaced FINDSTR with BrainWave ReadConfig.exe for reading config file;
 :::
 :::  (May 2020) v5.6 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::  -- Streamlined Completion Status via NOW.EXE;
 :::  -- Added support for a MINI edition of the ARCHIVE-INFO config file;
 :::
 :::  (Nov 2020) v5.7 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::  -- Fixed a minor issue with the Filtered CMD Title routine;
 :::
 :::  (Dec 2020) v5.8 -- Add timestamps to ongoing jobs;
 :::  -- Add a variable tracker (@MOVE-NEEDED) to avoid multiple attempts after
 :::  a successful move operation;
 :::
 :::  (Jan 2022) v5.9 -- Modify the @NAMECHK verification to include \ prefix;
 :::
 :::  (Oct 2023) v5.10 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (Apr 2024) v6.0 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::  (Jul 2024) v6.1 -- Replaced the :RunCMD routine with just a CALL command;
 :::
 :::  (Sep 2024) v6.2 -- Enable updates to local syslogs if requested;
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
 rem === Updated On: 30 Nov 2020 / 25 Feb 2018
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
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v6.2.0.630 b

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT"
 SET #MSUTILS=CHOICE.EXE FINDSTR.EXE SCHTASKS.EXE
 SET #O_UTILS=BLAT.EXE SYSLOGGEN.EXE TAIL.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES& GOTO :ExitBatch)

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @MAIL=FALSE
 SET @MAILPORT=25

 rem -- Job Scheduling Variables
 SET @JOBNAME=Move Archives - %~1
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=03:55:00
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
	 FOR /F "TOKENS=1 DELIMS=;" %%J IN ('READCONFIG "%%~C" -N -S "#MOVEARCHIVES" -P 2^>NUL') DO SET @VALIDJOB-%%~J=%%~J& SET @JOBLIST=TRUE
 )
 FOR %%N IN (JOBNAME INFO) DO CALL :ReplaceParentheses @%%N

 rem -- Main Variables
 SET @PARAMS=%*
 SET @CHANGES=FALSE
 SET @RUNMODE=
 SET @JOBNUM=0
 SET @JOBCOUNT=0
 SET @ATTEMPTS=0
 SET @TOTAL_MOVED=0
 SET @TOTAL_PRUNED=0
 SET @REMOTE=
 SET @FILEEXT=& FOR %%E IN (%@EXTENSIONS%) DO SET @FILEEXT=!@FILEEXT! *.%%~E
 SET @EXCEPTIONS=& FOR %%S IN (DIR FILE) DO IF DEFINED @SKIP%%~S SET @EXCEPTIONS=TRUE
 SET @SKIPFOLDERS=& IF DEFINED @EXCEPTIONS SET @SKIPFOLDERS=^^^| FINDSTR /V /I /R "%@SKIPDIR% %@SKIPFILE%"

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Archiving
 SET @LFORMAT=%@LOGPATH%\%~n0-%~1
 SET @TIMINGS=%@LFORMAT%.RECORDING.TXT
 SET @LOGFILE=%@LFORMAT%.%@FILESTAMP%
 FOR %%L IN (DEBUGLOG SUMMARY TEMPLOG ERRORS) DO SET @%%L=%@LFORMAT%.%%L.%@FILESTAMP%
 SET @LOGLIST="%@LOGFILE%" "%@DEBUGLOG%" "%@ERRORS%"
 SET @CLEANUP="%@TEMPLOG%" "%@SUMMARY%" "%@ERRORS%"

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "@" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "-" & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @UNSCHED=TRUE)
 CALL :GetParams "." & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @SCHEDULEONLY=TRUE& SET @UPDATESCHED=TRUE)
 CALL :GetParams "*" & IF DEFINED @OK (SET @PARAMS=!@PARAMS:%%~P=!& SET @MINROWS=1& SET @MAXROWS=1)
 CALL :GetParams "$" & IF DEFINED @OK (SET @PARAMS=!@PARAMS:%%~P=!& SET @MOVEALL=TRUE)
 CALL :GetParams "~" & IF DEFINED @OK (SET @PARAMS=!@PARAMS:%%~P=!& SET @TESTMODE=TRUE& SET @DIAGMODE=TRUE)
 CALL :GetParams "#" & IF DEFINED @OK (SET @SHOWALL=TRUE& GOTO :HelpMessage)

 rem -- Set Variables for Test Configurations
 IF /I "%@TESTMODE%"=="TRUE" (
	 CALL :GetInteger @MINROWS "%@T_MIN_LOG_ROWS%" 003 001 010
	 CALL :GetInteger @MAXROWS "%@T_MAX_LOG_ROWS%" 030 010 049
	 SET @MAILSENDER=LogAdmin-Test%@ORGFQDN%
	 SET @RCPT-TO=%@TEST-RCPTS%
	 SET @ALERT-TO=%@TEST-RCPTS%
	 SET @RUNMODE=!@RUNMODE! // TESTMODE
 )

 IF /I "%@MOVEALL%"=="TRUE" (
	 SET @MOVE_AFTER=0
	 SET @PURGE_AFTER=9999
	 SET @RUNMODE=!@RUNMODE! // MOVEALL
 )

 rem -- Set Variables for Special Modes
 SET @NOSCHED_MSG=Don't Schedule
 SET @UNSCHED_MSG=Unschedule
 SET @UPDATESCHED_MSG=Update Schedule
 SET @SCHEDULEONLY_MSG=Schedule ONLY
 SET @DIAGMODE_MSG=Diagnostics Logs
 SET @TESTMODE_MSG=Testing Mode
 SET @MOVEALL_MSG=Move All Archives
 SET @USE_SYSLOGS_MSG=Forward to Syslog
 SET @MODES=& FOR %%M IN (DIAGMODE TESTMODE USE_SYSLOGS MOVEALL NOSCHED UNSCHED UPDATESCHED SCHEDULEONLY) DO IF /I "!@%%~M!"=="TRUE" SET @MODES=!@%%~M_MSG! * !@MODES!
 IF "%@MODES%"=="" SET @MODES=NONE *
 IF /I NOT "%@SIMPLEDEST%"=="FALSE" SET @DESTFORMAT=**SIMPLE**

 rem -- Key Variable Verification
 SET @SOURCEDEST=
 FOR %%C IN ("" %@BASE10%) DO FOR %%X IN ("" %@ALPHA11%) DO IF DEFINED @SOURCE%%~C%%~X (
	 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L SET @SOURCEDEST=PRESENT
 )
 FOR %%V IN (ALL_PARAMS SOURCEDEST DESTFORMAT EXTENSIONS INFO JOBTIME JOBFREQ MOVE_AFTER PURGE_AFTER ALPHA11 BASE10) DO IF NOT DEFINED @%%~V (
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
 rem === Select Valid Source from List
 rem === Updated On: 20 Feb 2018 / 26 Jun 2017
 rem ==========================================================================
:SelectSourceFromList
 FOR %%C IN ("" %@BASE10%) DO (
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
 rem === Updated On: 10 May 2024 / 30 May 2019 / 30 Mar 2015
 rem ==========================================================================
:ShowHeader
 TITLE %@JOBNAME% [%@INFO%]
 FOR %%V IN ("%@LOGPATH%") DO IF NOT EXIST "%%~V" MD "%%~V" >NUL

 ECHO === Prepare to Execute the Following Archive Move Job ===

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER*%
	 ECHO *** %COMPUTERNAME% - [%DATE% at %TIME%] - %@VER%
	 ECHO *** Job Name .......... %@JOBNAME% [%@INFO%]
	 ECHO *** Job Schedule ...... %@JOBFREQ% at %@JOBTIME%  %@JOBDATE%
	 ECHO *** Job User .......... %@JOBUSER%
	 ECHO *** Dest Format ....... %@DESTFORMAT%
	 ECHO *** Global Modes ...... %@MODES:~0,-2%
	 ECHO *** Folders to Skip ... %@SKIPDIR%
	 ECHO *** Files to Skip ..... %@SKIPFILE%
	 ECHO %@DIVIDER*%
	 ECHO:
	 FOR %%C IN ("" %@BASE10%) DO IF DEFINED @SOURCE%%~C (
		 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L (
			 SET /A @JOBCOUNT+=1
			 CALL :FixDirectoryPath @SOURCE%%~C
			 CALL :FixDirectoryPath @DEST%%~C%%~L
			 CALL :DisplayCopy @SOURCE%%~C @DEST%%~C%%~L
		 )
	 )
	 IF "%@PURGE_AFTER%"=="9999" (SET @PURGE-INFO=NEVER) ELSE (SET @PURGE-INFO=%@PURGE_AFTER% days)
	 ECHO ARCHIVE MOVE JOBS ...................... !@JOBCOUNT!
	 ECHO ARCHIVE FILES TO BE MOVED ..............%@FILEEXT%
	 ECHO:
	 ECHO MOVE TO NETWORK STORAGE AFTER .......... %@MOVE_AFTER% days
	 ECHO DELETE FROM NETWORK STORAGE AFTER ...... !@PURGE-INFO!
	 ECHO:
	 ECHO ONLY RUN MANUALLY [NO SCHEDULED JOB] ... %@NOSCHED%
	 ECHO %@DIVIDER-%
	 ECHO:
 ) >"%@SUMMARY%" 2>&1

 TYPE "%@SUMMARY%"
 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 CHOICE /C YNQEX /T 20 /D Y /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :ExitBatch
 )
 IF /I "%@DIAGMODE%"=="TRUE" COPY "%@SUMMARY%" "%@DEBUGLOG%" /Y
 COPY "%@SUMMARY%" "%@LOGFILE%" /Y
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 12 Apr 2024 / 22 Jan 2022 / 26 Nov 2019
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
 rem === Enumerate Primary and Archive Zip Folders for Processing
 rem === Updated On: 27 Dec 2020 / 23 Dec 2020 / 20 Feb 2018
 rem ==========================================================================
:ProcessFolders
 ECHO:
 ECHO STARTED Moving Local Archive Files to Network Storage...

 FOR %%C IN ("" %@BASE10%) DO IF DEFINED @SOURCE%%~C (
	 SET @MOVE-NEEDED=TRUE

	 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L (
		 IF /I "!@MOVE-NEEDED!"=="TRUE" (
			 SET /A @JOBNUM+=1
			 CALL :FixDirectoryPath @SOURCE%%~C
			 CALL :FixDirectoryPath @DEST%%~C%%~L
			 CALL :VerifyFolders @SOURCE%%~C @DEST%%~C%%~L
			 IF /I "!@VALID!"=="TRUE" FOR %%E IN (%@EXTENSIONS%) DO (
				 SET /A @ATTEMPTS+=1
				 CALL :PruneArchive @DEST%%~C%%~L %%~E
				 CALL :MoveToNetwork @SOURCE%%~C @DEST%%~C%%~L %%~E
			 )
		 )
	 )
 )

 FOR %%D IN (!@REMOTE!) DO (
	 IF NOT DEFINED @DONE-%%~D (
		 SET @DONE-%%~D=TRUE
		 ECHO:
		 DIR /OGD /A "%%~D"
	 ) >>"%@LOGFILE%" 2>&1
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Footer
 rem === Updated On: 13 May 2020 / 25 Jan 2018
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
	 ECHO  Total Files Moved ...!@TM!
	 ECHO  Total Files Pruned ..!@TP!
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
 IF /I "%@MAIL%/%@CHANGES%"=="TRUE/TRUE" IF DEFINED @RCPT-TO (
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
 rem === Updated On: 12 Jan 2015 / 09 Jan 2015
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
 ECHO %@DIVIDER~%
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
 rem === SUBROUTINE: Echo Output to Multiple Destinations
 rem === Updated On: 20 Oct 2017 / 16 Mar 2015
 rem ==========================================================================
:EchoAll
:EchoAll0
:EchoAll2
 rem %* = Message to Display

 SET @OUT=%*
 SET @OUT=!@OUT: = !
 SET @CHK=%~1
 IF DEFINED @CHK SET @CHK=!@CHK:"=!
 FOR %%A IN (ALL ALL2 ALL2) DO IF "%~0"==":Echo%%A" ECHO:
 IF "!@CHK!"=="" (ECHO:) ELSE (ECHO !@OUT!)

:EchoSome
:EchoSome0
:EchoSome2
 SET @OUT=%*
 SET @OUT=!@OUT: = !
 IF /I "%@DIAGMODE%"=="TRUE" SET @OUT=!TIME: =0!: %@OUT%
 FOR %%B IN (CON "%@SUMMARY%") DO (
	 FOR %%A IN (SOME SOME2 SOME2 ALL ALL2 ALL2) DO IF "%~0"==":Echo%%A" ECHO: >>%%B
	 IF "%~1"=="" (ECHO: >>%%B) ELSE (ECHO !@OUT! >>%%B)
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine Destination Folder Format
 rem === Updated On: 11 Mar 2015 / 08 Feb 2015
 rem ==========================================================================
:SetDestFolder
 rem %1 = Current Destination Folder

 SET @D_FOLDER=
 IF /I "%@SIMPLEDEST%"=="FALSE" (
	 IF /I "%@DESTFORMAT%"=="{HOST}"        SET @D_FOLDER=%~1\%COMPUTERNAME%
	 IF /I "%@DESTFORMAT%"=="{HOST}\{INFO}" SET @D_FOLDER=%~1\%COMPUTERNAME%\%@INFO%
	 IF /I "%@DESTFORMAT%"=="{HOST}-{INFO}" SET @D_FOLDER=%~1\%COMPUTERNAME% - %@INFO%
	 IF /I "%@DESTFORMAT%"=="{INFO}"        SET @D_FOLDER=%~1\%@INFO%
	 IF /I "%@DESTFORMAT%"=="{INFO}\{HOST}" SET @D_FOLDER=%~1\%@INFO%\%COMPUTERNAME%
	 IF /I "%@DESTFORMAT%"=="{INFO}-{HOST}" SET @D_FOLDER=%~1\%@INFO% - %COMPUTERNAME%
 )

 IF NOT DEFINED @D_FOLDER SET @D_FOLDER=%~1
 SET @FULL_D_FOLDER=!@D_FOLDER!
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Verify That Source and Destination Exist
 rem === Updated On: 28 Jul 2024 / 09 Dec 2020 / 10 Feb 2015
 rem ==========================================================================
:VerifyFolders
 rem %1 = Current Source Folder, Encoded
 rem %2 = Current Destination Folder, Encoded

 SET @VALID=TRUE
 CALL SET @S_FOLDER=%%%~1%%
 CALL :SetDestFolder "%%%~2%%"

 rem -- Generate Diagnostics Logging
 IF /I "%@DIAGMODE%"=="TRUE" (
	 ECHO:
	 ECHO %%1=%~1
	 ECHO %%2=%~2
	 FOR %%Z IN (FULLPATH S_FOLDER D_FOLDER DLETTER FORFILES SKIPFOLDERS) DO ECHO @%%Z=!@%%Z!
	 ECHO %@DIVIDER-:~0,30%
 ) >>"%@DEBUGLOG%"

 ( rem -- Display Individual Job Summary
	 CALL :EchoALL ""
	 CALL :EchoALL %@DIVIDER*%
	 CALL :EchoAll *** [!TIME: =0!] VALIDATING FOLDERS FOR JOB #!@JOBNUM!
	 CALL :EchoAll %@DIVIDER*%

	 rem -- Check for Valid Source
	 IF NOT EXIST "%@S_FOLDER%" (SET @VALID=FALSE& CALL :EchoAll Could Not Access Source Folder: "%@S_FOLDER%")

	 rem -- Check for Valid Destination
	 IF NOT EXIST "%@D_FOLDER%" MD "%@D_FOLDER%"
	 IF NOT EXIST "%@D_FOLDER%" (SET @VALID=FALSE& CALL :EchoAll Could Not Write to Destination: "%@D_FOLDER%")

	 IF /I "!@VALID!"=="FALSE" (
		 ECHO %@DIVIDER*%
		 ECHO %@DIVIDER#%
		 ECHO:
		 ECHO:
	 )
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Move Zips to Central Storage %@MOVE_AFTER% Days
 rem === Updated On: 28 Jul 2024 / 23 Dec 2020 / 09 Dec 2020 / 24 Feb 2018
 rem ==========================================================================
:MoveToNetwork
 rem %1 = Current Source Folder, Encoded
 rem %2 = Current Destination Folder, Encoded
 rem %3 = Extension to Process

 CALL SET @S_FOLDER=%%%~1%%
 CALL :ConvertUNC @S_FOLDER
 CALL :SetDestFolder "%%%~2%%"
 SET @REMOTE=!@REMOTE! "!@D_FOLDER!"
 SET @ZIPEXT=%~3
 SET @ZIPEXT=%@ZIPEXT:+=*%
 SET @FORFILES=FORFILES -s -p"%@S_FOLDER%" -m*.%@ZIPEXT% -d-%@MOVE_AFTER% -c"CMD /C IF @ISDIR==FALSE ECHO @PATH\@FILE"
 SET @FILES_MOVED=0

 IF EXIST "%SystemRoot%\System32\FORFILES.EXE" (
	 SET @FORFILES=%SystemRoot%\System32\FORFILES -s -p "%@S_FOLDER%" -m *.%@ZIPEXT% -d -%@MOVE_AFTER% -c "CMD /C IF @ISDIR==FALSE ECHO @PATH"
 )

 rem -- Generate Diagnostics Logging
 IF /I "%@DIAGMODE%"=="TRUE" (
	 ECHO:
	 ECHO %%1=%~1
	 ECHO %%2=%~2
	 ECHO %%3=%~3
	 FOR %%Z IN (FULLPATH S_FOLDER D_FOLDER DLETTER FORFILES SKIPFOLDERS) DO ECHO @%%Z=!@%%Z!
	 ECHO %@DIVIDER-:~0,30%
 ) >>"%@DEBUGLOG%"

 ( rem -- Write to Log
	 IF NOT EXIST "%@D_FOLDER%" MD "%@D_FOLDER%"
	 IF NOT EXIST "%@D_FOLDER%" (
		 CALL :EchoAll Could Not Write to Destination: "%@D_FOLDER%"
	 ) ELSE (
		 CALL :EchoALL *** [!TIME: =0!] Moving Local [*.%@ZIPEXT%] files greater than %@MOVE_AFTER% days old to the Network ***
		 IF /I "%@DIAGMODE%"=="TRUE" (
			 CALL :EchoALL Current Source ........ %@FULLPATH% %@DLETTER%
			 CALL :EchoAll Current Destination ... %@D_FOLDER%
			 CALL :EchoAll %@DIVIDER~%
		 ) ELSE (
			 CALL :EchoAll
		 )
		 FOR /F "TOKENS=*" %%V IN ('%@FORFILES% %@SKIPFOLDERS% 2^>NUL') DO (
			 CALL :EchoAll  [!TIME: =0!] Moving "%%~V"
			 MOVE "%%~V" "%@D_FOLDER%"
			 SET @CHANGES=TRUE
			 SET /A @FILES_MOVED+=1
			 SET /A @TOTAL_MOVED+=1
		 )
		 IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 SET @MOVE-NEEDED=FALSE
		 IF NOT "!@FILES_MOVED!"=="0" CALL :EchoAll %@DIVIDER~%
		 CALL :GetFreeDiskSpace "%@S_FOLDER%" @FREESPACE_S
		 CALL :GetFreeDiskSpace "%@D_FOLDER%" @FREESPACE_D
		 CALL :EchoAll *.%@ZIPEXT% File[s] Moved: !@FILES_MOVED!
		 CALL :EchoALL SOURCE........ %@S_FOLDER%
		 CALL :EchoAll Free Space.... !@FREESPACE_S!
		 CALL :EchoALL DESTINATION... %@D_FOLDER%
		 CALL :EchoAll Free Space.... !@FREESPACE_D!
		 CALL :EchoAll %@DIVIDER~%
	 )

	 IF DEFINED @DLETTER NET USE %@DLETTER% /D /Y
	 ECHO %@DIVIDER#%
	 ECHO:
	 ECHO:
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Delete All Zips Older Than %@PURGE_AFTER% Days
 rem === Updated On: 09 Dec 2020 / 11 Mar 2015
 rem ==========================================================================
:PruneArchive
 rem %1 = Current Network Zip Storage, Encoded
 rem %2 = Extension to Process

 IF "%@PURGE_AFTER%"=="9999" GOTO :EOF
 CALL :SetDestFolder "%%%~1%%"
 CALL :ConvertUNC @D_FOLDER
 SET @ZIPEXT=%~2
 SET @ZIPEXT=%@ZIPEXT:+=*%
 SET @FORFILES=FORFILES -p"%@D_FOLDER%" -m*.%@ZIPEXT% -d-%@PURGE_AFTER% -c"CMD /C IF @ISDIR==FALSE ECHO @PATH\@FILE"
 SET @FILES_PRUNED=0

 rem -- Set Marker to Purge Destination Folder Only Once per Extension
 SET @THISDEST=%@FULL_D_FOLDER%-%~2
 SET @THISDEST=!@THISDEST:*=+!
 IF DEFINED !@THISDEST! (GOTO :EOF) ELSE (SET !@THISDEST!=TRUE)

 IF EXIST "%SystemRoot%\System32\FORFILES.EXE" (
	 SET @FORFILES=%SystemRoot%\System32\FORFILES -p "%@D_FOLDER%" -m *.%@ZIPEXT% -d -%@PURGE_AFTER% -c "CMD /C IF @ISDIR==FALSE ECHO @PATH"
 )

 rem -- Generate Diagnostics Logging
 IF /I "%@DIAGMODE%"=="TRUE" (
	 ECHO:
	 ECHO %%1=%~1
	 ECHO %%2=%~2
	 FOR %%Z IN (FULLPATH S_FOLDER D_FOLDER DLETTER FORFILES SKIPFOLDERS) DO ECHO @%%Z=!@%%Z!
	 ECHO %@DIVIDER-:~0,30%
 ) >>"%@DEBUGLOG%"


 ( rem -- Write to Log
	 CALL :EchoALL *** [!TIME: =0!] Pruning Network Archives of [*.%@ZIPEXT%] files greater than %@PURGE_AFTER% days old ***
	 IF /I "%@DIAGMODE%"=="TRUE" (
		 CALL :EchoALL Checking: %@FULLPATH% %@DLETTER%
		 CALL :EchoAll %@DIVIDER~%
	 ) ELSE (
		 CALL :EchoAll
	 )
	 FOR /F "TOKENS=*" %%V IN ('%@FORFILES% 2^>NUL') DO (
		 CALL :EchoAll - "%%~V"
		 DEL "%%~V"
		 SET @CHANGES=TRUE
		 SET /A @FILES_PRUNED+=1
		 SET /A @TOTAL_PRUNED+=1
	 )
	 IF NOT "!@FILES_PRUNED!"=="0" CALL :EchoAll %@DIVIDER~%
	 CALL :GetFreeDiskSpace "%@D_FOLDER%" @FREESPACE_D
	 CALL :EchoAll *.%@ZIPEXT% File[s] Pruned: !@FILES_PRUNED!
	 CALL :EchoALL ARCHIVE folder... %@FULLPATH% %@DLETTER%
	 CALL :EchoAll Free Space....... !@FREESPACE_D!
	 CALL :EchoAll %@DIVIDER~%

	 IF DEFINED @DLETTER NET USE %@D_FOLDER% /D /Y
	 ECHO %@DIVIDER#%
	 ECHO:
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Display All The Jobs In The Copy Stream
 rem === Updated On: 28 Jul 2024 / 28 Oct 2013 / 20 Nov 2012
 rem ==========================================================================
:DisplayCopy
 rem %1 = Source Location variable for archives
 rem %2 = Destination Location variable for archives
 rem %3 = Boolean value to determine format of output (LONG or SHORT)

 CALL SET @CURRENT_SOURCE=%%%~1%%
 CALL SET @CURRENT_DEST=%%%~2%%
 CALL :GetFreeDiskSpace "%@CURRENT_SOURCE%" @FREESPACE_S
 CALL :GetFreeDiskSpace "%@CURRENT_DEST%"   @FREESPACE_D TRUE

 IF "%~3"=="" ( rem -- Default to Long View
	 ECHO SOURCE ......... %@CURRENT_SOURCE% [!@FREESPACE_S!]
	 ECHO DESTINATION .... %@CURRENT_DEST% [!@FREESPACE_D!]
 ) ELSE (
	 ECHO S: %@CURRENT_SOURCE% [!@FREESPACE_S!]
	 ECHO D: %@CURRENT_DEST% [!@FREESPACE_D!]
 )
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
 rem === SUBROUTINE: Map a UNC Path to Drive Letter (w/Diagnostics Logging)
 rem === Updated On: 28 Jul 2024 / 13 Jan 2015 / 09 Jan 2015
 rem ==========================================================================
:ConvertUNC
 rem %1 = Variable Containing UNC Path to Convert

 SET @DLETTER=
 CALL SET @FULLPATH=%%%~1%%
 TYPE NUL >"%@TEMPLOG%"
 FOR /F %%U IN ('ECHO "!@FULLPATH!" ^| FIND "\\"') DO (
	 FOR /F "TOKENS=2" %%P IN ('NET USE * "!@FULLPATH!" /PERSISTENT:NO ^| FIND /I "is now connected to !@FULLPATH!" ') DO (
		 CALL SET %~1=%%P
		 SET @DLETTER=[%%P]
	 )
 ) >"%@TEMPLOG%" 2>&1

 IF /I "%@DIAGMODE%"=="TRUE" (TYPE "%@TEMPLOG%" >>"%@DEBUGLOG%") ELSE (TYPE "%@TEMPLOG%")
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
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 16 Oct 2023 / 23 Mar 2015
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
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
 rem === Updated On: 21 Jan 2020
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
 rem === Updated On: 12 Apr 2024 / 07 Apr 2024 / 15 Oct 2019 / 09 Mar 2019
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @JC "!@JOBCOUNT!" "0" 2
 CALL :PadLeft @AT "!@ATTEMPTS!" "0" 2
 CALL :PadLeft @TM "!@TOTAL_MOVED!" "." 3
 CALL :PadLeft @TP "!@TOTAL_PRUNED!" "." 3
 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 IF "%~1"=="" IF "!@JOBCOUNT!"=="0" SET @SPECIAL=!@SPECIAL! // ABORTED - SOURCE FOLDERS NOT FOUND
 SET @JOBHISTORY=%@INFO% // JOBS:%@JC%:%@AT% // FILES [MOVED.%@TM% PRUNED.%@TP%] // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %~n0 %@VERSION%%@SPECIAL%

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
 rem === Updated On: 25 Sep 2024 / 13 Jan 2020 / 07 Mar 2019
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
 rem === Updated On: 23 Jun 2024 / 14 Jan 2020 / 23 Apr 2018
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
 rem === Updated On: 03 Sep 2024 / 15 May 2018 / 05 Feb 2015
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
 ECHO Move Local Archive Files to Network Repository...
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<name_of_archive_job^>  [OPTIONS]
 ECHO  %~n0  [-h^|-?^|-h2^|-??^|#]
 ECHO:
 IF DEFINED @MOVE_AFTER IF DEFINED @PURGE_AFTER (
	 ECHO  * Number of days before local archives are moved .....: %@MOVE_AFTER%
	 ECHO  * Number of days before network archives are purged ..: %@PURGE_AFTER%
	 ECHO:
 )
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
 ECHO       $  ..... Set Move/Delete Options to 0/NEVER to move all files now
 ECHO       #  ..... Display All Possible Backup Jobs Which are Valid for This Computer
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 OldArchives
	 ECHO  %~n0 "MyOldArchives"
	 ECHO  %~n0 TheObsoleteJob -
	 ECHO  %~n0 MyStuff .
	 ECHO  %~n0 ZipCodes *
	 ECHO  %~n0 LogFiles $
	 ECHO  %~n0 Repository @
	 ECHO  %~n0 TheTestJob ~ @
	 ECHO  %~n0 #
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
	 FOR /F "TOKENS=1* DELIMS==" %%B IN ('SET @VALIDJOB-') DO ECHO  %~n0  %%~C @
	 ECHO:
	 ECHO:
	 ECHO  The following archive jobs are scheduled on this system [%COMPUTERNAME%]:
	 ECHO %@DIVIDER%
	 FOR /F "TOKENS=3*" %%B IN ('SCHTASKS ^| FIND /I "Move Archives -"') DO ECHO   %%C
 )
 CALL :ShowStatus "FINISHED"
             