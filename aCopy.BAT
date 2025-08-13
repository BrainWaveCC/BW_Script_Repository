@ECHO OFF
 rem ==========================================================================
 rem === Copy Files and Folders using XCOPY (with logging and time stamping)
 rem ==========================================================================
 rem
 rem Created On: 06 Oct 2002
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 02 Jun 2025 / 10 May 2024 / 02 May 2024 / 04 Apr 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: 2000 or later (or NT4 + Resource Kit)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script uses XCOPY, which is a native Windows utility, to copy files
 :::  and folders from one point to another. To minimize defragmentation, it
 :::  initially uses the /T parameter of XCOPY to create all the necessary
 :::  destination directories at one time, then copies the files over
 :::  afterwards, which eliminates the need to remember what parameters to call
 :::  in order to get all files copied over (including hidden and system files).
 :::
 :::  This script also makes use of several TIME subroutines to capture and
 :::  display the starting and ending times of the XCOPY job.
 :::
 :::  (Dec 2014) v3.0 -- Changed the manner in which pattern matching is
 :::  implemented, making use of a /P: parameter.  See HELP for details.
 :::
 :::  (Mar 2015) v3.2 -- Track elapsed time of xcopy jobs using a new version
 :::  of DATEINFO
 :::
 :::  (Apr 2015) v3.4 -- Streamline log output information
 :::
 :::  (Sep 2015) v3.5 -- Added new randomized function using DateInfo.exe to
 :::  generate a unique logfile name for each running instance of aCopy.BAT.
 :::
 :::  (Dec 2015) v3.6 -- Ensure that XCOPY parameters are deduplicated.
 :::
 :::  (Feb 2017) v3.7 -- Clean up PREFIX/SUFFIX evaluation subroutine to
 :::  eliminate script abort condition.
 :::
 :::  (Feb 2018) v3.8 -- Added Filtered CMD TITLE Routine
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Apr 2018) v3.9 -- The SYNTAX HELP routine has been updated
 :::
 :::  (Jul 2018) v3.10 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Oct 2018) v3.11 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Feb 2019) v3.12 -- Removed duplicate variables provided by SetDrive.BAT;
 :::
 :::  (Oct 2019) v3.13 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (May 2020) v3.14 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Nov 2020) v3.15 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Oct 2021) v4.0 -- Remove /D whenever a /D:xx-xx-xxxx is found;
 :::
 :::  (Oct 2023) v4.1 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (Apr 2024) v4.2 -- Check for essential utilities with FINDFILES;
 :::
 :::  (Jun 2025) v4.3 -- Remove any quotes from XCOPY parameters;
 :::
 :::
 :::  SCRIPTING SYNTAX RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  https://ss64.com/ .......... CMD and Powershell syntax
 :::  https://www.dostips.com/ ... Windows Shell Scripting Tips
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
 rem === Updated On: 10 May 2024 / 02 May 2024 / 04 Apr 2024 / 02 Apr 2024
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v4.3.0.1230 b

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=2 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f "%~dp0SetDrive.BAT" XCOPY.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Default Script Variables
 SET @DEFAULT=/S /E /R /C /I /D /F /H /K /Y
 SET @BYTES=0
 SET @TOTAL=0 Files
 SET @SOURCE=%~1
 SET @DEST=%~2
 SET @PARAMS=%*& FOR /L %%C IN (1,1,256) DO SET @PARAMS=!@PARAMS:  = !
 SET @PARAMS=!@PARAMS:%1 %2=!
 SET @PATTERN=& FOR %%P IN (%*) DO CALL :GetParams %%P
 FOR %%V IN (SOURCE DEST) DO CALL :FixDirectoryPath @%%V
 FOR /F %%P IN ('ECHO %@PARAMS% 2^>NUL ^| FIND /I "/D:"') DO SET @DEFAULT=!@DEFAULT:/D=!

 rem -- Get XCOPY Parameters
 CALL :EnsureUnique %@DEFAULT% %@PARAMS%
 IF DEFINED @UNIQUE SET @UNIQUE=%@UNIQUE:"=%
 SET @COPYJOB=XCOPY "%@SOURCE%%@PATTERN%" "%@DEST%" %@UNIQUE%

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Replication
 SET @LOGFILE=%@LOGPATH%\%~n0.%@FILESTAMP_R%


 rem ==========================================================================
 rem === Validate the Existence of the Log Folder
 rem === Updated On: 30 Apr 2015
 rem ==========================================================================
:ValidateLogFolder
 IF NOT EXIST "%@LOGPATH%" MD "%@LOGPATH%"
 IF NOT EXIST "%@LOGPATH%" (
	 ECHO *** Could Not Create Storage Folder ***
	 ECHO  -- "%@LOGPATH%"
	 GOTO :ExitBatch
 )


 rem ==========================================================================
 rem === Create Folders and Copy Files To Destination
 rem === Updated On: 02 Jun 2025 / 06 Jan 2022 / 29 Dec 2015 / 30 Apr 2015
 rem ==========================================================================
:CopyFiles
 ECHO %@DIVIDER~%
 ECHO  Source......... %@SOURCE%
 ECHO:
 ECHO  Destination.... %@DEST%
 IF DEFINED @PATTERN (ECHO:& ECHO  File Filter.... %@PATTERN%)
 IF DEFINED @PARAMS  (ECHO:& ECHO  XCOPY Options..%@PARAMS%)
 ECHO:
 ECHO  Logfile........ %@LOGFILE%
 ECHO %@DIVIDER~%
 ECHO:

 ( rem -- Check for Source Folder
	 FOR %%S IN ("%@SOURCE%\") DO IF NOT EXIST "%%~dpS" (
		 ECHO *** COULD NOT FIND: "%%~S" *** >CON
		 ECHO *** COULD NOT FIND: "%%~S" ***
		 GOTO :ExitBatch
	 )
 ) >>%@LOGFILE% 2>&1

 CALL :GetTime @STIME
 ( rem -- Write to Log
	 ECHO %@STIME% -- Starting Folder Enumeration...>CON
	 ECHO %@STIME% -- Starting Folder Enumeration...
	 IF NOT "%~0"=="aCopy.BAT" %@COPYJOB:/T=% /T >NUL 2>&1
 ) >>%@LOGFILE% 2>&1

 CALL :GetTime @CTIME
 ( rem -- Write to Log
	 ECHO %@CTIME% -- Starting File Copy...>CON
	 ECHO %@CTIME% -- Starting File Copy...
	 ECHO *** FILES COPIED ***
	 FOR /F "TOKENS=*" %%C IN ('%@COPYJOB%') DO (
		 ECHO %%C
		 SET @TOTAL=%%C
	 )
 ) >>%@LOGFILE% 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Summary Info for File Replication Job
 rem === Updated On: 30 Apr 2015 / 28 Apr 2015
 rem ==========================================================================
:FinishLog
 CALL :GetTime @ETIME
 FOR /F "TOKENS=3" %%B IN ('DIR "%@SOURCE%" /S /W 2^>^&1 ^| FIND "File(s)"') DO SET @BYTES=%%B

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO  [%@VER%] *** FILE COPY STATISTICS: %@TOTAL:(s)=s% ***
	 ECHO %@DIVIDER-%
	 ECHO  S: "%@SOURCE:~-70%"
	 ECHO  D: "%@DEST:~-70%"
	 IF DEFINED @PATTERN ECHO  *: %@PATTERN%
	 ECHO  O: %@DEFAULT%%@PARAMS%
	 ECHO  #: %@BYTES% Bytes
	 ECHO %@DIVIDER-%
	 ECHO  Copy Started On ............................. %@STIME%
	 ECHO  Copy Ended On ............................... %@ETIME%
	 DATEINFO -t !@CTIME#! -n !@ETIME#! -e "dys hrs mins secs.ms" -o " Copy Duration Was ........................... " 2>NUL
	 DATEINFO -t !@STIME#! -n !@ETIME#! -e "dys hrs mins secs.ms" -o " Total Job Duration Was ...................... " 2>NUL
	 ECHO %@DIVIDER-%
 ) >>%@LOGFILE% 2>&1


 rem ==========================================================================
 rem === Generate Final Job Report
 rem === Updated On: 30 Apr 2015 / 22 Apr 2015
 rem ==========================================================================
:FinalReport
 IF EXIST %@LOGFILE% (
	 ECHO:
	 TYPE %@LOGFILE% | FIND /V " -- Starting F"
	 DIR %@LOGFILE% | FIND /V " Volume "
 )


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
 rem === Updated On: 16 Oct 2023 / 23 Mar 2015
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Remove Trailing \ From Supplied Folder Path
 rem === Updated On: 07 Jan 2022 / 21 Dec 2014
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
 rem === SUBROUTINE: Get parameters and Set Appropriate Variables
 rem === Updated On: 23 Jun 2024 / 27 Feb 2017 / 24 Apr 2016
 rem ==========================================================================
:GetParams
 rem %1 = Parameter to Evaluate

 SET @PREFIX=%~1
 IF NOT DEFINED @PREFIX GOTO :EOF
 SET @PREFIX=!@PREFIX:"=!
 SET @SUFFIX=%@PREFIX:~3%& IF DEFINED @SUFFIX SET @SUFFIX=!@SUFFIX:"=!
 SET @PREFIX=%@PREFIX:~0,3%
 FOR %%d IN (/p -p) DO IF /I "%@PREFIX%"=="%%d:" IF DEFINED @SUFFIX (
	 SET @PATTERN=\!@SUFFIX!
	 SET @PARAMS=!@PARAMS: %1=!
 )
 IF DEFINED @PATTERN SET @PATTERN=!@PATTERN:+=*!
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === Ensure Unique Parameters in a Command String
 rem === Updated On: 13 Mar 2017 / 29 Dec 2015
 rem ==========================================================================
:EnsureUnique
 rem %* = Command-line to Evaluate

 IF "%~1"=="" GOTO :EOF
 SET @UNIQUE=
 FOR %%P IN (%*) DO IF NOT DEFINED $%%P (
	 SET $%%P=YES
	 SET @UNIQUE=!@UNIQUE! %%P
 )

 rem -- CleanUp Temp Variables
 FOR %%P IN (%*) DO SET $%%P=
 %@PRINT_IF_DEBUG%
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
 rem === Updated On: 30 Nov 2020 / 24 Apr 2018
 rem ==========================================================================
:HelpMessage
 ECHO Copy Files and Folders using XCOPY (with logging and time stamping)...
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<source_path^> ^<destination_path^> [/p:Pattern_Matches] [any_XCOPY_parameters]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 C:\Scripts E:\Scripts.Old
	 ECHO  %~n0 C:\Scripts F:\Scripts.New /U
	 ECHO  %~n0 C:\Source D:\Destination /P:+.DOC+ /U
	 ECHO  %~n0 C:\My\Files \\MyServer\Public\MyFiles
	 ECHO  %~n0 C:\My\Files \\MyServer\Public\YourFiles /L /P:+.CMD
	 ECHO  %~n0 "C:\Programs\This Program" "Y:\Remote\A Long Folder Name"
	 ECHO  %~n0 "C:\Programs\This Program" "Y:\Remote\A Longer Folder Name" /U
	 ECHO  %~n0 -h
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
	 ECHO:
	 ECHO  * The + character must be substituted for * in pattern matches due to the
	 ECHO    way that the FOR command processes the * character.
 )
 CALL :ShowStatus "FINISHED"
                                        