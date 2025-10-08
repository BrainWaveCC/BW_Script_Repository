@ECHO OFF
 rem ==========================================================================
 rem === Monthly Archive of Old Log Files in ZIP (Traverse Directory Tree)
 rem ==========================================================================
 rem
 rem Created On: 22 Jun 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 26 Sep 2025 / 14 Aug 2025 / 26 Sep 2024 / 03 Sep 2024
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
 rem    CHOICE ................. Native in Windows 2003+ / Reskit in NT/2000
 rem    PSTOOLS ................ https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This purpose of this script is to create a zip archive of all files in a
 :::  given directory tree which match a particular pattern such as *.LOG,
 :::  *.TXT, or LOG*.TXT.  The name of the root folder is the only parameter
 :::  which must be passed to the script at the command line.  All other
 :::  variables should be set within the script itself.
 :::
 :::  All files in the folder which match the filespec, but are older than the
 :::  1st day of the month in which the script is run (basically, all files
 :::  created in a previous month) will be zipped into a file containing the
 :::  current year+month in the name, and then deleted once the archive has
 :::  been validated. (If you don't want the originals deleted, remove the -m
 :::  parameter from the ZIP command). The script will attempt to schedule a
 :::  monthly job to run as SYSTEM, but the account can be changed via the
 :::  Task Scheduler or the environment variables.
 :::
 :::  Over time, you'll want to start pruning the zip archive folder, as it
 :::  will steadily consume diskspace.  The script now includes a self-purging
 :::  routine that will move files into an "Archive" folder after 100 days,
 :::  and then delete any files in this archive folder than are older than
 :::  550 days. These defaults can all be changed by altering the two %@KEEP_%
 :::  variables (@KEEP_SHORT-TERM and @KEEP_HISTORICAL), or by entering the
 :::  two parameters at the command prompt.  You might find it best to keep
 :::  the files around for a least 3 months for easy comparison.
 :::
 :::  The zip compatible compression is provided courtesy of the free
 :::  InfoZip utilities, which support all versions of Windows since 2001,
 :::  (has been tested on XP and later) and can process files in excess of 4GB.
 :::
 :::  (Jul 2010) In order to support archiving multi-extension files, such as
 :::  *.TXT.LOG or *.LOG.###, the @FILESPEC variable will accept entries such
 :::  as "LOG.+" or "TXT.+".  This is because of the way the FOR command
 :::  handles the * character, and the fact that the @FILESPEC variable
 :::  contents are passed to the FOR comamnd for processing. Variable
 :::  substitution will turn all "+" characters into "*" characters at time
 :::  of execution.  No provision is currently made for the "?" wildcard.
 :::
 :::  (Jul 2010) Support has also been added for the "CustomVariables.TXT"
 :::  input file, so that changes to the @FILESPEC, @EXCLUDE and @BYPASS
 :::  variables can be supported without modifying the script each time.
 :::
 :::  (Jul 2010) Specific deviations from the otherwise global @FILESPEC
 :::  criteria can made on a folder by folder level, by creating a file
 :::  called "@ZipLogsOverride.INPUT" in the local folder.  The contents of
 :::  this folder are identical to the desired @FILESPEC.  The name of the
 :::  file can be set and modified in the "CustomVariables.TXT" input file.
 :::
 :::  (Nov 2010) Added the name of the current machine as the prefix to
 :::  the archive name.  This will make it easier to store multiple logs
 :::  of the same type from a farm of servers in a central location.
 :::
 :::  (Nov 2010) v4.3 -- Added the option of deleting or not deleting empty
 :::  folders during log processing by way of a fourth (4th) parameter on
 :::  the command-line. If the value is TRUE, then empty folders will be
 :::  removed during the pruning/archival section of the script.  If no value
 :::  is provided, the default setting is FALSE. If you would like to maintain
 :::  the old behavior without changing all your scheduled jobs, then add the
 :::  @DELEMPTY variable with a setting of TRUE to your "CustomVariables.TXT"
 :::  file.  Please note that this will override whatever setting you make
 :::  for EVERY ZipLogs-*.BAT job.
 :::
 :::  (Mar 2011) The DblCheck routine has been updated to use the CHOICE.EXE
 :::  command rather than the TIMEOUT command.  This allows more flexibility
 :::  to abort or continue with the script.
 :::
 :::  (Dec 2011) Simplified the job scheduling section by way of environment
 :::  variables for verifying whether to use SCHTASKS or the AT command.
 :::
 :::  (Jan 2012) v4.8 -- The script has been configured to preserve the entire
 :::  path name as part of the archive name so that when archives are moved,
 :::  the source location can be easily identified.
 :::
 :::  The issue of supporting long path names via SCHTASKS was a vexing one
 :::  until I came across a KB article that outlines the \ character as the
 :::  escape character for quotation marks.  (e.g. \" )
 :::  For more details, see: http://support.microsoft.com/kb/823093
 :::
 :::  (Nov 2012) Because of a bug in how certain versions of Windows parse
 :::  quotes in a scheduled task, the script was changed to use only the
 :::  short name of folders in the path, eliminating the need for quotes.
 :::  For more details, see: http://support.microsoft.com/kb/951246
 :::
 :::  (Dec 2012) Made it possible for the scheduled tasks to be stored in their
 :::  own folder, rather than the default root folder of the Task Scheduler.
 :::
 :::  (Jan 2013) v5.0 -- Now uses the normal path name unless it contains
 :::  spaces, in which case, use the short name.
 :::
 :::  (Feb 2014) v5.2 -- Added the capability to send log data to one or more
 :::  Syslog servers using the SyslogGen or NeoLog utilities in conjunction
 :::  with the @SYSLOGx environment variables.
 :::
 :::  (Mar 2014) v5.3 -- Upgraded the DebugMode options to add another
 :::  variable (@PRINT_IF_DEBUG). Also revamped the routines for logging to
 :::  Syslog servers.
 :::
 :::  (Apr 2014) v5.4 -- Documented two parameters which have been available
 :::  for some time. One is for scheduling an archive job without running it,
 :::  and the other is for running an archive job without scheduling it.
 :::
 :::  (Jun 2014) v5.5 -- The Task Scheduler history in Windows 2012 does not
 :::  appreciate the single quote character in the job name, so it has been
 :::  replaced by square brackets [].
 :::
 :::  (Feb 2015) v5.6 -- Modified the FINDSTR parameters used for validating
 :::  the existence of the scheduled job;  Removed the shortname adjustment
 :::  that was previously made for Windows Vista/2008 RTM (Nov 2012).
 :::
 :::  (Apr 2015) v5.8 -- Scheduled jobs on Windows 8/2012 which contain the []
 :::  characters, do not always execute. As a result, these have been removed
 :::  from the script.
 :::
 :::  (Apr 2015) v5.9 -- Updated :ShowStatus routine to track script duration.
 :::
 :::  (May 2015) v6.0 -- Added a job history file (*.RECORDING.TXT) to keep a
 :::  log of archival sessions.
 :::
 :::  (Nov 2015) v6.1 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Feb 2016) v6.2 -- Provided a parameter to calculate and use the default
 :::  log location.
 :::
 :::  (Jan 2018) v6.3 -- Changed the HELP routine to use FINDSTR;
 :::  Fixed a new issue with using FINDSTR /R /C in checking for scheduled jobs.
 :::
 :::  (Feb 2018) v6.4 -- Extended "NEVER PURGE" timeframe from 999 to 9999 days.
 :::
 :::  (May 2018) v7.0 -- Changed Script Documentation to www.BrainWaveCC.com;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Migrated :SaveJobHistory to a subroutine, for additional flexibility;
 :::  -- Added the ability to delete folders older than 90 days via @MAX_AGE;
 :::  -- Support for NeoLogger has been eliminated from this script;
 :::  -- Filtered Out SCHTASKS Error Messages;
 :::
 :::  (Jul 2018) v7.1 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v7.2 -- Removed AT command support;
 :::
 :::  (Oct 2018) v7.3 -- Corrected and expanded the DEBUG logging routine;
 :::  -- The start time of each compressed folder is now logged
 :::
 :::  (Nov 2018) v7.4 -- Established Retention Defaults that can be overridden
 :::  via the CustomVariables.*.TXT config files;
 :::
 :::  (Dec 2018) v7.5 -- Restrict @ARCHIVE to 100 characters, maximum;
 :::  -- Added the -O parameter to allow a one-time archive to be generated
 :::  without the "Zips" and "Archives" folders being created;
 :::
 :::  (Mar 2019) v7.6 -- Enabled Code Page 1252 Support;
 :::  -- Corrected a bug introduced by the -O parameter processing;
 :::  -- Record additional attributes in the Job History log;
 :::  -- Prevent DEBUG MODE data from being stored in the .RECORDING.TXT file;
 :::
 :::  (Oct 2019) v7.7 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v7.8 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Dec 2019) v7.9 -- Developed a drop-in replacement for Microsoft's
 :::  old NOW.EXE utility, taking back that function from DATEINFO.EXE;
 :::
 :::  (Jan 2020) v8.0 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Added a routine for validating integer parameters;
 :::  -- Refactored the :Prepare4Syslog routine;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::
 :::  (May 2020) v8.1 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::  -- Replaced FINDSTR with BrainWave ReadConfig.exe for reading config file;
 :::  -- Moved Custom Options and Parameter Processing to Subroutines, rather than
 :::  standard compound statements within parentheticals;
 :::  -- Allow @DELEMPTY from CLI to override config file;
 :::
 :::  (Nov 2020) v8.2 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Mar 2021) v8.3 -- Renamed @BYPASS prefix to @ rather than + due to a
 :::  recently discovered conflict with DFS-R and Group Policy;
 :::
 :::  (Jan 2022) v9.0 -- Check for additional obsolete scheduled job entries;
 :::  -- Modify the @NAMECHK verification to avoid deleting -Daily/-Weekly jobs;
 :::  -- Stop using ‹› as substitutions for () in job descriptions;
 :::
 :::  (Oct 2023) v9.1 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (Apr 2024) v9.2 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::  (May 2024) v9.3 -- Corrected the :CheckFolderAge routine calculations;
 :::
 :::  (Jul 2024) v9.4 -- Replaced the :RunCMD routine with just a CALL command;
 :::
 :::  (Sep 2024) v9.5 -- Enable updates to local syslogs if requested;
 :::  -- Refactoring of the scheduled jobs verification routine;
 :::  -- Created :LogCriticalFailure routine for early job failures;
 :::
 :::  (Sep 2025) v9.6 -- Replaced instances of FORFILES with FILEHASH --JF;
 :::  -- Replaced instances of HEAD/TAIL/TYPE with READABLE;
 :::
 ::: --------
 :::  NOTES:
 ::: --------
 :::  *	The ZIP parameters ARE case sensitive.
 :::  *	This script processes the main folder + subdirectories.
 :::  *	This script requires SETDRIVE.BAT for the global variables.
 :::
 :::
 :::  SCRIPTING SYNTAX RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  https://ss64.com/ .......... CMD and Powershell syntax
 :::  https://www.dostips.com/ ... Windows Shell Scripting Tips
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
 rem === Updated On: 26 Sep 2025 / 26 Sep 2024 / 28 Jul 2024 / 10 May 2024
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v9.6.0.1060

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT" FILEHASH.EXE READABLE.EXE
 SET #MSUTILS=CHOICE.EXE FINDSTR.EXE SCHTASKS.EXE
 SET #O_UTILS=PSFILE.EXE SYSLOGGEN.EXE ZIP.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES & GOTO :ExitBatch)

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @EXCLUDE=-x *.ZIP *.RAR *\zia* *Zips\* *ZipFiles\*
 SET @FILESPEC=LOG LOG+ LOG_+ LOG.+ +.LOG TXT TXT+ TXT_+ TXT.+ +.TXT INFO CSV BAK TRN PP2 EVT SAV TRC Old.+
 SET @BYPASS=@ZipLogsOverride.INPUT
 SET @DEFAULT_KEEP_S=100
 SET @DEFAULT_KEEP_H=550
 SET @DELEMPTY=FALSE

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Main Variables
 SET @DIRS_PRUNED=0
 SET @FILES_ARCHIVED=0
 SET @ARCHIVES_MOVED=0
 SET @ARCHIVES_PRUNED=0

 rem -- Get Folder Names
 IF /I "%~1"=="*DEFAULT*LOGS*" SET @TARGET=%@LOGBASE%
 SET @TARGET=%~1
 SET @TARGET_S=%~s1& CALL :FixParentheses @TARGET_S
 SET @TARGET_D=%~1&  CALL :AltParentheses @TARGET_D
 SET @TARGET=%@TARGET:"=%
 SET @DEST=%@TARGET_S%\ZipFiles

 rem -- Historical Archiving Variables (in Days)
 SET @GRAVEYARD="%@DEST%\Archives"
 SET @KS=%2& CALL :StripQuotes @KS
 SET @KH=%3& CALL :StripQuotes @KH
 CALL :GetInteger @KEEP_SHORT-TERM !@KS! %@DEFAULT_KEEP_S% 1 9999
 CALL :GetInteger @KEEP_HISTORICAL !@KH! %@DEFAULT_KEEP_H% 1 9999

 rem -- Determine Whether or Not to Delete Empty Folders During Processing (from CLI)
 IF /I "%~4"=="TRUE" SET @DELEMPTY=TRUE

 rem -- Job Scheduling Variables
 SET @JOBINFO=Log Archive of
 SET @JOBNAME=%@JOBINFO% %@TARGET%& CALL :SanitizeName @JOBNAME
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=MONTHLY
 SET @JOBTIME=00:15:00
 SET @JOBDATE=/D 1
 SET @JOBPATH="%~f0" \"%@TARGET%\" %@KEEP_SHORT-TERM% %@KEEP_HISTORICAL% %@DELEMPTY% & CALL :FixParentheses @JOBPATH
 SET @JOBVRFY=%@TARGET%
 SET @JOBTYPE=

 rem -- Obsolete/Former Job Scheduling Names
 SET @OLDJOB0=%@JOBINFO% %@NO_TARGET%
 SET @OLDJOB1=%@JOBINFO% '%@TARGET%'
 SET @OLDJOB2=%@JOBINFO% [%@TARGET%]
 SET @OLDJOB3=%@JOBINFO% {%@TARGET%}
 IF /I NOT "%~1"=="%~s1" (
	 SET @OLDJOB4=%@JOBINFO% %@TARGET_S%
	 SET @OLDJOB5=%@JOBINFO% '%@TARGET_S%'
	 SET @OLDJOB6=%@JOBINFO% [%@TARGET_S%]
	 SET @OLDJOB7=%@JOBINFO% {%@TARGET_S%}
 )
 CALL :SwapBrackets @OLDJOB8 @JOBNAME ‹ ›
 CALL :SwapBrackets @OLDJOB9 @JOBNAME [ ]
 FOR /L %%I IN (0,1,9) DO IF DEFINED @OLDJOB%%I CALL :SanitizeName @OLDJOB%%I

 rem -- Grab Appropriate Custom Variables from CustomVariables.*.TXT -- Use ReadConfig.exe
 FOR %%C IN ("%@CUSTOM-VARS%" "%@CUST-VARS-MINI%") DO IF EXIST "%%~C" (
	 FOR /F "TOKENS=*" %%P IN ('READCONFIG "%%~C" -F "%~n0" 2^>NUL') DO CALL %%P
 )
 IF /I "%~4"=="TRUE" SET @DELEMPTY=TRUE

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Archiving
 SET @LOGFILE=%@LOGPATH%\%@JOBNAME%.%@FILESTAMP%
 SET @TIMINGS=%@LOGPATH%\%@JOBNAME%.RECORDING.TXT

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 003 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 099 030 199
 CALL :GetInteger @MAX_AGE "%@MAX_FOLDER_AGE%" 090 010 400

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 SET @UPDATESCHED=FALSE
 CALL :GetParams "D @ DIAG" & IF DEFINED @OK (SET @NOSCHED=TRUE&     SET @KEEP_SHORT-TERM=0& SET @KEEP_HISTORICAL=9999)
 CALL :GetParams "S ."      & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE)
 CALL :GetParams "U -"      & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @UNSCHED=TRUE)
 CALL :GetParams "N $"      & IF DEFINED @OK (SET @UPDATESCHED=TRUE)

 CALL :GetParams "O #" @CUSTOM & IF DEFINED @OK CALL :SetCustomValues
 CALL :GetParams "T"  @MINROWS & IF DEFINED @OK (
	 SET @MAXROWS=1
	 CALL :GetInteger @MINROWS "%@MINROWS%" 1 1 10
 )

 rem -- Key Variable Verification
 FOR %%V IN (DEST BYPASS FILESPEC JOBTIME GRAVEYARD KEEP_SHORT-TERM KEEP_HISTORICAL DELEMPTY) DO IF NOT DEFINED @%%~V (
	 ECHO:
	 ECHO *** WARNING: The @%%~V variable is undefined.
	 ECHO:
	 ECHO  Please ensure that all configuration info is provided correctly
	 ECHO  within the file: "%@CUSTOM-VARS%"
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
 rem === Validate Source and Script Log Folders
 rem === Updated On: 07 Mar 2019 / 01 May 2015
 rem ==========================================================================
:CheckFolders
 IF /I "%@UNSCHED%"=="TRUE" GOTO :ScheduleJobs
 SET @NOTFOUND=
 IF EXIST "%@TARGET%" FOR %%F IN ("%@DEST%" "%@LOGPATH%") DO IF NOT EXIST %%F MD %%F >NUL
 FOR %%F IN ("%@TARGET%" "%@DEST%" "%@LOGPATH%") DO IF NOT EXIST %%F SET @NOTFOUND=%%F !@NOTFOUND!

 IF DEFINED @NOTFOUND (
	 ECHO *** SCRIPT ERROR: ONE OR MORE KEY FOLDERS NOT FOUND ***
	 ECHO:
	 ECHO COULD NOT CREATE OR ACCESS THE FOLLOWING:
	 FOR %%F IN (%@NOTFOUND%) DO ECHO  -- %%F
	 ECHO:
	 CALL :SaveJobHistory ABORTED - MISSING FOLDER
	 GOTO :HelpMessage
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Allow User To Abort Operation
 rem === Updated On: 10 May 2024 / 05 May 2015 / 21 Apr 2015
 rem ==========================================================================
:DblCheck
 ECHO === Prepare to Create %@JOBINFO% "%@TARGET%" and subfolders ===
 ECHO:
 ECHO  Main archives will be kept for %@KEEP_SHORT-TERM% days...
 ECHO  Historical archives will be kept for %@KEEP_HISTORICAL% days...
 ECHO:
 ECHO  Logfile: "%@LOGFILE%"
 ECHO:
 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 CHOICE /C YNQEX /T 20 /D Y /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :ExitBatch
 )
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

 rem -- Delete Obsolete Scheduled Tasks (Containing Single Quotes, Containing 8.3 Filenames, etc)
 FOR /L %%I IN (0,1,9) DO IF DEFINED @OLDJOB%%I FOR %%f IN (\ "%@TASKFOLDER%") DO (
	 FOR /F %%s IN ('SCHTASKS /DELETE /TN "%%~f!@OLDJOB%%I!" /F 2^>^&1 ^| FIND "SUCCESS: "') DO ECHO Obsolete Task Deleted...
 )
 ECHO:

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
 rem === Start at Root Log Folder and Process All Subfolders
 rem === Updated On: 30 Sep 2025 / 10 Mar 2021 / 10 Dec 2019
 rem ==========================================================================
:ProcessFolders
 NOW Processing '%@TARGET%' and subfolders for log files to Zip...\n >"%@LOGFILE%"
 ECHO Processing "%@TARGET%" and subfolders for log files to Zip...
 ECHO:
 FOR /R "%@TARGET%" %%V IN (.) DO (
	 SET @EXTENSIONS=%@FILESPEC%
	 IF EXIST "%%~V\%@BYPASS:@=+%" REN "%%~V\%@BYPASS:@=+%" "%@BYPASS%"
	 IF EXIST "%%~V\%@BYPASS%" FOR /F "EOL=; USEBACKQ TOKENS=*" %%B IN ("%%~V\%@BYPASS%") DO SET @EXTENSIONS=%%~B
	 FOR %%F IN (!@EXTENSIONS!) DO CALL :MakeArchive "%%~V" *.%%~F
 )

 rem -- Determine Total Number of Files That Were Archived
 FOR /F "TOKENS=1" %%A IN ('READABLE "%@LOGFILE%" -F " testing: " --TO -Q') DO SET @FILES_ARCHIVED=%%~A
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Move Zips Into GraveYard After %@KEEP_SHORT-TERM% Days (Default=100)
 rem === Updated On: 26 Sep 2025 / 07 Mar 2019 / 05 May 2015
 rem ==========================================================================
:MoveIntoGraveYard
 SET @FORFILES=FILEHASH --JF --OLDER %@KEEP_SHORT-TERM% -D "%@DEST%" *.ZIP *.7z

 ( rem -- Write to Log
	 IF NOT EXIST %@GRAVEYARD% MD %@GRAVEYARD%
	 ECHO:
	 ECHO:
	 ECHO Manage Primary Archives
	 ECHO  -- Move all archives older than %@KEEP_SHORT-TERM% days to the GraveYard --
	 FOR /F "TOKENS=*" %%V IN ('%@FORFILES% 2^>NUL') DO (
		 ECHO Moving "%%~V" into Archive Graveyard Folder
		 MOVE "%%~V" %@GRAVEYARD%
		 SET /A @ARCHIVES_MOVED+=1
	 )
 ) >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Delete All Zips Older Than %@KEEP_HISTORICAL% Days (Default=550)
 rem === Updated On: 26 Sep 2025 / 07 Mar 2019 / 05 May 2015
 rem ==========================================================================
:PruneArchive
 SET @FORFILES=FILEHASH --JF --OLDER %@KEEP_HISTORICAL% -D "%@GRAVEYARD%" *.ZIP *.7z

 ( rem -- Write to Log
	 ECHO:
	 ECHO:
	 ECHO Pruning Old Backups from Archive Folder
	 ECHO  -- Delete all archives older than %@KEEP_HISTORICAL% days old --
	 FOR /F "TOKENS=*" %%V IN ('%@FORFILES% 2^>NUL') DO (
		 ECHO Deleting "%%~V" from Archive Graveyard Folder
		 DEL "%%~V"
		 SET /A @ARCHIVES_PRUNED+=1
	 )
	 ECHO:
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Job Report
 rem === Updated On: 16 May 2018 / 05 May 2015
 rem ==========================================================================
:FinalReport
 CALL :SaveJobHistory

 ( rem -- Write to Log
	 CALL :ForwardToSyslog "6" FINISHED Creating %@JOBINFO% "%@TARGET_D%" in %@ELAPSED%
	 ECHO:
	 DIR /OGD /S "%@DEST%"
	 ECHO:
	 DIR /OGD "%@LOGPATH%"
	 ECHO:
	 ECHO %@DIVIDER~%
	 ECHO  Total Files Archived ...!@FA!
	 ECHO  Empty Folders Pruned .......!@DP!
	 ECHO  Old Archives Moved .........!@AM!
	 ECHO  Old Archives Pruned ........!@AP!
	 ECHO %@DIVIDER~%
 ) >>"%@LOGFILE%" 2>&1
 COPY "%@LOGFILE%" "!@LOGFILE:%@FILESTAMP%=TXT!" /V /Y
 IF /I "%@CONSOLE_SESSION%"=="TRUE" TYPE "%@LOGFILE%"
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
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 16 Oct 2023 / 01 Apr 2015
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Set Custom Values for Archival
 rem === Updated On: 25 Jul 2021 / 05 May 2020
 rem ==========================================================================
:SetCustomValues
 rem %* = No Parameters Needed

 SET @NOSCHED=TRUE
 SET @KEEP_SHORT-TERM=9999
 SET @KEEP_HISTORICAL=9999
 SET @DEST=%@TARGET_S%\ZipFiles
 SET @GRAVEYARD="!@DEST!"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Check Folder Age
 rem === Updated On: 27 May 2024 / 07 Mar 2019 / 16 May 2018
 rem ==========================================================================
:CheckFolderAge
 rem %1 = Folder to Check

 SET @FOLDER_DATE=%@TODAY%
 FOR %%z IN (FOLDER_AGE OLD_FOLDER REMOVE_DIR) DO SET @%%z=

 IF NOT EXIST "%~1" EXIT /B
 FOR /F %%d IN ('DIR /OG-D "%~1" ^| FIND " ."') DO SET @FOLDER_DATE=%%d
 FOR /F %%a IN ('DATEINFO -S -B "%@FOLDER_DATE%" -Q 2^>NUL') DO SET @FOLDER_AGE=%%a
 IF %@FOLDER_AGE% GTR %@MAX_AGE% SET @OLD_FOLDER=TRUE
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Create Zip Archive and Move All Log Files
 rem === Updated On: 07 Mar 2019 / 07 Dec 2018
 rem ==========================================================================
:MakeArchive
 rem %1 = Current Folder (Full Path Name)
 rem %2 = Current FileSpec

 CALL :GetTime @THISTIME
 SET @EMPTYDIR=TRUE
 SET @CURRENTDIR=%~f1
 SET @CURRENTSPEC=%~2
 SET @CURRENTSPEC=%@CURRENTSPEC:+=*%

 SET @LONGNAME=%@CURRENTDIR::\=_%& CALL :SanitizeName @LONGNAME
 SET @ARCHIVE=%@DEST%\%COMPUTERNAME%_%@LONGNAME%.%@LASTMONTH_EXP%.ZIP

 IF EXIST "%@CURRENTDIR%\%@CURRENTSPEC%" (
	 PUSHD "%@CURRENTDIR%"
	 ECHO !@THISTIME! -- Processing "%@CURRENTDIR%\%@CURRENTSPEC%" Files... >CON
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO !@THISTIME! -- Processing "%@CURRENTDIR%\%@CURRENTSPEC%" Files...
	 ECHO:
	 DIR "%@CURRENTSPEC%"
	 ECHO:
	 ZIP %@EXCLUDE% -m -9 -v -dgds 1m -T -tt %@BEGMONTH% "%@ARCHIVE%" %@CURRENTSPEC%
	 ECHO:
	 DIR
	 POPD
 ) >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%

 rem -- Delete Empty and Unattached Folders After Archiving Logs...
 IF NOT EXIST "%@CURRENTDIR%" EXIT /B
 IF /I "%@CURRENTDIR%"==%@GRAVEYARD% EXIT /B
 FOR /F %%E IN ('DIR /A /B "%@CURRENTDIR%" 2^>^&1') DO SET @EMPTYDIR=FALSE
 FOR /F "TOKENS=1*" %%A IN ('PSFILE %@PSPARAMS% 2^>NUL ^| FIND "]"') DO IF /I "%@CURRENTDIR%"=="%%~B" SET @EMPTYDIR=FALSE

 IF /I "%@EMPTYDIR%"=="TRUE" (
	 CALL :CheckFolderAge "%@CURRENTDIR%"
	 FOR %%E IN (DELEMPTY OLD_FOLDER) DO IF "!@%%~E!"=="TRUE" SET @REMOVE_DIR=TRUE

	 IF /I "!@REMOVE_DIR!"=="TRUE" (
		 SET /A @DIRS_PRUNED+=1
		 ECHO Deleting Empty Folder: "%@CURRENTDIR%"... >CON
		 ECHO:
		 ECHO Deleting Empty Folder: "%@CURRENTDIR%"...
		 RD /Q "%@CURRENTDIR%"
		 ECHO %@DIVIDER-%
		 ECHO:
		 ECHO:
	 )
 ) >>"%@LOGFILE%" 2>&1
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Put Escape Codes Around Parentheses
 rem === Updated On: 22 Jan 2022 / 05 May 2020
 rem ==========================================================================
:FixParentheses
:AltParentheses
 rem %1 = Name of Variable to CleanUp

 IF NOT DEFINED %1 EXIT /B

 SET %~1=!%~1:(=^^(!
 SET %~1=!%~1:)=^^)!

 IF /I "%~0"==":AltParentheses" (
	 SET %~1=!%~1:^(={!
	 SET %~1=!%~1:^)=}!
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Swap Brackets into Alternate Characters
 rem === Updated On: 22 Jan 2022
 rem ==========================================================================
:SwapBrackets
 rem %1 = Name of Destination Variable
 rem %2 = Name of Source Variable
 rem %3 = Replace { with this char
 rem %4 = Replace } with this char

 IF NOT DEFINED %2 EXIT /B
 IF "%~3"=="" EXIT /B
 IF "%~4"=="" EXIT /B

 SET %~1=!%~2:{=%~3!
 SET %~1=!%~1:}=%~4!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Generate Safe Job Schedule Name, Limited to 100 characters
 rem === Updated On: 22 Jan 2022 / 05 May 2020
 rem ==========================================================================
:SanitizeName
 rem %1 = Name of Variable to CleanUp
 rem %2 = Optional Parameter to Add Quotation Marks

 IF NOT DEFINED %1 EXIT /B
 IF NOT "!%~1!"=="!%~1:~0,100!" (
	 SET %~1=!%~1:~0,92!...!%~1:~-5!
 )

 SET %~1=!%~1:(={!
 SET %~1=!%~1:)=}!
 SET %~1=!%~1::\=_!
 SET %~1=!%~1:\=_!
 SET %~1=!%~1:"=!
 IF NOT "%~2"=="" SET %~1="!%~1!"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Strip Quotation Marks from a Value
 rem === Updated On: 16 Jan 2020
 rem ==========================================================================
:StripQuotes
 rem %1 = Name of Variable to CleanUp

 IF NOT DEFINED %1 SET %~1=""
 SET @VAL=!%~1!
 SET @VAL=!@VAL:"=!
 SET %~1="!@VAL!"
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
 rem === Updated On: 15 Mar 2021 / 21 Jan 2020
 rem ==========================================================================
:GetParams
 rem %1 = Parameters to Search For
 rem %2 = Variable to Set

 SET @OK=& IF "%~1"=="" EXIT /B
 FOR /F "TOKENS=2-3*" %%v IN ('CHECKPARAMS -q -a -c "%~1" -s %@ALL_PARAMS% 2^>NUL') DO IF /I "%%~v"=="TRUE" (
	 SET @OK=T
	 SET @REQ=T
	 IF NOT "%~2"=="" SET %~2=%%~x
	 IF "%%~w"=="" EXIT /B
	 SET @USED=%%~w
	 SET @USED=!@USED:[=!
	 SET @USED=!@USED:]=!
	 SET @SELECTED=!@SELECTED! !@USED!
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
 rem === Updated On: 30 Sep 2025 / 05 May 2020 / 27 Apr 2020 / 15 Oct 2019
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @FA "%@FILES_ARCHIVED%" "." 6
 CALL :PadLeft @DP "%@DIRS_PRUNED%" "." 2
 CALL :PadLeft @AM "%@ARCHIVES_MOVED%" "." 3
 CALL :PadLeft @AP "%@ARCHIVES_PRUNED%" "." 3

 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 SET @JOBHISTORY="%@TARGET%" // FILES ZIPPED.%@FA% // EMPTY DIRS PRUNED.%@DP% // ARCHIVES [MOVED.%@AM% PRUNED.%@AP%] // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %~n0 %@VERSION%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('READABLE "%@TIMINGS%" -F "/" --TO -Q') DO SET @ROWCOUNT=%%c
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
 rem === Updated On: 23 Jun 2024 / 14 Jan 2020 / 15 May 2018
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
 rem === Updated On: 30 Nov 2020 / 14 Jan 2020
 rem ==========================================================================
:HelpMessage
 ECHO Create MONTHLY ZIP archives of .TXT, .LOG and other text files
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<folder^> [days before archive] [days before graveyard purge]  [OPTIONS]
 ECHO  %~n0  ^<folder^> [OPTIONS]
 ECHO  %~n0  *DEFAULT*LOGS* [OPTIONS]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 IF DEFINED @KEEP_SHORT-TERM IF DEFINED @KEEP_HISTORICAL (
	 ECHO  * Number of days before zip files are archived .....: %@KEEP_SHORT-TERM%
	 ECHO  * Number of days before archived zips are purged ...: %@KEEP_HISTORICAL%
	 ECHO:
 )
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO  /S,  .   .... Schedule the Job, But Don't Execute It
 ECHO  /D,  @   .... Execute the Job without Scheduling It
 ECHO  /N,  $   .... Execute the Job, and Update the Schedule
 ECHO  /U,  -   .... Unschedule the Job Only, Without Executing It First
 ECHO  /O,  #   .... Provide a one-time archive
 ECHO                (like /D but without diagnostics or Zip/Archives folders)
 ECHO  /T       .... Truncate Job History Logfile {or /T:# where # is from 1-10}
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 C:\LOGS
	 ECHO  %~n0 D:\Backup 150
	 ECHO  %~n0 D:\TEST 200 900
	 ECHO  %~n0 "F:\SYSTEM LOGS" %@KEEP_SHORT-TERM% %@KEEP_HISTORICAL%
	 ECHO  %~n0 *DEFAULT*LOGS* 100 600 /S
	 ECHO  %~n0 %SystemDrive%\TheseLogs /D
	 ECHO  %~n0 "H:\Special Logs" /O
	 ECHO  %~n0 "J:\Special Docs\More" /T:5
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
 )
 CALL :ShowStatus "FINISHED"
                                                                        