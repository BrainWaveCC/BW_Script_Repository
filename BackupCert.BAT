@ECHO OFF
 rem ==========================================================================
 rem === Backup AD Certificate Server
 rem ==========================================================================
 rem
 rem Created On: 08 Mar 2021
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 14 Aug 2025 / 03 Sep 2024 / 28 Jul 2024 / 10 May 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
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

 :::  This script makes use of the CERTUTIL and REG.exe to backup an enterprise
 :::  Certificate Authority
 :::
 :::  This script will also delete all but 30 most recent backups that have been
 :::  created.  To adjust the default, change the @KEEP_HISTORICAL variable.
 :::
 :::  (Mar 2021) v1.0 -- Initial Release;
 :::
 :::  (Jan 2022) v1.1 -- Modify the @NAMECHK verification to include \ prefix;
 :::
 :::  (Oct 2023) v1.2 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v1.3 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::
 :::  WINDOWS SHELL SCRIPTING RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  https://ss64.com/ .......... CMD and Powershell syntax
 :::  https://www.dostips.com/ ... Windows Shell Scripting Tips
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 08 Mar 2021
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 10 May 2024 / 08 Mar 2021
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v1.3.0.071 c

 rem -- Backup Archives to Keep (# of weekly backups)
 SET @KEEP_HISTORICAL=10

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f "%~dp0SetDrive.BAT" FINDSTR.EXE SCHTASKS.EXE CERTUTIL.EXE REG.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Job Scheduling Variables
 SET @JOBNAME=Weekly AD CA Backup
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=WEEKLY
 SET @JOBTIME=03:55:00
 SET @JOBDATE=/D SAT
 SET @JOBPATH=%~f0
 SET @JOBTYPE=

 rem -- Cert Specific Info  (Override via CustomVariables.*.TXT)
 SET @CERT_NAME=%COMPUTERNAME%\MyCorp-Enterprise-CA

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"


 rem -- Main Variables
 SET @NOSCHED=TRUE
 SET @UPDATESCHED=FALSE
 SET @CA_REGKEY=HKLM\System\CurrentControlSet\Services\CertSVc\Configuration
 SET @ROOTDIR=%@BACKUPS%\CA
 SET @LOGPATH=%@STORAGE%\Logs\AD
 SET @LOGFILE=%@LOGPATH%\CA.%@FILESTAMP%

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
 rem === Updated On: 10 May 2024 / 22 Jan 2022 / 08 Mar 2021
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
 rem === Backup AD Cert Authority (CA)
 rem === Updated On: 08 Mar 2021
 rem ==========================================================================
:BackupCA
 IF NOT EXIST "%@LOGPATH%" MD "%@LOGPATH%"

 ECHO %@TIMESTAMP% - Begin AD CA Backups... [%@VER%] >>"%@LOGFILE%"
 ECHO Begin Backup of Certificate Authority Database... [%@VER%]

 ( rem -- Write to Log
	CERTUTIL -f -v -backupDB %@ROOTDIR%\%@DIRSTAMP_R%
	CERTUTIL -f -v -config %@CERT_NAME% -backupKey %@ROOTDIR%\%@DIRSTAMP_R%
	REG SAVE  "%@CA_REGKEY%" %@ROOTDIR%\%@DIRSTAMP_R%\CurrentRegistry.Backup
	REG QUERY "%@CA_REGKEY%" /S
 ) >>"%@LOGFILE%"

 ECHO Finished Backup of AD CA!
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Keep Only The Last %@KEEP_HISTORICAL% CA Backups (Default=30)
 rem === Updated On: 08 Mar 2021
 rem ==========================================================================
:PruneOldBackups
 ( rem -- Write to Log
	 ECHO:
	 ECHO:
	 ECHO Archiving Old CA Backups [Keep only the last %@KEEP_HISTORICAL% copies]

	 FOR /F "SKIP=%@KEEP_HISTORICAL% TOKENS=*" %%V IN ('DIR "%@ROOTDIR%" /AD /O-N /B') DO (
		 ECHO  - Deleting Obsolete CA Backup Folder: "%%V"
		 RD /S /Q "%@ROOTDIR%\%%V"
	 )
	 ECHO:
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Job Report
 rem === Updated On: 08 Mar 2021
 rem ==========================================================================
:FinalReport
 IF EXIST "%@LOGFILE%" TYPE "%@LOGFILE%"
 DIR /OGD "%@LOGPATH%"
 DIR /OGD /S "%@ROOTDIR%"


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 08 Mar 2021
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Determine if Parameter is a Valid Integer, Or Set to Zero
 rem === Updated On: 08 Mar 2021
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
 rem === Updated On: 08 Mar 2021
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
 rem === Updated On: 03 Sep 2024 / 08 Mar 2021
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
 rem === Updated On: 22 Sep 2025 / 16 Oct 2023 / 08 Mar 2021
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
 rem === Updated On: 08 Mar 2021
 rem ==========================================================================
:HelpMessage
 ECHO Backup AD Certificate Server
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
                                                                                               