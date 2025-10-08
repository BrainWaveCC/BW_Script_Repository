@ECHO OFF
 rem ==========================================================================
 rem === Generate Network Diagnostics Logs for Troubleshooting
 rem ==========================================================================
 rem
 rem Created On: 18 Feb 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 14 Aug 2025 / 02 Feb 2025 / 10 May 2024 / 16 Oct 2023
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
 rem
 rem  Non-Native Utilities Used/Required/OPTIONAL:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    MiTec System Info X .... https://www.mitec.cz/msi.html
 rem    InfoZip Utilities ...... http://sourceforge.net/projects/infozip/files/
 rem
 rem    PATHPING ............... Windows XP/2003/Vista (only)
 rem    NETSH .................. Windows XP/2003/Vista (only)
 rem    NETDIAG ................ Windows 2000/XP/2003 Support Tools
 rem    PSPING ................. https://learn.microsoft.com/en-us/sysinternals/downloads/psping
 rem    PSTOOLS ................ https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
 rem    TCPVCON ................ https://learn.microsoft.com/en-us/sysinternals/downloads/tcpview
 rem    LOGONSESSIONS .......... https://learn.microsoft.com/en-us/sysinternals/downloads/logonsessions
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script uses a variety of native Windows networking utilities such as
 :::  PING, TRACERT, and NSLOOKUP to log connection attempts to YAHOO.COM and
 :::  GOOGLE.COM by name and by IP, and record the networking configuration of
 :::  the local system for analysis.  It is possible to provide an alternate
 :::  destination site for both of these entries at the command line, or by
 :::  changing the @NAME1 and @NAME2 variables manually.  Up to 9 log files,
 :::  including one big consoldated log, will be generated.
 :::
 :::  Additional utilities from the Resource Kit, SysInternals suite, or
 :::  subsequent versions of Windows can be downloaded and placed in one of the
 :::  following folders:  C:\UTILS or C:\Scripts\UTILS or [anywhere in the PATH]
 :::
 :::  This script can be a very useful tool for posting system debug info to
 :::  technical mailing lists and forums. For your own safety/security, you
 :::  might want to consider sanitizing the data prior to posting it, as it
 :::  will contain a great deal of information about your system and your
 :::  network configuration.  This is true whether you are a home user or a
 :::  corporate user.
 :::
 :::  The zip compatible compression is provided courtesy of the free
 :::  InfoZip utilities, which support all versions of Windows since 2001,
 :::  (has been tested on XP and later) and can process files in excess of 4GB.
 :::
 :::  PLEASE NOTE: The ZIP parameters are case sensitive.
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
 :::  in the recommended folders or somewhere else in the PATH. By default,
 :::  the script will run fine with only the native tools present.
 :::
 :::  (Jul 2011) Added a minor FOR loop using the -accepteula parameter in
 :::  order to accept various SysInternals utilities before the time of the
 :::  actual command execution occurs.
 :::
 :::  (Feb 2014) Added PSPING (from SysInternals) to the diagnostics tools.
 :::
 :::  (Apr 2015) v3.0 -- Updated :ShowStatus routine to track script duration.
 :::
 :::  (Jul 2015) v3.1 -- Now tracks logon sessions and associated processes
 :::  with LogonSessions from SysInternals.
 :::
 :::  (May 2018) v3.4 -- Changed the HELP routine to use FINDSTR;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v3.5 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Oct 2018) v3.6 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Feb 2019) v3.7 -- Removed redundant variables and updated code page support;
 :::
 :::  (Oct 2019) v3.8 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (May 2020) v3.9 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Nov 2020) v3.10 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Oct 2023) v3.11 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v4.0 -- Check for essential utilities with FINDFILES;
 :::
 :::  (Feb 2025) v4.1 -- Replaced COMPINFO with MiTec System Info X
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
 rem === Updated On: 02 Feb 2025 / 10 May 2024 / 30 Nov 2020 / 26 May 2020
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v4.1.0.2310 c

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Set Shortname for MSINFO32
 SET @MSINFO=%ProgramFiles%\Common Files\Microsoft Shared\MSInfo\MSINFO32.EXE

 rem -- Establish Key Tools from SysInternals
 SET @PSTOOLS=LOGONSESSIONS TCPVCON PSEXEC PSPING PIPELIST PSFILE

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT"
 SET #MSUTILS=ARP.EXE IPCONFIG.EXE NBTSTAT.EXE NETSH.EXE NETSTAT.EXE NSLOOKUP.EXE PATHPING.EXE PING.EXE ROUTE.EXE SYSTEMINFO.EXE TRACERT.EXE "%@MSINFO%"
 SET #O_UTILS=%@PSTOOLS% ZIP.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS% -o NETDIAG.EXE GETSYS.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Set Log Related Variables...
 SET @LOGHEADER=COMPLETE Network Diagnostics Log -- [%@TIMESTAMP%]
 SET @LOGPATH=%@STORAGE%\Logs\Debug\Network
 SET @ZIPPATH=%@STORAGE%\Logs\ZipFiles
 SET @TEMPLOG=%@LOGPATH%\TEMPLOG.INFO
 SET @LOGFILE1=%@LOGPATH%\PING.INFO
 SET @LOGFILE2=%@LOGPATH%\ROUTE.INFO
 SET @LOGFILE3=%@LOGPATH%\TRACERT.INFO
 SET @LOGFILE4=%@LOGPATH%\NSLOOKUP.INFO
 SET @LOGFILE5=%@LOGPATH%\IPCONFIG.INFO
 SET @LOGFILE6=%@LOGPATH%\CACHE.INFO
 SET @LOGFILE7=%@LOGPATH%\SOCKETS.INFO
 SET @LOGFILE8=%@LOGPATH%\MSINFO32.INFO
 SET @ALL-LOGS="%@LOGFILE1%" "%@LOGFILE2%" "%@LOGFILE3%" "%@LOGFILE4%" "%@LOGFILE5%" "%@LOGFILE6%" "%@LOGFILE7%" "%@LOGFILE8%"
 SET @BIGTXT=%@LOGPATH%\%COMPUTERNAME%-IPDEBUG.TXT
 SET @BIGLOG=%@LOGPATH%\%COMPUTERNAME%-IPDEBUG.%@FILESTAMP%
 SET @ARCHIVE=%@ZIPPATH%\%COMPUTERNAME%-IPDEBUG.%@ZIPSTAMP%

 rem -- Obtain hostname #1 from parameter and determine IP
 SET @NAME1=%1& IF "%~1"=="" SET @NAME1=yahoo.com
 ECHO -- Looking Up IP Address for: %@NAME1%
 FOR /F "TOKENS=2 DELIMS=, " %%I IN ('NSLOOKUP %@NAME1% 2^>NUL ^| FIND "Address"') DO SET @IP1=%%I
 SET @IP1=%@IP1:,=%& IF /I "%@IP1%"=="" SET @IP1=66.218.71.198

 rem -- Obtain hostname #2 from parameter and determine IP
 SET @NAME2=%2& IF "%~2"=="" SET @NAME2=google.com
 ECHO -- Looking Up IP Address for: %@NAME2%
 FOR /F "TOKENS=2 DELIMS=, " %%I IN ('NSLOOKUP %@NAME2% 2^>NUL ^| FIND "Address"') DO SET @IP2=%%I
 SET @IP2=%@IP2:,=%& IF /I "%@IP2%"=="" SET @IP2=216.239.37.99

 rem -- Set PATH to Debug Utilities
 SET @SOURCE="%SystemDrive%\Scripts" "%SystemDrive%\UTILS" "%SystemDrive%\Scripts\BAT" "%SystemDrive%\Scripts\UTILS"
 FOR %%P IN (%@SOURCE%) DO IF EXIST "%%~P" SET PATH=%PATH%;%%~P


 rem ==========================================================================
 rem === Create Network Diagnostics Info
 rem === Updated On: 02 Feb 2025 / 05 Oct 2019 / 15 May 2018
 rem ==========================================================================
:GetDiagnostics
 FOR %%F IN ("%@LOGPATH%" "%@ZIPPATH%") DO IF NOT EXIST "%%~F" MD "%%~F"

 CALL :GetTime @STIME
 ECHO Creating Network Diagnostics Logs...  Please be patient...
 ECHO:
 ECHO This entire process can take up to 20 minutes to run, especially on systems
 ECHO that have an older/slower processor, or have very slow network connectivity...
 ECHO:
 CALL :SpecialInfo

 ( rem -- Create New Log Headers...
	 ECHO %@LOGHEADER%
	 ECHO Generated by %@VER%
	 ECHO:
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

 rem -- Generate Network Diagnostics Data...
 CALL :MakeLog1 FALSE "%@LOGFILE5%" "IPCONFIG /ALL"
 CALL :MakeLog1 FALSE "%@LOGFILE2%" "ROUTE -p PRINT"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "NETSTAT -a"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "TCPVCON -c"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "LOGONSESSIONS -p"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "PSFILE"

 CALL :MakeLog1 FALSE "%@LOGFILE4%" "NSLOOKUP %@NAME1%"
 CALL :MakeLog1 FALSE "%@LOGFILE4%" "NSLOOKUP %@IP1%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PING %@NAME1%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PING %@IP1%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PSPING -n 10 -w 3 %@NAME1%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PSPING -n 10 -w 3 %@IP1%"

 CALL :MakeLog1 FALSE "%@LOGFILE4%" "NSLOOKUP %@NAME2%"
 CALL :MakeLog1 FALSE "%@LOGFILE4%" "NSLOOKUP %@IP2%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PING %@NAME2%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PING %@IP2%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PSPING -n 10 -w 3 %@NAME2%"
 CALL :MakeLog1 FALSE "%@LOGFILE1%" "PSPING -n 10 -w 3 %@IP2%"

 rem -- Determine If Running XP or Windows 2003, Before Running NETSH DIAG...
 FOR %%Z IN (2600 3790) DO IF %@OSBUILD% EQU %%Z CALL :MakeLog1 FALSE "%@LOGFILE5%" "NETSH DIAG SHOW all"
 FOR %%Z IN (2600 3790) DO IF %@OSBUILD% EQU %%Z CALL :MakeLog1 FALSE "%@LOGFILE1%" "NETSH DIAG PING ADAPTER"

 CALL :MakeLog1 TRUE  "%@LOGFILE3%" "TRACERT -h 30 %@NAME1%"
 CALL :MakeLog1 TRUE  "%@LOGFILE3%" "TRACERT -h 30 %@IP1%"
 CALL :MakeLog1 TRUE  "%@LOGFILE3%" "PATHPING %@IP1% -p 10"

 CALL :MakeLog1 TRUE  "%@LOGFILE3%" "TRACERT -h 30 %@NAME2%"
 CALL :MakeLog1 TRUE  "%@LOGFILE3%" "TRACERT -h 30 %@IP2%"
 CALL :MakeLog1 TRUE  "%@LOGFILE3%" "PATHPING %@IP2% -p 10"

 CALL :MakeLog1 FALSE "%@LOGFILE7%" "NBTSTAT -c"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "NETSTAT -an"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "NETSTAT -ano"
 CALL :MakeLog1 FALSE "%@LOGFILE7%" "TCPVCON -a"
 CALL :MakeLog1 FALSE "%@LOGFILE6%" "ARP -A"
 CALL :MakeLog1 FALSE "%@LOGFILE6%" "IPCONFIG /DISPLAYDNS"
 CALL :MakeLog1 FALSE "%@LOGFILE6%" "TYPE %SystemRoot%\System32\Drivers\Etc\HOSTS.*"
 CALL :MakeLog1 FALSE "%@LOGFILE6%" "TYPE %SystemRoot%\System32\Drivers\Etc\LMHOSTS.*"

 rem -- Determine If Running Windows 2003, Before Running NetDIAG...
 IF %@OSBUILD% EQU 3790 CALL :MakeLog1 FALSE "%@LOGFILE5%" "NETDIAG"

 rem -- Run the Fairly Comprehensive System Information Reports (GETSYS, SYSTEMINFO, etc)...
 CALL :MakeLog1 FALSE "%@LOGFILE8%" "GETSYS /so /ld /na /la /id /usb"
 CALL :MakeLog1 FALSE "%@LOGFILE8%" "SYSTEMINFO"

 rem -- Run The Very Lengthy, but Comprehensive, MSINFO Report...
 CALL :MakeLog3 TRUE  "%@LOGFILE8%" "%@MSINFO%" /REPORT


 rem ==========================================================================
 rem === Create Aggregate Diagnostics Log and Report Time
 rem === Updated On: 17 Jan 2016 / 05 Feb 2015
 rem ==========================================================================
:FinalReport
 CALL :GetTime @ETIME

 FOR %%B IN (%@ALL-LOGS%) DO IF EXIST "%%~B" (
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
 ) >>"%@BIGLOG%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Compress Diagnostics Logs to facilitate eMailing
 rem === Updated On: 06 Nov 2016 / 17 Jan 2016
 rem ==========================================================================
:ZipLogs
 ECHO:
 ECHO Compressing Diagnostics Logs...
 PUSHD "%@LOGPATH%"

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
 rem === Updated On: 06 Nov 2016 / 19 Feb 2014
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
 rem === Updated On: 17 Jan 2016 / 05 Feb 2015
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
 ) >>"%~2" 2>&1
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Create Individual Diag Logs with FIND command
 rem === Updated On: 17 Jan 2016 / 21 Apr 2015
 rem ==========================================================================
:MakeLog2
 rem %1 = Boolean Value to Denote Long Running Processes
 rem %2 = Current Log File
 rem %3 = Diagnostics Command/Utility with parameters
 rem %4 = Filtering Criteria of Command/Utility

 rem -- Exit Subroutine If Insufficient Parameters
 IF "%~4"=="" EXIT /B

 rem -- Exit Subroutine If Executable Does Not Exist
 FOR /F "TOKENS=*" %%C IN ('%~3 -? 2^>^&1') DO IF "%%~C"=="operable program or batch file." EXIT /B

 IF /I "%~1"=="TRUE" (SET @MARK=***) ELSE (SET @MARK=   )
 ECHO  %TIME:~0,8%- %@MARK% %~3 ^| FIND /I "%~4"
 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-%
	 ECHO [%TIME%] --- Executed: %~3 ^| FIND /I "%~4"
	 ECHO %@DIVIDER-%
	 %~3 | FIND /I "%~4"
	 ECHO:
	 ECHO:
 ) >>"%~2" 2>&1
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Create Individual Diags Logs using Intermediate Log File
 rem === Updated On: 15 May 2018 / 17 Jan 2016
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
 ) >>"%~2"
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Output Warning Message
 rem === Updated On: 17 Jan 2016 / 21 Apr 2015
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
 ECHO Generate Network Diagnostics Logs for Troubleshooting Local Machine
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [ip_address_1 ^| full_dns_name_of_remote_host_1]  [ip_address_2 ^| full_dns_name_of_remote_host_2]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 www.dilbert.com
	 ECHO  %~n0 65.114.4.69  yahoo.com
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
                                                                           