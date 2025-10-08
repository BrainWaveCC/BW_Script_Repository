@ECHO OFF
 rem ==========================================================================
 rem === Backup All local DCHP Scopes
 rem ==========================================================================
 rem
 rem Created On: 01 Jan 2007
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 14 Aug 2025 / 03 Sep 2024 / 28 Jul 2024 / 10 May 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows Server 2003 or later
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script calls the NETSH command to backup local DHCP Scope information
 :::  and stores it in the x:\Storage\Backups\DHCP folder where X: is determined
 :::  by the SetDrive.BAT script.
 :::
 :::  This script will also delete all but 30 most recent backups that have been
 :::  created.  To adjust the default, change the @KEEP_HISTORICAL variable.
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
 :::  (Oct 2013) v1.10 -- It is now possible to provide additional script
 :::  settings via the CustomVariables.TXT input file.  This can be a useful
 :::  way of changing the default user account for the schedule job, as an
 :::  example.  These settings are processed after every internal setting, but
 :::  before the commandline parameters are evaluated.
 :::
 :::  (Nov 2017) v2.0 -- Reduced the default retension period from 30 to 10,
 :::  and added validation to ensure that it is always a legitmate value if
 :::  set via the CustomVariables.TXT input file.
 :::
 :::  (May 2018) v3.0 -- Changed the HELP routine to use FINDSTR;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Filtered Out SCHTASKS Error Messages;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com;
 :::
 :::  (Jul 2018) v3.1 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v3.2 -- Removed AT command support;
 :::
 :::  (Oct 2018) v3.3 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Mar 2019) v3.4 -- Enabled Code Page 1252 Support;
 :::
 :::  (Oct 2019) v3.5 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Jan 2020) v3.6 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Added a routine for validating integer parameters;
 :::
 :::  (May 2020) v3.7 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Nov 2020) v3.8 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Jan 2022) v3.9 -- Modify the @NAMECHK verification to include \ prefix;
 :::
 :::  (Oct 2023) v3.10 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v4.0 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 ::: --------
 :::  NOTES:
 ::: --------
 :::  * (January 2005): There is a weird bug in Windows 2003 SP1 x64 where
 :::    the existence of a 'D' in the beginning of a task name is interpreted
 :::    as a special character by SCHTASKS.EXE and will generate an error
 :::    during creation of the job. Lowercase 'd' works just fine, though. I
 :::    haven't tested to see if the same problem shows up in 64-bit XP, but
 :::    I suspect that it will as they use the same codebase.
 :::
 :::
 :::  WINDOWS SHELL SCRIPTING RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  https://ss64.com/ .......... CMD and Powershell syntax
 :::  https://www.dostips.com/ ... Windows Shell Scripting Tips
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 30 Nov 2020 / 16 May 2018
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 10 May 2024 / 30 Nov 2020 / 26 May 2020
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v4.0.0.401 c

 rem -- Backup Archives to Keep (# of weekly backups)
 SET @KEEP_HISTORICAL=10

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f "%~dp0SetDrive.BAT" FINDSTR.EXE NETSH.EXE SCHTASKS.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Job Scheduling Variables
 SET @JOBNAME=Weekly dHCP Scope Backup
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=WEEKLY
 SET @JOBTIME=04:00:00
 SET @JOBDATE=/D SAT
 SET @JOBPATH=%~f0
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"


 rem -- Main Variables
 SET @UPDATESCHED=FALSE
 SET @DATAPATH=%@STORAGE%\Backups\DHCP
 SET @DATAFILE=%@DATAPATH%\%@TODAY_EXP%.%@NOW%.BAK
 SET @LOGPATH=%@STORAGE%\Logs\AD
 SET @LOGFILE=%@LOGPATH%\DHCP.%@FILESTAMP%

 rem -- Ensure Valid Retention Time
 CALL :GetInteger @KEEP_HISTORICAL "%@KEEP_HISTORICAL%" 10

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "D @" & IF DEFINED @OK (SET @NOSCHED=TRUE& SET @KEEP_HISTORICAL=9999)
 CALL :GetParams "S ." & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE)
 CALL :GetParams "U -" & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @UNSCHED=TRUE)
 CALL :GetParams "N $" & IF DEFINED @OK (SET @UPDATESCHED=TRUE)
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 10 May 2024 / 22 Jan 2022 / 09 Mar 2019
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

 rem -- Check for Schedule Update Parameters
 IF /I "%@UPDATESCHED%"=="TRUE" (!@SET_SCHED!) ELSE (CALL :CheckSched "%~f0")
 ECHO %@MINORDIV%
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
 rem === Backup local DHCP Scope Data
 rem === Updated On: 20 Dec 2011 / 01 Jan 2007
 rem ==========================================================================
:BackupDHCP
 FOR %%F IN ("%@LOGPATH%" "%@DATAPATH%") DO IF NOT EXIST "%%~F" MD "%%~F"

 IF EXIST "%SystemRoot%\System32\DHCP" (
	 ECHO %@TIMESTAMP% - Begin DHCP Backup... [%@VER%] >>"%@LOGFILE%"
	 ECHO Begin DHCP Backup... [%@VER%]
	 NETSH DHCP server export "%@DATAFILE%" all >>"%@LOGFILE%"
	 ECHO Finished DCHP Backup!
 ) ELSE (
	 ECHO No DHCP Folder found for Backups... >>"%@LOGFILE%"
	 ECHO:
	 DIR "%SystemRoot%\System32\DCHP"
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Keep Only The Last %@KEEP_HISTORICAL% DHCP Backups (Default=30)
 rem === Updated On: 05 Feb 2015 / 20 Dec 2011
 rem ==========================================================================
:PruneOldBackups
 ( rem -- Write to Log
	 ECHO:
	 ECHO:
	 ECHO Archiving Old DHCP Backups [Keep only the last %@KEEP_HISTORICAL% copies]
	 FOR /F "SKIP=%@KEEP_HISTORICAL% TOKENS=*" %%V IN ('DIR "%@DATAPATH%" /A-D /O-N /B') DO (
		 ECHO  - Deleting "%%V" from DHCP Backup Folder
		 DEL "%@DATAPATH%\%%~V"
	 )
	 ECHO:
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Job Report
 rem === Updated On: 25 Feb 2015
 rem ==========================================================================
:FinalReport
 TYPE "%@LOGFILE%" & DIR "%@LOGFILE%" & DIR "%@DATAFILE%"


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 04 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
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
 rem === SUBROUTINE: Update Job Execution Stats (Placeholder)
 rem === Updated On: 10 May 2024
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 rem -- Temp Placeholder
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Check if Scheduled Job is Already Running
 rem === Updated On: 03 Sep 2024 / 16 May 2018 / 05 Feb 2015
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
 IF /I "%~1"=="STARTED" FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET @SCRIPT_BEG#="%%~d"
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
 rem === Updated On: 30 Nov 2020 / 16 May 2018
 rem ==========================================================================
:HelpMessage
 ECHO Backup All local DCHP Scopes
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [OPTIONS]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 IF DEFINED @KEEP_HISTORICAL (
	 ECHO  * Number of archived backups that are maintained ...: %@KEEP_HISTORICAL%
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
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 /S
	 ECHO  %~n0 /D
	 ECHO  %~n0 -N
	 ECHO  %~n0 -?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO  * Options are case-insensitive, and can be prefaced by "-" or "/".
 )
 CALL :ShowStatus "FINISHED"
                                                                                                