@ECHO OFF
 rem ==========================================================================
 rem === Generate Systems Diagnostics Logs for Troubleshooting
 rem ==========================================================================
 rem
 rem Created On: 16 Feb 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 14 Aug 2025 / 02 Feb 2025 / 10 May 2024 / 30 Mar 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    MiTec System Info X .... https://www.mitec.cz/msi.html
 rem    TDSSKILLER ............. http://support.kaspersky.com/viruses/disinfection/5350
 rem    PRODUKEY ............... http://www.nirsoft.net/utils/product_cd_key_viewer.html
 rem    InfoZip Utilities ...... http://sourceforge.net/projects/infozip/files/
 rem
 rem    DRIVERQUERY ............ Native in Windows XP/2003/Vista+
 rem    OPENFILES .............. Native in Windows XP/2003/Vista+
 rem    SYSTEMINFO ............. Native in Windows XP/2003/Vista+
 rem    AUTORUNSC .............. https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns
 rem    HANDLE ................. https://learn.microsoft.com/en-us/sysinternals/downloads/handle
 rem    LISTDLLS ............... https://learn.microsoft.com/en-us/sysinternals/downloads/listdlls
 rem    PSTOOLS ................ https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
 rem    TCPVCON ................ https://learn.microsoft.com/en-us/sysinternals/downloads/tcpview
 rem    LOGONSESSIONS .......... https://learn.microsoft.com/en-us/sysinternals/downloads/logonsessions
 rem    SRVINFO ................ https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script uses various utilites from the SysInternals suite and other
 :::  diagnostics utilities to capture critical information about a system's
 :::  current state, including the list of running processes, active DLLs,
 :::  current TCP connections, and and open file handles. The full list of
 :::  utilities is indicated above, and can be downloaded for free from 3rd
 :::  party websites or the Windows 2003 Resource Kit (runs on XP and 2003).
 :::
 :::  The script assumes that the executable files have been downloaded to your
 :::  C:\UTILS or C:\Scripts\UTILS folder.  It will also work if the files are
 :::  located anywhere in your current PATH.  You can change the @SOURCE
 :::  variable if you prefer to keep your utilities in a differently named
 :::  folder, or some location that is not  in the path.
 :::
 :::  This script can be a very useful tool for posting system debug info to
 :::  technical mailing lists and forums. For your own safety/security, you
 :::  might want to consider sanitizing the data prior to posting it, as it
 :::  will contain a great deal of information about your system and your
 :::  network configuration.  This is true whether you are a home user or a
 :::  corporate user.
 :::
 :::  Users of Windows XP or Server 2003 will get some extra diagnostics by way
 :::  of the DRIVERQUERY and OPENFILES commands.
 :::
 :::  NOTE: Windows XP HOME Edition does not have some utilities that come
 :::        by default with big brother XP Pro.  OPENFILES, DRIVERQUERY and
 :::        TASKLIST are some of the key ones missing.
 :::
 :::  The zip compatible compression is provided courtesy of the free
 :::  InfoZip utilities, which support all versions of Windows since 2001,
 :::  (has been tested on XP and later) and can process files in excess of 4GB.
 :::
 :::  PLEASE NOTE:
 :::  		The ZIP parameters are case sensitive.
 :::
 :::  (Nov 2010) Changed the default log extension of the reports from .LOG to
 :::  .TXT so that the reports that are mailed to mobile devices can be read
 :::  automatically. (Not too many devices can natively handle .LOG files)
 :::
 :::  (Feb 2011) Added a validator to the :MakeLog2 subroutine that attempts to
 :::  ensure that the executable to be called exists before trying to execute
 :::  the command.  Previously, the script would break if output from a non-
 :::  existent command was passed to the FIND command. It is still a good idea
 :::  to ensure that all needed executables exist on the machine, and are stored
 :::  in the recommended folders or somewhere else in the PATH.
 :::
 :::  (Jul 2011) Added a minor FOR loop using the -accepteula parameter in
 :::  order to accept various SysInternals utilities before the time of the
 :::  actual command execution occurs.
 :::
 :::  (Nov 2011) Replaced "RootKit Revealer" from SysInternals with "TDSSKiller"
 :::  from Kaspersky Security, since TDSSKiller is more up to date, and supports
 :::  both 32-bit and 64-bit systems in a remote console window.
 :::
 :::  (Apr 2015) v3.0 -- Updated :ShowStatus routine to track script duration.
 :::
 :::  (Jul 2015) v3.1 -- Now tracks logon sessions and associated processes
 :::  with LogonSessions from SysInternals.
 :::
 :::  (Aug 2016) v3.3 -- Added output from additional SysInternals tools:
 :::                     PipeList, RU
 :::
 :::  (Aug 2016) v3.4 -- Move log files to ZIP and then delete originals
 :::
 :::  (Apr 2017) v3.5 -- Recent versions of LISTDLLS have created massive logs
 :::  especially in Windows 10 and Windows 2016.  The script now checks for at
 :::  least 16GB (default) of free disk space on the log drive or it won't
 :::  execute the verbose option for LISTDLLS.
 :::
 :::  (Jan 2018) v3.7 -- Still experiencing intermittent problems with obese
 :::  logs from LISTDLLS.  For now, we will ensure that LISTDLLS is killed after
 :::  running for more than 10 minutes, and see if this addresses the issue.
 :::
 :::  (May 2018) v3.8 -- Changed the HELP routine to use FINDSTR;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v3.9 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v4.0 -- The -V parameter of LISTDLLS will no longer be run
 :::  unless there is more than 16GB freee space, and @EXT_LISTDLLS=EXTENDED.
 :::
 :::  (Oct 2018) v4.1 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Nov 2018) v4.2 -- Capture ANSI output for AUTORUNSC;
 :::  -- Update UPTIME.EXE references to UPTIME2.EXE;
 :::
 :::  (Oct 2019) v4.3 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (May 2020) v4.4 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Nov 2020) v4.5 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Oct 2023) v4.6 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (Mar 2024) v5.0 -- Verify existence of files using FINDFILES;
 :::  -- Send error output to a different folder and calculate free space;
 :::  -- Move folder/file space calculator to its own subroutine;
 :::  -- Change FreeSpace default for running LISTDLLs to 32GB, from 16GB
 :::
 :::  (May 2024) v5.1 -- Modernize essential check for SetDrive.BAT;
 :::
 :::  (Feb 2025) v5.2 -- Replaced COMPINFO with MiTec System Info X
 :::  to get around the constant process crashes of COMPINFO;
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
 rem === Updated On: 01 Feb 2025 / 10 May 2024 / 30 Mar 2024 / 30 Nov 2020
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v5.2.0.2320 c

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f "%~dp0SetDrive.BAT"
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Establish Min Free Diskspace (32GB) for executing LISTDLLS -v
 SET @MIN_FREE=33554432
 SET @EXT_LISTDLLS=FALSE

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Get Current Free Diskspace on LOGS$ Drive...
 CALL :GetFreeSpace "%@LOGBASE%" @FILESIZE @FREESPACE
 SET @EXT_LOGS=FALSE& IF DEFINED @FREESPACE IF %@FREESPACE% GTR %@MIN_FREE% SET @EXT_LOGS=TRUE

 rem -- Set Log Related Variables...
 SET @LOGHEADER=COMPLETE Systems Diagnostics Log -- [%@TIMESTAMP%]
 SET @LOGPATH=%@STORAGE%\Logs\Debug\System
 SET @ZIPPATH=%@STORAGE%\Logs\ZipFiles
 SET @TEMPLOG=%@LOGPATH%\TEMPLOG.INFO
 SET @LOGFILE1=%@LOGPATH%\SYSINFO.INFO
 SET @LOGFILE2=%@LOGPATH%\TASKLIST.INFO
 SET @LOGFILE3=%@LOGPATH%\OPENFILES.INFO
 SET @LOGFILE4=%@LOGPATH%\LISTDLLS.INFO
 SET @LOGFILE5=%@LOGPATH%\SERVICES.INFO
 SET @LOGFILE6=%@LOGPATH%\DRIVERS.INFO
 SET @LOGFILE7=%@LOGPATH%\EVENTLOG.INFO
 SET @LOGFILE8=%@LOGPATH%\MSINFO32.INFO
 SET @LOGFILE9=%@LOGPATH%\REGISTRY.INFO
 SET @ERRORLOG=%@LOGPATH%\ERRORLOG.INFO
 SET @ALL-LOGS="%@LOGFILE1%" "%@LOGFILE2%" "%@LOGFILE3%" "%@LOGFILE4%" "%@LOGFILE5%" "%@LOGFILE6%" "%@LOGFILE7%" "%@LOGFILE8%" "%@LOGFILE9%" "%@ERRORLOG%"
 SET @BIGTXT=%@LOGPATH%\%COMPUTERNAME%-DEBUG.TXT
 SET @BIGLOG=%@LOGPATH%\%COMPUTERNAME%-DEBUG.%@FILESTAMP%
 SET @ARCHIVE=%@ZIPPATH%\%COMPUTERNAME%-DEBUG.%@ZIPSTAMP%

 rem -- Set Proper Path for Dr Watson Logs (Pre/Post Windows Vista/2008)...
 SET @DRWATSON="%SystemDrive%\Documents and Settings\All Users\Application Data\Microsoft\Dr Watson" "%USERPROFILE%\AppData\Local\Microsoft\Windows\WER\ReportArchive"
 SET @DRWTSN32=%@DRWATSON%\drwtsn32.log

 rem -- Set Shortname for MSINFO32
 SET @MSINFO=%ProgramFiles%\Common Files\Microsoft Shared\MSInfo\MSINFO32.EXE

 rem -- Set PATH to Debug Utilities
 SET @ROOT=%SystemDrive%\Scripts
 SET @SOURCE="%@ROOT%\BAT" "%@ROOT%\UTILS" "%@ROOT%" "%SystemDrive%\UTILS"
 FOR %%P IN (%@SOURCE%) DO IF EXIST "%%~P" SET PATH=%PATH%;%%~P

 rem -- Get List of Essential Utilities and/or Scripts
 SET @ESSENTIAL=PRODUKEY NET PSINFO UPTIME2 SRVINFO LOGONSESSIONS TASKLIST TCPVCON PSLIST PSFILE OPENFILES HANDLE PIPELIST LISTDLLS AUTORUNSC PSSERVICE DRIVERQUERY PSLOGLIST SYSTEMINFO TDSSKILLER "%@MSINFO%" RU ZIP -o GETSYS


 rem ==========================================================================
 rem === Create Systems Diagnostics Info
 rem === Updated On: 02 Feb 2025 / 10 May 2024 / 30 Mar 2024 / 05 Oct 2019
 rem ==========================================================================
:GetDiagnostics
 FOR %%F IN ("%@LOGPATH%" "%@ZIPPATH%") DO IF NOT EXIST "%%~F" MD "%%~F"

 CALL :GetTime @STIME
 ECHO Creating Systems Diagnostics Logs...  Please be patient...
 ECHO:
 ECHO This entire process can take up to 20 minutes to run, especially on systems
 ECHO that have an older/slower processor, and/or have very large hard drives...
 ECHO:
 CALL :SpecialInfo

 ( rem -- Create New Log Headers...
	 ECHO %@LOGHEADER%
	 ECHO Generated by %@VER%
	 ECHO:
	 ECHO:
	 FINDFILES --bw -w -m -f %@ESSENTIAL%
	 ECHO:
 ) >"%@BIGLOG%"

 rem -- Write to Log
 FOR %%B IN (%@ALL-LOGS%) DO (
	 ECHO %@DIVIDER*%
	 ECHO *** %%B -- [%@TIMESTAMP%]
	 ECHO *** Generated by %@VER%
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >%%B

 rem -- Accept the EULA for SysInternals Utilities
 FOR %%S IN (%@PSTOOLS%) DO %%~S %@PSACCEPT% -? >NUL 2>NUL

 rem -- Generate Diagnostics Data...
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "SET"
 CALL :MakeLog3 FALSE "%@LOGFILE1%" "PRODUKEY" /STEXT
 FOR %%D IN (%@SOURCE% %@DRWATSON%) DO IF EXIST %%D CALL :MakeLog1 FALSE "%@LOGFILE1%" "DIR /OGN" "%%~D"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "NET USE"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "NET SHARE"
 CALL :MakeLog2 FALSE "%@LOGFILE1%" "PSINFO %@PSPARAMS%" "Uptime: "
 CALL :MakeLog1 TRUE  "%@LOGFILE1%" "UPTIME2 /S"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PSINFO %@PSPARAMS% -s -d -h"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "SRVINFO -ns"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "TYPE %SystemRoot%\System32\Drivers\Etc\HOSTS.*"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "TYPE %SystemRoot%\System32\Drivers\Etc\LMHOSTS.*"

 CALL :MakeLog1 FALSE "%@LOGFILE2%" "LOGONSESSIONS %@PSPARAMS% -p"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "TASKLIST /SVC"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "TCPVCON %@PSPARAMS%"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "TASKLIST /V"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "TASKLIST"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "PSLIST %@PSPARAMS% -t"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "PSLIST %@PSPARAMS% -m"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "PSLIST %@PSPARAMS% -x"

 CALL :MakeLog1 FALSE "%@LOGFILE3%" "PSFILE %@PSPARAMS%"
 CALL :MakeLog1 FALSE "%@LOGFILE3%" "OPENFILES /QUERY /FO LIST"
 CALL :MakeLog1 FALSE "%@LOGFILE3%" "HANDLE %@PSPARAMS%"
 CALL :MakeLog1 FALSE "%@LOGFILE3%" "PIPELIST %@PSPARAMS%"

 rem -- Check for Sufficient Disk Space (32GB default) and Extended ListDLLS mode before generating extended LISTDLLS log data
 IF /I "%@EXT_LISTDLLS%/%@EXT_LOGS%"=="EXTENDED/TRUE" (
	 CALL :MakeLog1 TRUE  "%@LOGFILE4%" "LISTDLLS %@PSPARAMS% -v"
 ) ELSE (
	 CALL :MakeLog1 FALSE "%@LOGFILE4%" "LISTDLLS %@PSPARAMS%"
 )

 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PSINFO %@PSPARAMS% -s"
 CALL :MakeLog3 FALSE "%@LOGFILE5%" "AUTORUNSC" %@PSPARAMS% -a * -h -o
 CALL :MakeLog2 FALSE "%@LOGFILE5%" "PSSERVICE %@PSPARAMS% query -s active" "DISPLAY_NAME:"
 CALL :MakeLog1 FALSE "%@LOGFILE5%" "PSSERVICE %@PSPARAMS%"

 CALL :MakeLog1 FALSE "%@LOGFILE6%" "SRVINFO -d"
 CALL :MakeLog1 FALSE "%@LOGFILE6%" "DRIVERQUERY /SI"
 CALL :MakeLog1 FALSE "%@LOGFILE6%" "DRIVERQUERY /FO TABLE"
 CALL :MakeLog1 FALSE "%@LOGFILE6%" "DRIVERQUERY /FO LIST /V"

 CALL :MakeLog2 FALSE "%@LOGFILE7%" "PSLOGLIST %@PSACCEPT% -s -d 5         Security" "FAILURE"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "PSLOGLIST %@PSACCEPT% -s -n 20 -f EW  System"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "PSLOGLIST %@PSACCEPT% -s -n 20 -f EW  Application"

 rem -- Run the Fairly Comprehensive System Information Reports (GETSYS, SYSTEMINFO, etc)...
 CALL :MakeLog1 FALSE "%@LOGFILE8%" "GETSYS /so /ld /na /la /id /usb"
 CALL :MakeLog1 FALSE "%@LOGFILE8%" "SYSTEMINFO"

 rem -- Run the Very Lengthy, but Comprehensive, MSINFO and AntiRootKit reports...
 CALL :MakeLog3 TRUE  "%@LOGFILE5%" "TDSSKILLER" -accepteula -accepteulaksn -dcexact -sigcheck -tdlfs -silent -l
 CALL :MakeLog3 TRUE  "%@LOGFILE8%" "%@MSINFO%" /REPORT

 rem -- Obtain Registry Statistics for the HKLM and HKU keys...
 CALL :MakeLog1 TRUE "%@LOGFILE9%" "RU %@PSPARAMS% -v HKLM"
 CALL :MakeLog1 TRUE "%@LOGFILE9%" "RU %@PSPARAMS% -v HKU"


 rem ==========================================================================
 rem === Create Aggregate Diagnostics Log and Report Time
 rem === Updated On: 03 Dec 2017 / 17 Jan 2016
 rem ==========================================================================
:FinalReport
 CALL :GetTime @ETIME

 FOR %%B IN (%@ALL-LOGS% %@DRWTSN32%) DO IF EXIST "%%~B" (
	 TYPE "%%~B"
	 ECHO:
	 ECHO:
 ) >>"%@BIGLOG%"

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO  DIAGNOSTICS LOGS LOCATION: "%@LOGPATH:~-40%\*.INFO"
	 ECHO %@DIVIDER-%
	 ECHO  Started On .................................... %@STIME%
	 ECHO  Ended On ...................................... %@ETIME%
	 ECHO:
	 ECHO:
	 ECHO:
	 ECHO %@DIVIDER*%
 ) >"%@BIGTXT%"

 TYPE "%@BIGTXT%" >>"%@BIGLOG%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Compress Diagnostics Logs to facilitate eMailing
 rem === Updated On: 30 Mar 2024 / 17 Sep 2016 / 17 Jan 2016
 rem ==========================================================================
:ZipLogs
 ECHO:
 ECHO Compressing Diagnostics Logs...
 PUSHD "%@LOGPATH%"

 rem -- Get Current Free Diskspace and Delete Error Logs If Insufficient Space...
 CALL :GetFreeSpace "%@ERRORLOG%" @FILESIZE @FREESPACE
 IF DEFINED @FREESPACE IF DEFINED @FILESIZE (
	IF %@FILESIZE% GEQ %@MIN_FREE% ECHO LOGFILE TOO LARGE [%@FILESIZE%] -- CONTENTS OVERWRITTEN... >"%@ERRORLOG%"
 )

 ( rem -- Write to Log
	 ZIP -m -9 -v -dgds 1m -T -j "%@ARCHIVE%" %@ALL-LOGS% "%@BIGLOG%"
	 ECHO:
	 ECHO DIAGNOSTICS LOG COMPLETED AT %TIME% ON %DATE%
	 ECHO:
	 ECHO %@DIVIDER*%
 ) >>"%@BIGTXT%"

 POPD
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Display Diagnostics Log Collection
 rem === Updated On: 17 Sep 2016 / 19 Feb 2014
 rem ==========================================================================
:ShowLog
 ECHO:
 ECHO Opening Diagnostics Logs...

 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 FOR %%V IN ("%@LOGPATH%" "%@ZIPPATH%") DO START " " %%V
	 FOR %%V IN (%@ALL-LOGS% "%@BIGLOG%") DO IF EXIST "%%~V" START NOTEPAD "%%~V"
 ) ELSE (
	 IF EXIST "%@BIGLOG%" TYPE "%@BIGLOG%"
	 DIR "%@LOGPATH%"
 )
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
 rem === Updated On: 16 Oct 2023 / 21 Apr 2015
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Create Individual Diagnostics Logs
 rem === Updated On: 30 Mar 2024 / 17 Jan 2016 / 05 Feb 2015
 rem ==========================================================================
:MakeLog1
 rem %1 = Boolean Value to Denote Long Running Processes
 rem %2 = Current Log File
 rem %3 = Diagnostics Command/Utility with parameters
 rem %4 = Any additional parameters, such as quoted directory name

 IF /I "%~1"=="TRUE" (SET @MARK=***) ELSE (SET @MARK=   )
 ECHO  %TIME:~0,8%- %@MARK% %~3 %4
 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO [%TIME%] --- Executed: %~3 %4
	 ECHO %@DIVIDER-%
	 %~3 %4
	 ECHO:
	 ECHO:
 ) >>"%~2" 2>>"%@ERRORLOG%"
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Create Individual Diag Logs with FIND command
 rem === Updated On: 30 Mar 2024 / 17 Jan 2016 / 05 Feb 2015
 rem ==========================================================================
:MakeLog2
 rem %1 = Boolean Value to Denote Long Running Processes
 rem %2 = Current Log File
 rem %3 = Diagnostics Command/Utility with parameters
 rem %4 = Parameters for %3 Command/Utility
 rem %5 = Filtering Criteria of Command/Utility

 rem -- Exit Subroutine If Insufficient Parameters
 IF "%~5"=="" EXIT /B

 rem -- Exit Subroutine If Executable Does Not Exist
 FINDFILES --rc -f "%~3"
 IF ERRORLEVEL 64 EXIT /B

 IF /I "%~1"=="TRUE" (SET @MARK=***) ELSE (SET @MARK=   )
 ECHO  %TIME:~0,8%- %@MARK% %~3 %4 ^| FIND /I "%~5"
 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO [%TIME%] --- Executed: %~3 %4 ^| FIND /I "%~5"
	 ECHO %@DIVIDER-%
	 %~3 %4 | FIND /I "%~5"
	 ECHO:
	 ECHO:
 ) >>"%~2" 2>>"%@ERRORLOG%"
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Create Individual Diag Logs using Intermediate Log File
 rem === Updated On: 30 Mar 2024 / 15 May 2018 / 17 Jan 2016
 rem ==========================================================================
:MakeLog3
 rem %1  = Boolean Value to Denote Long Running Processes
 rem %2  = Current Log File
 rem %3  = Diagnostics Command/Utility with parameters
 rem %4+ = Additional Parameters for Command in Parameter Slot #3

 SET @PARAMS=%*
 FOR %%e IN (%1 %2 %3) DO SET @PARAMS=!@PARAMS:%%e=!
 IF /I "%~1"=="TRUE" (SET @MARK=***) ELSE (SET @MARK=   )

 ECHO  %TIME:~0,8%- %@MARK% %~n3 !@PARAMS! "%~nx2"
 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO [!TIME: =0!] --- Executed: %~n3 !@PARAMS! "%~nx2"
	 ECHO %@DIVIDER-%
	 "%~3" !@PARAMS! "%@TEMPLOG%"
	 TYPE "%@TEMPLOG%"
	 ECHO:
	 ECHO:
	 IF EXIST "%@TEMPLOG%" DEL "%@TEMPLOG%" >NUL
 ) >>"%~2" 2>>"%@ERRORLOG%"
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Free Space from a Folder
 rem === Updated On: 30 Mar 2024
 rem ==========================================================================
:GetFreeSpace
 rem %1  = File to Examine
 rem %2  = Variable for storing File Size
 rem %3  = Variable for storing Disk Free Space

 IF NOT EXIST "%~1" EXIT /B
 IF "%~2"=="" EXIT /B
 IF "%~3"=="" EXIT /B

 FOR /F %%S IN ('DIR /B /S "%~1"') DO SET %~2=%%~zS
 FOR /F "TOKENS=3 DELIMS=) " %%F IN ('DIR "%~1" ^| FIND " bytes free"') DO SET "@FS=%%F "
 SET %~3=!@FS:,=!
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Output Warning Message
 rem === Updated On: 17 Jan 2016 / 05 Feb 2015
 rem ==========================================================================
:SpecialInfo
 ECHO:
 ECHO %@DIVIDER-%
 ECHO  P N:  This script may break if all the necessary files have not been
 ECHO  L O:  downloaded and placed in C:\UTILS (or somewhere in your PATH).  If
 ECHO  E T:  you receive an error message, OR you do not see the final line of
 ECHO  A E:  output "OPENING DIAGNOSTICS LOGS", then you are probably missing
 ECHO  S  :  files, or have placed them in the wrong locations.  Please see the
 ECHO  E  :  instructions for more details.
 ECHO %@DIVIDER-%
 ECHO:
 ECHO Commands marked with *** can take several minutes to run by themselves...
 ECHO:
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
 rem === Updated On: 30 Nov 2020 / 15 May 2018
 rem ==========================================================================
:HelpMessage
 ECHO Generate Systems Diagnostics Logs for Troubleshooting Local Machine
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  {no parameters required}
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
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
                                                     