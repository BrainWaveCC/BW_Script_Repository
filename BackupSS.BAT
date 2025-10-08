@ECHO OFF
 rem ==========================================================================
 rem === Create SystemState Backups for Windows 2000 or XP or 2003 Systems
 rem ==========================================================================
 rem
 rem Created On: 06 Mar 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 14 Aug 2025 / 10 May 2024 / 16 Oct 2023 / 30 Nov 2020
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

 :::  This script creates a SystemState backup on a Win2K or XP system using
 :::  the native NTBACKUP utility.  You can control the location of the backup
 :::  file by changing the environment variable or adding a command-line
 :::  parameter of the desired location.  If run on an Exchange 2000 or 2003
 :::  server, this script will automatically create an appropriate backup set
 :::  configuration file, with the parameter for backing up the Mail Store.
 :::
 :::  This backup simply appends to the previous file.
 :::
 :::  Remember to use quotes to surround long file/folder names.
 :::
 :::  The script now supports the use of marker files to prevent the creation
 :::  of either entire SystemState backup, or of the Exchange portion for
 :::  servers also running Exchange.  Placing the followng files in the
 :::  C:\Scripts\Bat\Input folder will alter the backup processing as follows:
 :::
 :::  	- NoExchangeData.DAT: Create only a SystemState backup; No Exchange
 :::  	- NoSystemState.DAT:  Don't create any backups at all.
 :::
 :::  (May 2018) v3.0 -- Changed the HELP routine to use FINDSTR;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Filtered Out SCHTASKS Error Messages;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com;
 :::
 :::  (Jul 2018) v3.1 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Oct 2018) v3.2 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Oct 2019) v3.3 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (May 2020) v3.4 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Nov 2020) v3.5 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Oct 2023) v3.6 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v4.0 -- Check for essential utilities with FINDFILES;
 :::
 :::
 :::  SCRIPTING SYNTAX RESOURCES:
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
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v4.0.0.400 c

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f "%~dp0SetDrive.BAT" %SystemRoot%\System32\ntbackup.exe
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"
 SET @FILESTAMP=%@TODAY%-%@NOW%.BKF

 rem -- Main Variables
 SET @NOBACKUP=%~dp0Input\NoSystemState.DAT
 SET @NOEXCHANGE=%~dp0Input\NoExchangeData.DAT
 SET @LOGPATH=%USERPROFILE%\Local Settings\Application Data\Microsoft\Windows NT\NTBackup\Data
 SET @BKUPSET=%@LOGPATH%\SystemState-Plus.bks
 SET @BACKUPEXE=%SystemRoot%\System32\ntbackup.exe
 SET @BACKUPFILE=%~1& IF "%~1"=="" SET @BACKUPFILE=%@STORAGE%\Backups\SystemState.%@FILESTAMP%
 SET @LONGNAME="Daily SystemState Backup"
 SET @SHORTNAME="Daily"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Create Backup Set Config File (in Unicode) If It Doesn't Already Exist
 rem === Updated On: 20 Dec 2011 / 09 Jan 2007
 rem ==========================================================================
:NewBackupSet
 IF NOT EXIST "%@NOBACKUP%" ( rem -- Drop This Marker File To Prevent Creation of Backup Set
	 IF NOT EXIST "%@BKUPSET%" (
		 ECHO Creating Backup Configuration File...
		 IF NOT EXIST "%@NOEXCHANGE%" ( rem -- Drop This Marker File To Prevent Creation of Exchange Backup Set
		 	 ECHO Adding Exchange Backup Info to the Configuration File...
			 IF DEFINED EXCHICONS CMD /U /C ECHO JET %COMPUTERNAME%\Microsoft Information Store\First Storage Group\ >>"%@BKUPSET%"
		 )
		 CMD /U /C ECHO SystemState >>"%@BKUPSET%"
	 )
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Initiate Backup Based on Backup Set or Generic SystemState Backup
 rem === Updated On: 20 Dec 2011 / 08 Mar 2006
 rem ==========================================================================
:CreateBackup
 IF NOT EXIST "%@BACKUPFILE%\.." MD "%@BACKUPFILE%\.."

 ECHO Creating SystemState Backup for %COMPUTERNAME%...
 ECHO:
 ECHO Please wait (up to 5 minutes)...
 ATTRIB -A "%@LOGPATH%\*.LOG"
 %@BACKUPEXE% backup SystemState /a /d %@LONGNAME% /v:yes /r:no /rs:no /hc:off /m normal /j %@SHORTNAME% /l:s /f "%@BACKUPFILE%"

 rem -- Backup SystemState ONLY, or SystemState plus whatever is in the BackupSet file
 IF NOT EXIST "%@BKUPSET%" (
	 %@BACKUPEXE% backup SystemState /a /d %@LONGNAME% /v:yes /r:no /rs:no /hc:off /m normal /j %@SHORTNAME% /l:s /f "%@BACKUPFILE%"
 ) ELSE (
	 %@BACKUPEXE% backup "@%@BKUPSET%" /a /d %@LONGNAME% /v:yes /r:no /rs:no /hc:off /m normal /j %@SHORTNAME% /l:s /f "%@BACKUPFILE%"
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Final Job Report
 rem === Updated On: 25 Feb 2015
 rem ==========================================================================
:FinalReport
 DIR "%@BACKUPFILE%\..\*.BKF" /OD /A-D
 FOR /F %%V IN ('DIR "%@LOGPATH%\*.LOG" /AA /B') DO TYPE "%@LOGPATH%\%%V"


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 04 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
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
 ECHO Create SystemState Backups for Windows 2000 or XP or 2003 Systems...
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [destination_file]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 C:\Backups\MyBackup.bkf
	 ECHO  %~n0 "C:\My Backups\MyBackup.bkf"
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
                                    