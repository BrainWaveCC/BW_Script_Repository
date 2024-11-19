@ECHO OFF
 rem ==========================================================================
 rem === Backup AD Group Policy Info using the GPMC command line console
 rem ==========================================================================
 rem
 rem Created On: 25 Mar 2005
 rem         By: Saulo Nunez
 rem
 rem Updated On: 03 Sep 2024 / 28 Jul 2024 / 10 May 2024 / 16 Oct 2023
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2003 and later (Originally on Windows 2000+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    GPMGMT.DLL ............. http://www.microsoft.com/technet/prodtechnol/windowsserver2003/technologies/management/gpmcscr.mspx
 rem    BackupAllGPOs.wsf ...... http://www.microsoft.com/technet/prodtechnol/windowsserver2003/technologies/management/gpmcscr.mspx
 rem    Lib_CommonGPMCFunctions. http://www.microsoft.com/technet/prodtechnol/windowsserver2003/technologies/management/gpmcscr.mspx
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script makes use of the GPMGMT.DLL file from the Group Policy
 :::  Management Console (GPMC) to script the backup of your GPOs in the domain
 :::  to specific folders under the Backups tree (\Storage\Backups\GPOs)
 :::
 :::  The GPMC files are found in (\Program Files\GPMC) by default once you
 :::  install the GPMC.
 :::
 :::  This script will also delete all but 30 most recent backups that have been
 :::  created.  To adjust the default, change the @KEEP_HISTORICAL variable.
 :::
 :::  (Nov 2010) Changed the default log extension of the reports from .LOG to
 :::  .TXT so that the reports that are mailed to mobile devices can be read
 :::  automatically. (Not too many devices can natively handle .LOG files)
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
 :::  ADDITIONAL SCRIPTING TOOLS/INFO:
 :::  -------------------------------------------------------------------------
 :::  https://www.BrainWaveCC.com/knowledge-base/scripting-and-automation-options-for-windows/
 :::  https://www.BrainWaveCC.com/knowledge-base/must-have-utilities-for-windows-usersadmins/
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 30 Nov 2020 / 16 May 2018
 rem ==========================================================================
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 10 May 2024 / 30 Nov 2020 / 26 May 2020
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v4.0.0.401

 rem -- Backup Archives to Keep (# of weekly backups)
 SET @KEEP_HISTORICAL=10

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT"
 SET #MSUTILS=FINDSTR.EXE SCHTASKS.EXE CSCRIPT.EXE %~dp0BackupAllGPOs.wsf
 SET #O_UTILS=
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :SaveJobHistory ABORTED - MISSING CRITICAL FILES& GOTO :ExitBatch)

 rem -- Job Scheduling Variables
 SET @JOBNAME=Weekly GPO Backup
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=WEEKLY
 SET @JOBTIME=04:15:00
 SET @JOBDATE=/D SUN
 SET @JOBPATH=%~f0
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Main Variables
 SET @UPDATESCHED=FALSE
 SET @DOMAINS=%*& IF "%~1"=="" SET @DOMAINS=%USERDNSDOMAIN%
 SET @ROOTDIR=%@STORAGE%\Backups\GPOs
 SET @LOGPATH=%@STORAGE%\Logs\AD
 SET @LOGFILE=%@LOGPATH%\GPO.%@FILESTAMP%

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
 rem === Backup All GPOs for Local DNS Domain(s)
 rem === Updated On: 05 Feb 2015 / 20 Dec 2011
 rem ==========================================================================
:BackupGPOs
 PUSHD "%SystemDrive%\Scripts\Utils"
 IF NOT EXIST "%@LOGPATH%" MD "%@LOGPATH%"

 ECHO %@TIMESTAMP% - Begin GPO Backups... [%@VER%] >>"%@LOGFILE%"
 ECHO Begin Backup of All GPOs... [%@VER%]

 FOR %%D IN (%@DOMAINS%) DO (
	 SET @DATADIR=%@ROOTDIR%\%%~D\%@TODAY_EXP%.%@NOW%
	 SET @LOGFILE=%@LOGPATH%\GPO-%%D.%@FILESTAMP%

	 IF NOT EXIST "!@DATADIR!" MD "!@DATADIR!"
	 CSCRIPT %~dp0BackupAllGPOs.wsf !@DATADIR! /Comment:"Weekly GPO Backup" /Domain:%%~D >>"!@LOGFILE!"

	 ( rem -- Write to Log
		 ECHO:
		 ECHO:
		 ECHO Archiving Old GPO Backups [Keep only the last %@KEEP_HISTORICAL% copies]

		 FOR /F "SKIP=%@KEEP_HISTORICAL% TOKENS=*" %%V IN ('DIR "%@ROOTDIR%\%%~D" /AD /O-N /B') DO (
			 ECHO  - Deleting "%%V" from GPO Backup Folder "%%~D"
			 RD /S /Q "%@ROOTDIR%\%%~D\%%V"
		 )
		 ECHO:
	 ) >>"%@LOGFILE%"
 )

 ECHO Finished Backup of All GPOs!
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Job Report
 rem === Updated On: 25 Feb 2015
 rem ==========================================================================
:FinalReport
 POPD
 FOR %%D IN (%@DOMAINS%) DO TYPE "%@LOGPATH%\GPO-%%~D.%@FILESTAMP%"
 DIR "%@LOGPATH%"


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
 rem === SUBROUTINE: Update Job Execution Stats (Placeholder)
 rem === Updated On: 10 May 2024
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 rem -- Temp Placeholder
 %@PAUSE_IF_DEBUG%
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
 IF /I "%~1"=="STARTED" FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET "@SCRIPT_BEG#="%%~d""
 IF /I "%~1"=="FINISHED" (
	 IF DEFINED $CODEPAGE FOR /F "TOKENS=1* DELIMS=:" %%B IN ('CHCP %$CODEPAGE%') DO SET "@CHCP_STATUS= {Restoring Code Page:%%C}"
	 IF DEFINED @END_DEBUG_MODE %@END_DEBUG_MODE:"=%
	 TITLE Command Prompt [%USERDOMAIN%\%USERNAME%]   !@DEBUG_MODE!
	 DATEINFO -t %@SCRIPT_BEG#% -e "hr:min:sec.ms" -o "\n*** DURATION: " 2>NUL
 )
 NOW \n*** %@SCRIPTSTATUS%: %@VER% [\v] *** %@CHCP_STATUS%\n!@CRLF-%~1!
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Display Syntax Help if Required/Requested
 rem === Updated On: 30 Nov 2020 / 16 May 2018
 rem ==========================================================================
:HelpMessage
 ECHO Backup AD Group Policy Info using the GPMC command line console
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [OPTIONS]
 ECHO  %~n0  [-h^|-?^|-h2^|-??]
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
 ECHO  /S,  .  ..... Schedule the Job, But Don't Execute It
 ECHO  /D,  @  ..... Execute the Job without Scheduling It
 ECHO  /N,  $  ..... Execute the Job, and Update the Schedule
 ECHO  /U,  -  ..... Unschedule the Job Only, Without Executing It First
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
                             