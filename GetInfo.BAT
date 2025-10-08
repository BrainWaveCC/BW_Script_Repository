@ECHO OFF
 rem ==========================================================================
 rem === Forensics Info for Remote Malware Detection Analysis
 rem ==========================================================================
 rem
 rem Created On: 10 May 2005
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 29 Sep 2025 / 14 Aug 2025 / 01 Feb 2025 / 11 Sep 2024 / 28 Jul 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    AUTORUNSC .............. https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns
 rem    HANDLE ................. https://learn.microsoft.com/en-us/sysinternals/downloads/handle
 rem    LISTDLLS ............... https://learn.microsoft.com/en-us/sysinternals/downloads/listdlls
 rem    PSTOOLS ................ https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
 rem    TCPVCON ................ https://learn.microsoft.com/en-us/sysinternals/downloads/tcpview
 rem    LOGONSESSIONS .......... https://learn.microsoft.com/en-us/sysinternals/downloads/logonsessions
 rem    SRVINFO ................ https://en.wikipedia.org/wiki/Resource_Kit
 rem    MiTec System Info X .... https://www.mitec.cz/msi.html
 rem    TDSSKILLER ............. http://support.kaspersky.com/viruses/disinfection/5350
 rem    RESOLVE ................ Email Gerald W. Gaston (gwgaston [at] yahoo.com) for more info
 rem    WHOSIP (Optional) ...... http://www.nirsoft.net/utils/whosip.html
 rem    NMAP (Optional) ........ https://nmap.org/download.html
 rem    CHOICE (Optional) ...... Native in Windows 2003 and 64-bit XP / Reskit in NT/2000
 rem    Blat ................... http://www.blat.net/
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem    InfoZip Utilities ...... http://sourceforge.net/projects/infozip/files/
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem    UPTIME2 ................ https://techibee.com/tools/say-hello-to-uptime2-exe-alternative-for-uptime-exe/1728
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    [BadProcesses].TXT ..... List of Known Malware Processes to Check For
 rem    [KnownServices].TXT .... List of Services Which are Valid for This Environment
 rem    [ValidSecTools].TXT .... List of AntiMalware and Patch Mgmt Tools to Check For
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem    NetworkSegments.TXT .... Map of Network IP Subnet Ranges to Pinpoint Suspect Systems
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script uses various utilities from SysInternals (e.g. LISTDLLS and
 :::  HANDLE), Windows Resource Kit (e.g. SRVINFO), and antimalware vendors
 :::  (e.g. McAfee and Kaspersky) in order to generate a security forensics
 :::  report of potentially infected systems.
 :::
 :::  NOTE: The Resource Kit has to be installed after being downloaded.
 :::
 :::  This script also supports NMAP.  To run it, the NMAP folder must be in
 :::  your PATH.  As it pertains to this script, the default supported PATH
 :::  for NMAP is "C:\Programs\NMap"  (Actually, the script was updated
 :::  around version 1.8x to support multiple NMap search paths).
 :::
 :::  Much of the detailed info is only possible with admin access of the
 :::  remote system.  Some information might not be possible depending on the
 :::  configuration of the remote system (e.g. firewall enabled). Additionally,
 :::  the further away the system in question is, the longer the script will
 :::  take to obtain some of the details.
 :::
 :::  NOTE: Because of changes to the SysInternals Utilities as of Nov 2006,
 :::        the tools require acceptance of a EULA before they will execute
 :::        on a remote system.  This affects any SysInternals utility, such
 :::        as HANDLE or LISTDLLS that is executed via PSEXEC.  A second
 :::        script, SetEULA.BAT, has been created to deal with this.
 :::
 :::  The latest changes to the script allow it to pull the list of malware
 :::  from a file called "BadProcesses.TXT" found in the standard INPUT dir,
 :::  and also makes a TEST (/T) parameter available for script diagnostics.
 :::
 :::  As of v2.7.0, this script can perform a lookup of the subnet that the
 :::  suspect system is from the list contained in "NetworkSegments.TXT"
 :::  found in the standard INPUT dir.  Currently, for the purpose of
 :::  establishing the current subnet, the IP Address is assumed to be the
 :::  system identification that was input at the command line.
 :::
 :::  As of v2.9.0, this script will attempt to compare currently running
 :::  services against a list of known services for the environment as found
 :::  in the "KnownServices.TXT" file.  This is less reliable than the search
 :::  for malware processes, but can help in isolating a suspect service from
 :::  a long list of installed services.
 :::
 :::  As of v3.4.0, this script will ignore any entries in the known services
 :::  input file ("KnownServices.TXT") that begin with a semicolon.  This
 :::  allows you to keep track of entries that you might otherwise not want to
 :::  to eliminate from your analysis.
 :::
 :::  This script can be set to obtain its SMTP configuration options via
 :::  the \Scripts\Bat\Input\CustomVariables.TXT file.  Or, if you choose, you
 :::  can modify the script directly to set the mail-related variables.  This
 :::  will reduce the number of files needed to operate the script, but using
 :::  the CustomVariables.TXT file makes it easier to manage custom configs.
 :::
 :::  (Nov 2010) Changed the default log extension of the reports from .LOG to
 :::  .TXT so that the reports that are mailed to mobile devices can be read
 :::  automatically. (Not too many devices can natively handle .LOG files)
 :::
 :::  (Jul 2011) Added a minor FOR loop using the -AcceptEula parameter in
 :::  order to accept various SysInternals utilities before the time of the
 :::  actual command execution occurs.
 :::
 :::  (Feb 2013) v4.0 -- Added the following options via new command-line
 :::  parameters: /D for DNS custom DNS server, /U for username, /P for
 :::  password.  /P must be used with /U.
 :::
 :::  (Apr 2013) v4.5 -- A new INPUT file ("ValidSecTools.TXT") was added,
 :::  containing a list of valid anti-malware and patch management apps that
 :::  might be installed on a target system, beyond whatever app is currently
 :::  designated as the preferred tool in CustomVariables.TXT
 :::
 :::  (Oct 2013) v4.6 -- The delimiter for all parameters can be either the
 :::  "-" or the "/" character.  This includes the help parameters.
 :::
 :::  (Apr 2014) v5.0 -- Added an OS detection routine near the beginning of
 :::  the scanning, so that this information is available early on.
 :::  -- Upgraded the DebugMode options with another mode (@PRINT_IF_DEBUG).
 :::  -- Added parameter to force a full scan (/F), even without admin access
 :::  -- Added the capability to send log data to one or more Syslog servers
 :::  using the SyslogGen or NeoLog utilities in conjunction with the @SYSLOGx
 :::  environment variables.
 :::
 :::  (Nov 2014) v5.2 -- Log files are now compressed before emailing, in
 :::  order to reduce attachment size.
 :::
 :::  (Jan 2015) v6.0 -- Updated to use timestamped logfiles, managed with the
 :::  new logfile maintenance routine.
 :::
 :::  (Jul 2015) v6.4 -- Now identifies user logon sessions and associated
 :::  running processes using LogonSessions from SysInternals.  Now scans for
 :::  Rootkits, Bootkits and other malware using TDSSKiller from Kaspersky.
 :::
 :::  (Nov 2015) v6.5 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Apr 2016) v6.7 -- Changed all instances of @RECIPIENTS to @RCPT-TO to
 :::  be consistent with all other scripts.
 :::
 :::  (May 2016) v6.8 -- The local "KnownServices-Custom.TXT" file is now
 :::  supported in addition to the global "[KnownServices.TXT]" file.
 :::
 :::  (Nov 2017) v7.0 -- Apply default parameters for SysInternals Tools;
 :::  Implement FNR to clean up the output of any files with the \x00 character
 :::  (a Unicode space) embedded in them;
 :::
 :::  (Mar 2018) v7.1 -- Changed the HELP routine to use FINDSTR;
 :::  -- Added new Filtered CMD Title and Syntax Help processing routines;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v7.3 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::  -- Support for NeoLogger has been eliminated from this script;
 :::
 :::  (Oct 2018) v7.4 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Dec 2018) v8.0 -- Eliminated PSEXEC calls if running on local host;
 :::  -- Corrected "--host-timeout" parameter in the nMap routine;
 :::  -- Replaced extended UPTIME.EXE report with UPTIME2.EXE equivalent;
 :::  -- Convert AUTORUNSC output from Unicode to ASCII;
 :::  -- Changed the "LISTDLLS -v" command to only run on remote systems.
 :::
 :::  (Mar 2019) v8.2 -- Enabled Code Page 1252 Support;
 :::  -- Streamline environment variable usage;
 :::
 :::  (Oct 2019) v8.3 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Jan 2020) v8.4 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Added a routine for validating integer parameters;
 :::  -- Refactored the :Prepare4Syslog routine;
 :::
 :::  (May 2020) v8.5 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::
 :::  (Jun 2020) v8.6 -- Add Routine to obtain randomized/personalize ID for
 :::  service names on Win10/Server2016+ systems;
 :::
 :::  (Nov 2020) v8.7 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Jul 2021) v9.0 -- Updated routine for enabling Remote Registry;
 :::  -- Add option to search for a list of potential suspicious IP addresses;
 :::
 :::  (Sep 2021) v9.1 -- Expand OS/CPU capture to include Total RAM;
 :::
 :::  (Jan 2022) v9.2 -- Eliminated the use of FNR with BrainWave Readable v2.0;
 :::
 :::  (Oct 2023) v9.3 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (May 2024) v9.4 -- Check for essential utilities with FINDFILES;
 :::
 :::  (Jun 2024) v9.5 -- Revamp :LogInfo routines for process logging;
 :::  -- Process and format AUTORUNSC and TDSSKILLER output via READABLE;
 :::  -- Strip Excess Errors from Main Log, But Capture in New Zipped @BIGLOG;
 :::
 :::  (Jul 2024) v9.6 -- Replaced the :RunCMD routine with just a CALL command;
 :::
 :::  (Feb 2025) v9.7 -- Replaced COMPINFO with MiTec System Info X
 :::  to get around the constant process crashes of COMPINFO;
 :::
 :::  (Sep 2025) v9.8 -- Replaced instances of HEAD/TAIL/TYPE with READABLE;
 :::
 :::
 :::  SCRIPTING SYNTAX RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  https://ss64.com/ .......... CMD and Powershell syntax
 :::  https://www.dostips.com/ ... Windows Shell Scripting Tips
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 26 May 2020 / 30 Mar 2018
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 29 Sep 2025 / 01 Feb 2025 / 11 Sep 2024 / 20 Jun 2024
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v9.8.0.1980

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Main Variables
 SET @ALL_PARAMS=%*
 SET @DELAY=120
 SET @DEFAULT=N
 SET @FULLSCAN=FALSE
 SET @SETEULA=%~dp0SetEULA.BAT
 SET @RUNKEY=Software\Microsoft\Windows\CurrentVersion
 SET @EXEMPT=AUTHORITY %USERNAME% %COMPUTERNAME% SMSCliSvcAcct Error: locally: HKEY_USERS
 SET @SCRIPTUTILS=%SystemDrive%\Scripts\Utils
 SET @NMAP_DIRS="%SystemDrive%\Nmap";"%SystemDrive%\Programs\NMap";"%ProgramFiles%\Nmap";"%ProgramFiles(x86)%\Nmap"
 SET @SPECIALP=CSRSS SVCHOST W3WP DLLHOST EXPLORER IEXPLORE CHROME FIREFOX MSEDGE BRAVE OPERA SAFARI
 SET @PSTOOLS-R=AUTORUNSC HANDLE LISTDLLS LOGONSESSIONS TCPVCON
 SET @PSTOOLS=%@PSTOOLS-R% PSEXEC PSFILE PSINFO PSLIST PSLOGGEDON PSLOGLIST PSSERVICE
 SET @REMOTE-UTILS=%@PSTOOLS-R% TDSSKILLER DATEINFO
 SET @BW_PARAMS=--Script-Variables --No-Symbols
 SET @BW_SEARCH=@OS @WIN @CPU @PHY _CORE THREADS @TOTAL_RAM @REBOOT_ @NEEDS_ @SERIAL
 SET @CHECKSVC="CaptureService" "Clipboard User Service"
 SET @EXTRANEOUS="servicefp-  SF-Port  SF: ^The.parameter.is.incorrect.  ^Error opening."

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT" READABLE.EXE
 SET #MSUTILS=AT CHOICE CMD NET NOTEPAD PING REG SC SCHTASKS TRACERT UPTIME XCOPY
 SET #3_PARTY=BLAT SYSLOGGEN ZIP
 SET #O_UTILS=7Z NMAP %@PSTOOLS% RESOLVE UPTIME2 WHOSIP TDSSKILLER RMTSHARE SRVINFO LOCAL GETSYS
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#3_PARTY% -o %#O_UTILS%
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Determine IP Subnet Location
 SET @SEGMENTS=%~dp0Input\NetworkSegments.TXT
 SET @RANGE=*** An Unknown/Undocumented Subnet Range ***
 SET @DNSSERVER=

 rem -- Generate Malware Process/Service Lists
 SET @MY_PATCHMGMT=wuauserv
 SET @MY_ANTIVIRUS=Windows Defender Antivirus Service
 SET @SUSPICION=LIKELY to be
 SET @BAD_PROCESS=%~dp0Input\[BadProcesses].TXT
 SET @GOOD_SERVICE=%~dp0Input\[KnownServices].TXT
 SET @GOOD_SERVICE2=%~dp0Input\KnownServices-Custom.TXT
 SET @SECTOOLS=%~dp0Input\[ValidSecTools].TXT
 SET @UNAUTH=& FOR /F %%M IN ('TYPE "%@BAD_PROCESS%"') DO SET @UNAUTH=!@UNAUTH! %%M
 SET @AV_LIST=
 SET @PM_LIST=& FOR /F "SKIP=2 USEBACKQ TOKENS=1* DELIMS=,; " %%L IN ("%@SECTOOLS%") DO (
	 IF /I "%%~L"=="ANTI-MALWARE" SET @AV_LIST=!@AV_LIST! "%%~M"
	 IF /I "%%~L"=="PATCH_MANAGEMENT" SET @PM_LIST=!@PM_LIST! "%%~M"
 )

 rem -- Determine the Computer Name and its IP Address and Subnet Range
 ECHO  Probing %~1 for malware
 ECHO:
 ECHO %~nx0 - Identifying Remote System Name/IP - Please Wait...
 SET @UNKNOWN=%~1& IF "%~1"=="" SET @UNKNOWN=%COMPUTERNAME%
 SET @UNKNOWN=%@UNKNOWN:\=%
 FOR /F "TOKENS=*" %%I IN ('RESOLVE %@UNKNOWN%') DO SET @OTHERID=%%I& IF "!@OTHERID!"=="" SET @OTHERID=%@UNKNOWN%
 FOR %%Z IN ("%@UNKNOWN%" "%@OTHERID%") DO CALL :DetermineSubnet %%Z

 rem -- Anti-Malware Resources (Can Be Overridden By CustomVariables.TXT)
 SET @RESOURCE1=http://en.wikipedia.org/wiki/Rootkit
 SET @RESOURCE2=http://www.avast.com/c-rootkit
 SET @RESOURCE3=http://www.sophos.com/products/free-tools/sophos-anti-rootkit.html
 SET @RESOURCE4=http://www.malwarebytes.com/antirootkit/
 SET @RESOURCE5=http://support.kaspersky.com/us/viruses/disinfection/5350
 SET @RESOURCE6=http://www.veracode.com/security/rootkit
 SET @RESOURCE7=http://www.mcafee.com/us/downloads/free-tools/rootkitremover.aspx
 SET @RESOURCE8=http://labs.bitdefender.com/projects/rootkit-remover/rootkit-remover/

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- If Running Against the Local System, Do Not Execute PSEXEC commands
 SET "@LOCALSYS=TRUE"
 SET "@PSEXEC1="
 SET "@PSEXEC2="
 IF /I NOT "%@UNKNOWN:\=%"=="%COMPUTERNAME%" (
	  SET "@LOCALSYS=FALSE"
	  SET "@PSEXEC1=PSEXEC               \\%@UNKNOWN% -n 15 "
	  SET "@PSEXEC2=PSEXEC               \\%@UNKNOWN% -n 15 cmd /c "
 )

 rem -- Set READABLE Variables for LogInfo routine
 SET @REPLACE=%TEMP%\%@GUID%
 SET @FILTER0=-a -e -r "%@REPLACE%"
 SET @FILTER1=%@FILTER0% --sa " AM; PM" --sb "HKCU;HKLM"
 SET @FILTER2=%@FILTER0% --sa ","
 SET @FILTER3=%@FILTER0% --sa " - ok\n" -x
 ECHO ÿþ;>"%@REPLACE%"

 rem -- Standard Zip Variables
 SET @ZIPPATH=%@STORAGE%\Logs\ZipFiles
 SET @ARCHIVE=%@ZIPPATH%\%COMPUTERNAME%-%~n0-%@UNKNOWN%.%@ZIPSTAMP%

 rem -- Special Log Variables
 SET @SCANTEMP=SCANTEMP.%@FILESTAMP%
 SET @REMOTE_LOG=%%WINDIR%%\Temp\%@SCANTEMP%
 SET @REMOTE_UNC=\\%@UNKNOWN%\Admin$\Temp\%@SCANTEMP%

 rem -- Standard Log Variables
 SET @LOGHEADER=Remote Forensics Log -- [Generated by %@VER% on %@TIMESTAMP%]
 SET @LOGPATH=%@STORAGE%\Logs\Forensics
 SET @LFORMAT=%@LOGPATH%\%~n0-%@UNKNOWN%
 SET @TIMINGS=%@LFORMAT%.RECORDING.TXT
 SET @LOGFILE=%@LFORMAT%.%@FILESTAMP%
 FOR %%L IN (SUSPECT SUMMARY TEMPLOG BIGLOG) DO SET @%%L=%@LFORMAT%.%%L.%@FILESTAMP%
 SET @LOGLIST="%@LOGFILE%" "%@SUSPECT%" "%@SUMMARY%"
 SET @CLEANUP="%@TEMPLOG%" "%@SUSPECT%" "%@SUMMARY%" "%@BIGLOG%" "%@REMOTE_LOG%" "%@REMOTE_UNC%"

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "Q QUIET" & IF DEFINED @OK (SET @QUIET=TRUE&    SET @NOTICE=!@NOTICE! No Summary Log;)
 CALL :GetParams "Y YES"   & IF DEFINED @OK (SET @DEFAULT=Y&     SET @NOTICE=!@NOTICE! Default to Sending Mail;&     SET @DELAY=30)
 CALL :GetParams "N NO"    & IF DEFINED @OK (SET @DEFAULT=N&     SET @NOTICE=!@NOTICE! Default to NOT Sending Mail;& SET @DELAY=120)
 CALL :GetParams "M MAIL"  & IF DEFINED @OK (SET @MAIL=TRUE&     SET @NOTICE=!@NOTICE! Ask to Send Mail;)
 CALL :GetParams "T TEST"  & IF DEFINED @OK (SET @TESTRUN=TRUE&  SET @NOTICE=!@NOTICE! Debug Mode;&                  SET @EULA=SKIP& SET @RCPT-TO=%@TEST-RCPTS%& SET @SUBJECT=**TEST** %@SUBJECT%)
 CALL :GetParams "S SHORT" & IF DEFINED @OK (SET @SHORTLOG=TRUE& SET @NOTICE=!@NOTICE! Summary Log Enabled;&         SET @EULA=SKIP)
 CALL :GetParams "E EULA"  & IF DEFINED @OK (SET @EULA=SKIP&     SET @NOTICE=!@NOTICE! Skip SysInternal EULA Config;)
 CALL :GetParams "F FULL"  & IF DEFINED @OK (SET @EULA=SKIP&     SET @NOTICE=!@NOTICE! Skip SysInternal EULA Config;)

 CALL :GetParams "V VIRUS"  @XTRA & IF DEFINED @OK IF DEFINED @XTRA (
	 SET @V_ALARM=TRUE
	 SET @NOTICE=!@NOTICE! Virus Report Enabled;
	 SET @VIRUSINFO=ECHO The suspected virus is called: !@XTRA:_= !
 )

 CALL :GetParams "I IPADDR" @XTRA & IF DEFINED @OK IF DEFINED @XTRA (
	 SET @NOTICE=!@NOTICE! Suspect IP Addresses Searched;
	 SET @IPLIST=!@XTRA: =;!
	 SET @IP_INFO=ECHO Checking for the following IP Addresses: !@IPLIST!
 )

 CALL :GetParams "C CPORT"  @XTRA & IF DEFINED @OK IF DEFINED @XTRA (
	 SET @NOTICE=%@NOTICE% Port Info Available;
	 SET @PORTINFO=ECHO Suspicious traffic was detected using !@XTRA:_= !
 )

 CALL :GetParams "D DNS"    @XTRA & IF DEFINED @OK IF DEFINED @XTRA (
	 SET @NOTICE=%@NOTICE% Use Custom DNS Server;
	 SET @DNSSERVER=!@XTRA!
	 SET @NMAP_DNS=--dns-servers !@XTRA!
 )

 CALL :GetParams "P PWD"    @XTRA & IF DEFINED @OK IF DEFINED @XTRA (
	 SET @NOTICE=%@NOTICE% Use Custom Password;
	 SET @PASSWORD=!@XTRA!
 )

 CALL :GetParams "U USER"   @XTRA & IF DEFINED @OK IF DEFINED @XTRA (
	 SET @NOTICE=%@NOTICE% Use Custom Username;
	 SET @USERNAME=!@XTRA!
 )

 rem -- Key Variable Verification
 FOR %%V IN (MAILSERVER MAILSENDER RECIPIENTS SUBJECT LOGHEADER) DO IF NOT DEFINED @%%~V (
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
	 GOTO :HelpMessage
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Determine Correct nMap Folder
 rem === Updated On: 27 Apr 2006
 rem ==========================================================================
:GetNMapFolder
 SET @NMAP=
 FOR %%F IN (%@NMAP_DIRS%) DO IF EXIST "%%~F" (
	 SET @NMAP=%%~F
	 PATH !PATH!;%%~F
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Accept EULA for locally executed SysInternals utilties
 rem === Updated On: 29 Apr 2018 / 20 Jul 2011
 rem ==========================================================================
:AcceptEULA
 ECHO Accepting EULA for local SysInternals Utilities...
 FOR %%S IN (%@PSTOOLS%) DO %%~S %@PSACCEPT% -? >NUL 2>NUL
 ECHO:
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Attempt to Connect with Custom Credentials, If Provided
 rem === Updated On: 19 Feb 2013
 rem ==========================================================================
:CustomCredentials
 IF DEFINED @USERNAME IF DEFINED @PASSWORD (
	 ECHO %~nx0 - Trying to Connect Using Custom Credentials - Please Wait...
	 NET USE \\%@UNKNOWN% /USER:%@USERNAME% %@PASSWORD%
 ) ELSE (
	 ECHO Could Not Use Custom Credentials -- NO Password Provided
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Determine If System Is Pingable, And Prompt To Continue If Blocked
 rem === Updated On: 07 Jul 2021 / 01 Jun 2020 / 19 Jan 2015
 rem ==========================================================================
:VerifyAvailability
 ECHO %~nx0 - Trying to Reach Remote System [%@UNKNOWN%] via PING - Please Wait...
 FOR /F "TOKENS=2 DELIMS=()%%" %%V IN ('PING -n 2 %@UNKNOWN% ^| FIND /I "loss"') DO IF "%%~V"=="100" (
	 ECHO:
	 ECHO PING Failed.  System May Be Unavailable Or Firewall May Be Enabled...
	 ECHO:
	 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
		 CHOICE /C YNQEX /T 20 /D N /N /M "Continue running this script? (Y/N/Q) "
		 IF ERRORLEVEL 2 GOTO :ExitBatch
	 )
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Obtain As Much Forensics Info As Possible
 rem === Updated On: 01 Feb 2025 / 14 Jul 2024 / 10 Jun 2024 / 31 Dec 2021
 rem ==========================================================================
:GetForensics
 FOR %%L IN ("%@LOGPATH%" "%@ZIPPATH%") DO IF NOT EXIST "%%~L" MD "%%~L"
 PUSHD %@SCRIPTUTILS%
 CALL :GetTime @STIME
 CALL :Notification Script Options: %@NOTICE%

 ECHO Attempting To Obtain Detailed Forensics Info...
 ECHO:
 ECHO The Complete Report can take between 5 and 30 minutes to complete
 ECHO depending on a variety of factors, such as level of access, distance
 ECHO of remote network, number of relevant records, speed of host, etc...
 ECHO:
 ECHO A preliminary report should be availabile in less than 3 minutes...
 ECHO:
 ECHO Please Standby...
 ECHO:
 CALL :SpecialInfo

 ( rem -- Create Initial Log Headers...
	 ECHO %@LOGHEADER%
	 CALL :Notification Script Options: %@NOTICE%
 ) >"%@LOGFILE%"

 rem -- Copy/Update Forensics Tools to Remote System...
 CALL :SectionInfo "Copy/Update Remote Forensics Tools"
 FOR %%C IN (%@REMOTE-UTILS%) DO (
	 ECHO  Copying %%C.EXE to Remote System...
	 XCOPY %@SCRIPTUTILS%\%%C.EXE \\%@UNKNOWN%\ADMIN$ /D /Y >NUL
 )

 rem -- Run nMap from the nMap folder, then return  (Basic Version)
 CALL :SectionInfo "Capture Basic Network Info..."
 PUSHD "%@NMAP%"
 CALL :LogInfo  "NMAP -O -Pn -F -sS     %@UNKNOWN%"
 POPD

 rem -- Attempt To Capture Network Info for Forensics... (Name/IP Info)
 CALL :LogInfo  "RESOLVE                %@UNKNOWN%" "ECHO Network Segment: %@RANGE%"
 CALL :LogInfo  "NSLOOKUP               %@UNKNOWN%  %@DNSSERVER%"
 CALL :LogInfo  "NSLOOKUP              '%@OTHERID%' %@DNSSERVER%"
 CALL :LogInfo  "WHOSIP                 %@UNKNOWN%"
 CALL :LogInfo  "WHOSIP                 %@OTHERID%"
 CALL :LogInfo  "PING                   %@UNKNOWN%"
 CALL :LogInfo  "NET VIEW             \\%@UNKNOWN%"
 CALL :LogInfo  "UPTIME               \\%@UNKNOWN%"

 rem -- If Admin Access Is Not Available, Abort Execution of Additional Forensics
 CALL :VerifyAccess %@UNKNOWN%
 IF NOT DEFINED @ACCESSIBLE IF /I NOT "%@FULLSCAN%"=="TRUE" GOTO :FinishLog

 rem -- Start "Remote Registry" service on %@UNKNOWN% if not running
 CALL :SectionInfo "Enable Remote Registry if Possible..."
 FOR /F "TOKENS=4" %%S IN ('SC \\%@UNKNOWN% QUERY "RemoteRegistry" ^| FIND "STATE"') DO (
	 IF NOT "%%~S"=="RUNNING" (
		 ECHO Starting Remote Registry Service on %@UNKNOWN%...
		 SC \\%@UNKNOWN% CONFIG RemoteRegistry start= AUTO
		 SC \\%@UNKNOWN% START RemoteRegistry
		 ECHO:
	 ) ELSE (
		 ECHO Remote Registry Service already running on %@UNKNOWN%...
		 ECHO:
	 )
 )

 rem -- Attempt To Capture Application Info for Forensics... (Processes and Services)
 CALL :SectionInfo "Capture Process/Service Info..."
 CALL :FindValidTools
 CALL :FindBadProcesses
 CALL :LogInfoF "PSSERVICE            \\%@UNKNOWN% QUERY -S active" "%@MY_PATCHMGMT%" @PATCHMGMT "*** DOES NOT APPEAR TO BE RUNNING ***"
 CALL :LogInfoF "PSSERVICE            \\%@UNKNOWN% QUERY -S active" "%@MY_ANTIVIRUS%" @ANTIVIRUS "*** DOES NOT APPEAR TO BE RUNNING ***"
 CALL :LogInfo  "%@PSEXEC1%NET START"
 CALL :LogInfo  "PSLIST               \\%@UNKNOWN%"

 rem -- Attempt to Capture Information Related to Specific Processes...
 FOR %%P IN (%@SPECIALP%) DO (
	 CALL :LogInfo  "PSLIST               \\%@UNKNOWN% %%P"
 )

 rem -- Attempt To Capture User & System Specific Information...
 CALL :SectionInfo "Capture User and Operating System Info..."
 CALL :LogInfoF "PSLOGGEDON -L        \\%@UNKNOWN%" "\" @LOGGEDON
 CALL :LogInfo  "%@PSEXEC1%LOGONSESSIONS -p %@PSPARAMS%"
 CALL :LogInfo  "CALL :Get-DATEINFO   \\%@UNKNOWN%"
 CALL :LogInfoF "PSINFO               \\%@UNKNOWN%" "version:"
 CALL :LogInfo  "%@PSEXEC2%'VER'"
 CALL :LogInfoF "SRVINFO              \\%@UNKNOWN%" "Build:" @OSBUILD
 CALL :LogInfoF "PSLOGLIST            \\%@UNKNOWN% -H 2 -S SECURITY" "fail "

 rem -- Show Abbreviated Report Unless Quiet Mode Is Invoked...
 IF NOT "%@QUIET%"=="TRUE" (
	 FOR %%O IN (CON %@LOGFILE%) DO CALL :Notification Displaying Abbreviated Forensics Report... >>%%O 2>&1
	 START NOTEPAD "%@LOGFILE%"
	 SLEEP 5
 )

 rem ----------------------------------------------------------------------------------------------
 rem -- Skip Core/Extended Forensics if the /TEST or /T parameters are set at the command line
 IF /I "%@TESTRUN%"=="TRUE" GOTO :FinishLog

 rem -- Make an Attempt to Pre-Accept the SysInternals EULA
 IF NOT "%@EULA%"=="SKIP" (
	 ECHO Configuring SysInternals EULA Approvals...  Please Wait...
	 ECHO:
	 ECHO NOTE: It Could Take Up To 20 Minutes To Run On Systems Across The WAN...
	 ECHO:
	 CMD /C "%@SETEULA%" %@UNKNOWN% >NUL 2>NUL
	 ECHO:
 )

 rem -- Accept the EULA for SysInternals Utilities on Remote System
 FOR %%S IN (%@PSTOOLS-R%) DO %@PSEXEC1% %%~S %@PSACCEPT% -? >NUL 2>NUL

 rem -- Get OS Info and CMD Variables
 CALL :LogInfo  "%@PSEXEC1%DATEINFO --Script-Variables"

 rem -- Continue With Remote Forensics Data...  (Core Networking Forensics Info)
 CALL :LogInfo  "TRACERT -d -h 15       %@UNKNOWN%"
 CALL :LogInfo  "%@PSEXEC1%LOGONSESSIONS -p %@PSPARAMS%"
 CALL :LogInfo  "%@PSEXEC1%NETSTAT -ano"
 CALL :LogInfo  "%@PSEXEC1%TCPVCON -a %@PSACCEPT%"
 CALL :LogInfo  "%@PSEXEC1%NETSTAT -s"
 CALL :LogInfo  "%@PSEXEC1%NBTSTAT -n"
 CALL :LogInfo  "%@PSEXEC1%NBTSTAT -c"
 CALL :LogInfo  "%@PSEXEC1%NBTSTAT -s"
 CALL :LogInfo  "%@PSEXEC1%NBTSTAT -S"
 CALL :LogInfo  "%@PSEXEC1%GETSYS /so /ld /na /la /id /usb"
 CALL :LogInfo  "PSINFO -s            \\%@UNKNOWN%"
 CALL :LogInfo  "SRVINFO -s           \\%@UNKNOWN%"
 CALL :LogInfo  "PSSERVICE            \\%@UNKNOWN% config"
 CALL :FindSuspectIPs

 rem ----------------------------------------------------------------------------------------------
 rem -- Skip Extended Forensics if the /S or /SHORT parameters are set at the command line
 IF /I "%@SHORTLOG%"=="TRUE" (
	 SET @SUBJECT=%@SUBJECT% [SUMMARY]
	 GOTO :FinishLog
 )

 rem -- Attempt to Capture Extended Info on Specific Processes...  (PSLIST)
 FOR %%X IN (-t -m -x) DO FOR %%P IN (%@SPECIALP%) DO (
	 CALL :LogInfo  "PSLIST %%~X            \\%@UNKNOWN% %%~P"
 )

 rem -- Continue With Remote Forensics Data...  (Extended File and Process Info)
 CALL :LogInfo  "PSLIST -t            \\%@UNKNOWN%"
 CALL :LogInfo  "PSLIST -m            \\%@UNKNOWN%"
 CALL :LogInfo  "PSLIST -x            \\%@UNKNOWN%"

 CALL :LogInfo  "UPTIME /P:30 /A      \\%@UNKNOWN%"
 CALL :LogInfo  "UPTIME2  /COMPUTERNAME:%@UNKNOWN% /NOLOGO /S"
 CALL :LogInfo  "PSINFO -h -d         \\%@UNKNOWN%"
 CALL :LogInfo  "%@PSEXEC1%IPCONFIG /ALL"
 CALL :LogInfo  "%@PSEXEC1%ROUTE -p PRINT"

 rem -- Attempt to Capture Extended Info on Specific Processes...  (HANDLE)
 FOR %%P IN (%@SPECIALP%) DO (
	 CALL :LogInfo  "%@PSEXEC1%HANDLE %@PSPARAMS% -p %%~P"
 )

 CALL :LogInfo  "%@PSEXEC1%HANDLE %@PSPARAMS% -s"
 CALL :LogInfo  "%@PSEXEC1%HANDLE %@PSPARAMS% -a" "COPY %@LOGFILE% %@BIGLOG% /Y"
 CALL :LogInfo  "%@PSEXEC1%LISTDLLS %@PSPARAMS%"& IF /I "%@LOCALSYS%"=="FALSE" CALL :LogInfo  "%@PSEXEC1%LISTDLLS %@PSPARAMS% -v"
 CALL :LogInfo  "%@PSEXEC2%'SET'"
 CALL :LogInfo  "TYPE                 \\%@UNKNOWN%\Admin$\System32\Drivers\Etc\HOSTS.*"
 CALL :LogInfo  "TYPE                 \\%@UNKNOWN%\Admin$\System32\Drivers\Etc\LMHOSTS.*"
 CALL :LogInfo  "RMTSHARE             \\%@UNKNOWN%"
 CALL :LogInfo  "PSFILE               \\%@UNKNOWN%"

 rem -- Run nMap from the nMap folder, then return  (Extended Version)
 PUSHD "%@NMAP%"
 CALL :LogInfo  "NMAP -A -v -Pn %@NMAP_DNS% --host-timeout 300s --version-intensity 7 %@UNKNOWN%"
 POPD

 rem -- Continue With Remote Forensics Data...  (Security Info)
 CALL :LogInfo  "LOCAL Administrators \\%@UNKNOWN%"
 CALL :LogInfo  "PSLOGGEDON           \\%@UNKNOWN%"
 CALL :LogInfoF "PSLOGLIST            \\%@UNKNOWN% -D 2 -S SECURITY" "fail "
 CALL :LogInfo  "AT                   \\%@UNKNOWN%"
 CALL :LogInfo  "SCHTASKS /QUERY /S   \\%@UNKNOWN%"
 CALL :LogInfo  "%@PSEXEC1%AUTORUNSC %@PSPARAMS% -a *" "" @FILTER1
 CALL :LogInfo  "%@PSEXEC1%AUTORUNSC %@PSPARAMS% -c  " "" @FILTER2
 CALL :LogInfo  "REG QUERY            \\%@UNKNOWN%\HKLM\%@RUNKEY%\Run"
 CALL :LogInfo  "REG QUERY            \\%@UNKNOWN%\HKLM\%@RUNKEY%\RunOnce"


 rem ==========================================================================
 rem === Get Run/RunOnce Data For All Currently LoggedOn Users
 rem === Updated On: 14 Jul 2010 / 11 Oct 2005
 rem ==========================================================================
:GetUserSID
 FOR /F "TOKENS=2 DELIMS=\" %%R IN ('REG QUERY \\%@UNKNOWN%\HKU ^| FIND /I "S-1-5-21" ^| FIND /V /I "classes"') DO (
	 CALL :LogInfo  "REG QUERY            \\%@UNKNOWN%\HKU\%%~R\%@RUNKEY%\Run"
	 CALL :LogInfo  "REG QUERY            \\%@UNKNOWN%\HKU\%%~R\%@RUNKEY%\RunOnce"
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Scan for Rootkit/Bootkit
 rem === Updated On: 11 Jun 2024 / 10 Jan 2022 / 04 Dec 2018
 rem ==========================================================================
:RootkitScanner
 CALL :SectionInfo "Run Rootkit/Bootkit Scanner..."
 CALL :LogInfo "%@PSEXEC1%TDSSKILLER -AcceptEula -AcceptEulaksn -dcexact -sigcheck -tdlfs -silent -l %@REMOTE_LOG%"
 SLEEP 3
 COPY "%@REMOTE_UNC%" "%@TEMPLOG%" /Y
 READABLE %@TEMPLOG% %@FILTER3% >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Close Out Forensic Log Files and Remove Extraneous Lines in Main Log
 rem === Updated On: 11 Jun 2024 / 10 Jan 2022 / 24 Nov 2017
 rem ==========================================================================
:FinishLog
 CALL :SectionInfo "Performing Log Maintenance..."
 FINDSTR /I /V /R %@EXTRANEOUS% "%@LOGFILE%" >"%@TEMPLOG%"
 SLEEP 3
 COPY "%@TEMPLOG%" "%@LOGFILE%" /Y

 CALL :GetTime @ETIME
 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER-:~-75%
	 ECHO  Forensics Started On .......................... %@STIME%
	 ECHO  Forensics Ended On ............................ %@ETIME%
	 DATEINFO -t !@STIME#! -n !@ETIME#! -e "dys hrs mins secs.ms" -o " Total Job Duration Was ........................ " 2>NUL
	 ECHO:
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Display Full Log
 rem === Updated On: 29 Sep 2025 / 11 Jun 2024 / 19 Jan 2015 / 08 May 2014
 rem ==========================================================================
:ShowLogs
 DIR "%@LOGFILE%"
 READABLE "%@LOGFILE%" --ST 26 --EN -5 --RD TRUE
 IF /I NOT "%@QUIET%"=="TRUE" START "Forensics Info" "%@LOGFILE%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Mail Log File To Virus Mitigation Team (after waiting for 30 seconds)
 rem === Updated On: 11 Jun 2024 / 25 Apr 2016 / 19 Jan 2015
 rem ==========================================================================
:MailLogs
 CALL :Notification Script Options: %@NOTICE%

 ( rem -- Compress Logs Before Sending Email
	 ECHO %@DIVIDER-%
	 PUSHD "%@LOGPATH%"
	 ZIP -9 -v -T -j  %@ARCHIVE% %@LOGFILE% %@BIGLOG%
	 POPD
	 ECHO:
	 ECHO Job Logs Compressed -- [!DATE! at !TIME!]
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1

 IF /I "%@MAIL%"=="TRUE" IF DEFINED @RCPT-TO (
	 ECHO:
	 CHOICE /C YNQ /T %@DELAY% /D %@DEFAULT% /N /M "Do You Wish To Send Mail? "
	 IF !ERRORLEVEL! EQU 1 (
		 CALL :SendMail "%@SUMMARY%"
		 ECHO:
		 ECHO:
		 ECHO Mailing Logs To: %@RCPT-TO:-to=%
		 ECHO:
		 BLAT -install %@MAILSERVER% %@MAILSENDER% 5 %@MAILPORT%
		 BLAT "%@SUMMARY%" %@RCPT-TO% -s "%@SUBJECT%" -attach "%@ARCHIVE%"
		 ECHO:
		 ECHO:
		 CALL :ForwardToSyslog "6" Mailed Forensics Log about "%@SUBJECT%" to %@RCPT-TO:-to=% -- "%@LOGFILE%"
	 )
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
 rem === Remove Forensics Tools from Remote System
 rem === Updated On: 11 Jun 2024 / 26 Jul 2015 / 28 Jan 2015
 rem ==========================================================================
:CleanUpExe
 CALL :SectionInfo "Cleaning Up Remote Forensics Tools"
 FOR %%C IN (%@REMOTE-UTILS%) DO (
	 ECHO  Removing %%C.EXE from Remote System...
	 DEL \\%@UNKNOWN%\ADMIN$\%%~C.EXE >NUL
	 ECHO:
 )
 CALL :ForwardToSyslog "5" FINISHED Scanning %@UNKNOWN% [%@OTHERID%] for Malware
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 04 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 POPD
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Send eMail Summary With Contact Info
 rem === Updated On: 14 Jul 2024 / 19 Jan 2015 / 18 Apr 2014
 rem ==========================================================================
:SendMail
 rem %1 = Logfile to Send Output To
 rem %2 = Suspect Process Logfile to Display

 ( rem -- Write to Log
	 ECHO %@LOGHEADER%
	 ECHO:
	 ECHO HELPDESK: Please create a ticket for this security incident, and reply to ALL recipients with the ticket number.
	 ECHO:
	 ECHO Current System Identification:  %@UNKNOWN% [%@OTHERID%]
	 ECHO Current System IP Range:        %@RANGE%
	 ECHO Currently Logged-on User:       %@LOGGEDON%
	 ECHO Current Windows Version/Build:  %@OSVERSION% -%@OSBUILD:Build:=%
	 ECHO:
	 %@VIRUSINFO%
	 %@PORTINFO%
	 ECHO:
	 ECHO %@DIVIDER-:~-70%
	 ECHO ^|         ^|  Before attempting to clean the system indicated above,
	 ECHO ^| SPECIAL ^|  please check REMEDY to see how many previous times this
	 ECHO ^| NOTE TO ^|  particular system has been infected.  If there have been
	 ECHO ^|   THE   ^|  any earlier infections and cleaning -- especially within
	 ECHO ^| DESKTOP ^|  the last 60 days -- you should immediately RE-IMAGE the
	 ECHO ^|  TEAMS  ^|  system, because it is extremely likely that this system
	 ECHO ^|         ^|  has been infected by an undetectable rootkit.
	 ECHO %@DIVIDER-:~-70%
	 ECHO:
	 ECHO:

	 rem -- Provide Information About Lack of Administrative Access
	 IF NOT DEFINED @ACCESSIBLE (
		 ECHO:
		 ECHO %@DIVIDER-%
		 ECHO --- Administrative Access To This System Was Denied...
		 ECHO ---
		 ECHO --- The most common reasons for this include the following:
		 ECHO ---    The system is a guest machine on our network...
		 ECHO ---    The system is not a member of any of our production domains...
		 ECHO ---    The system is running a firewall that prevents remote access...
		 ECHO ---    The system is not a Windows machine...
		 ECHO ---    This script was executed from an account with insufficient rights...
		 ECHO ---
		 ECHO --- Please access the system locally to validate all other findings.
		 ECHO %@DIVIDER-%
		 ECHO:
	 ) ELSE (
		 ECHO Patch Management Agent Status ...............: %@PATCHMGMT%
		 ECHO Host-based AntiVirus Client Status ..........: %@ANTIVIRUS%
		 ECHO:
	 )

	 rem -- Provide Generic Info About Potential State of Infection
	 IF "%@V_ALARM%"=="TRUE" (
		 CALL :ForwardToSyslog "5" Some malware is likely running on %@UNKNOWN% [%@OTHERID%]. Please initiate a scan...
		 ECHO:
		 ECHO PLEASE BE ADVISED: Our Corporate AntiVirus management console is reporting some malware on %@UNKNOWN% [%@OTHERID%], but is unable to clean or quarantine it.  Please run the standard malware cleanup utilities on the local system...
		 ECHO:
	 ) ELSE (
		 CALL :ForwardToSyslog "4" The %@UNKNOWN% [%@OTHERID%] device is %@SUSPICION% infected with malware.  Address Immediately!
		 ECHO:
		 ECHO PLEASE BE ADVISED: Our security scanners indicate that the system identified as %@UNKNOWN% [%@OTHERID%] is %@SUSPICION% affected in one or more of the following ways:
		 ECHO:
		 ECHO 	- Infected with some form of malware [spyware/virus/trojan/rootkit]
		 ECHO 	- Is running an unapproved/unauthorized network scanning application
		 ECHO 	- Is running an unapproved/unauthorized application or utility including P2P, Internet Relay Chat [IRC].
		 ECHO:
	 )

	 rem -- Provide Identification of any Discovered Suspect Processes OR Services
	 IF EXIST "%@SUSPECT%" (
		 ECHO:
		 ECHO %@DIVIDER*:~-35%
		 TYPE "%@SUSPECT%"
		 ECHO %@DIVIDER*:~-35%
	 ) ELSE (
		 ECHO:
		 ECHO  *** Could Not Identify Any Specific Malware Processes -OR- Unauthorized Application -- Please Scan For Rootkits and/or Spyware ***
		 ECHO:
		 ECHO PLEASE NOTE: Although we are unable to precisely determine the identity of the malware process[es] at this time, we have encountered several systems in the environment over the past few months that were found to be infected by Rootkits and other stealth malware for which there were no antivirus signatures at the time.  The following free tools, run in SAFE MODE, will greatly assist in detecting such forms of malware:
		 ECHO:
		 FOR /L %%R IN (1,1,9) DO IF DEFINED @RESOURCE%%R ECHO 	* !@RESOURCE%%R!
	 )

	 rem -- Provide Guidance About Attached Log Info
	 ECHO:
	 ECHO:
	 ECHO Please review the attached logfile for additional details, especially the AUTORUNS capture near the end of the log, and take the necessary steps to secure/remediate the system as soon as possible. If you are still unable to detect any infection after scanning with the anti-rootkit utilities, please coordinate with the Information Security Team before releasing the system to the user.
	 ECHO:
	 ECHO For more information about information security and risk mitigation, please see the following:
	 ECHO:
	 ECHO		* https://www.BrainWaveCC.com/blogs/category/malware/
	 ECHO:
 ) >>"%~1" 2>&1
 %@PAUSE_IF_DEBUG%
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
 rem === SUBROUTINE: Store Current 12-Hour Time in Variable
 rem === Updated On: 18 Jan 2007
 rem ==========================================================================
:GetTime12
 rem %1 = Variable to Store Time

 FOR /F "TOKENS=*" %%T IN ('TIME /T') DO SET %~1=%%~T
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Convert Multiple Spaces To Single Space
 rem === Updated On: 16 May 2005
 rem ==========================================================================
:SingleSpace
 rem %1 = New Variable Name
 rem %2 = Variable to Reduce To Single Spaces

 SET @Z=%~2
 SET @Z=%@Z:'="%& FOR /L %%S IN (1,1,100) DO SET @Z=!@Z:  = !
 SET %~1=%@Z%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Execute Process And Log Output
 rem === Updated On: 10 Jun 2024 / 07 Jul 2021
 rem ==========================================================================
:LogInfo
 rem %1 = Diagnostics Command/Utility with parameters
 rem %2 = Optional Command to Execute
 rem %3 = Optional Variable containing READABLE parameters

 CALL :GetTime12 @CTIME
 CALL :SingleSpace @MSG %1
 SET @CMD=%~1
 SET @CMD=!@CMD:'="!
 SET @CMD2=%~2

 ECHO  [%@CTIME%]: %@CMD%
 ( rem -- Write to Log
	 NOW \z \s \n \- --- [!TIME!]: %@MSG% \n \-
	 IF "%~3"=="" (
		 !@CMD! 2>NUL
	 ) ELSE (
		 !@CMD!  >"%@TEMPLOG%" 2>NUL
		 READABLE "%@TEMPLOG%" !%~3!
	 )
	 !@CMD2!
	 ECHO:
	 ECHO:
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Execute Process And Log Output w/FIND command
 rem === Updated On: 31 Dec 2021 / 08 Jul 2021/28 Jan 2015
 rem ==========================================================================
:LogInfoF
 rem %1 = Current Diagnostics Utility with Parameters
 rem %2 = Filtering Criteria of Command/Utility
 rem %3 = Variable to Store Data In
 rem %4 = Default Value of the Variable

 CALL :GetTime12 @CTIME
 CALL :SingleSpace @MSG %1
 SET @CMD=%~1
 SET @CMD=%@CMD:'="%
 SET @SETVAR=FALSE

 IF NOT "%~3"=="" IF "%~4"=="" (
	 SET %~3=***UNKNOWN***
 ) ELSE (
	 SET %~3=%~4
 )

 ECHO  [%@CTIME%]: %@CMD% ^| FIND "%~2"
 ( rem -- Write to Log
	 NOW \z \s \n \- --- [!TIME!]: %@MSG% ^| FIND \q "%~2" \q \n \-

	 FOR /F "TOKENS=*" %%A IN ('%@CMD% 2^>NUL ^| FIND "%~2" ^| FINDSTR /I /V "%@EXEMPT%"') DO (
		 SET @SETVAR=TRUE
		 SET @FOUND=%%A
		 FOR %%z IN (SERVICE DISPLAY) DO SET @FOUND=!@FOUND:%%z_NAME:=!
		 ECHO !@FOUND!
		 IF NOT "%~3"=="" SET %~3=!@FOUND!
	 )

	 IF "!@SETVAR!"=="FALSE"  IF "%~3"=="" (
		 ECHO *** COULD NOT OBTAIN INFO ***
	 ) ELSE (
		 ECHO !%~3!
	 )

	 ECHO:
	 ECHO:
 ) >>"%@LOGFILE%"
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Search For Known Malware or P2P or Suspect Services
 rem === Updated On: 07 Jul 2021 / 01 Jun 2020 / 16 May 2016
 rem ==========================================================================
:FindBadProcesses
 CALL :GetTime12 @CTIME
 SET @CMD=Searching for Known Malware Processes AND Suspect Services

 rem -- Find Randomized/Personalized Service Name Info for Win10 Services
 FOR %%S IN (%@CHECKSVC%) DO FOR /F "TOKENS=3 DELIMS=_" %%A IN ('PSSERVICE \\%@UNKNOWN% QUERY "%%~S" %@PSPARAMS% 2^>NUL ^| FIND /I "_NAME:"') DO SET @RNDACCT=%%~A

 rem -- Evaluate both Regular Service Names and New Win10 Randomized/Personalized Service Names
 FOR /F "TOKENS=1*" %%R IN ('PSSERVICE \\%@UNKNOWN% %@PSPARAMS% 2^>NUL ^| FIND /I "DISPLAY_NAME:"') DO (
	 SET @SUSPECTSVC=TRUE
	 FOR %%F IN ("%@GOOD_SERVICE%" "%@GOOD_SERVICE2%") DO IF EXIST "%%~F" FOR /F "USEBACKQ EOL=; TOKENS=*" %%K IN ("%%~F") DO (
		 FOR %%C IN ("" "!@RNDACCT!") DO IF "%%~S"=="%%~K%%~C" SET @SUSPECTSVC=FALSE
	 )
	 IF "!@SUSPECTSVC!"=="TRUE" ( rem -- Write to Log
		 SET @SUSPICION=POTENTIALLY
		 ECHO  -- Suspect Service?  %%S??
	 ) >>"%@SUSPECT%"
 )

 FOR /F "EOL=; TOKENS=1-2" %%M IN ('PSLIST %@PSPARAMS% \\%@UNKNOWN% 2^>NUL ^| FINDSTR /I "%@UNAUTH%"') DO (
	 SET @SUSPICION=DEFINITELY
	 ECHO  -- Suspect Process: %%M [pid=%%N]
 ) >>"%@SUSPECT%"

 ECHO  [%@CTIME%]: %@CMD%
 ( rem -- Write to Log
	 NOW \z \s \n \- --- [!TIME!]: %@CMD% \n \- \n

	 IF EXIST "%@SUSPECT%" (
		 TYPE "%@SUSPECT%"
	 ) ELSE (
		 ECHO  -- Could Not Identify Any Malware Processes or Unauthorized Applications
	 )
	 ECHO:
	 ECHO:
	 ECHO: >CON
 ) >>"%@LOGFILE%" 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Search For Valid Security and Patch Management Tools
 rem === Updated On: 07 Jul 2021 / 28 Jan 2015
 rem ==========================================================================
:FindValidTools
 CALL :GetTime12 @CTIME
 SET @CMD=Searching for Running Security and Patch Management Applications
 SET @FOUND_AV=
 SET @FOUND_PM=

 ECHO  [%@CTIME%]: %@CMD%
 ( rem -- Write to Log
	 NOW \z \s \n \- --- [!TIME!]: %@CMD% \n \- \n

	 FOR /F "TOKENS=1*" %%R IN ('PSSERVICE \\%@UNKNOWN% QUERY -S active 2^>NUL ^| FIND /I "DISPLAY_NAME:"') DO (
		 FOR %%L IN (%@AV_LIST%) DO (
			 SET @COMPSTR=%%~S
			 CALL :GetStringLen %%~L
			 IF /I "%%~L"=="!@COMPSTR!" SET @FOUND_AV=!@FOUND_AV! "%%~S"
		 )

		 FOR %%L IN (%@PM_LIST%) DO (
			 SET @COMPSTR=%%~S
			 CALL :GetStringLen %%~L
			 IF /I "%%~L"=="!@COMPSTR!" SET @FOUND_PM=!@FOUND_PM! "%%~S"
		 )
	 )

	 SET @MSG=AntiMalware Services are Running
	 IF "!@FOUND_AV!"=="" (
		 ECHO  ** No !@MSG! **
		 ECHO:
	 ) ELSE (
		 ECHO  -- The Following !@MSG!
		 FOR %%L IN (!@FOUND_AV!) DO ECHO     ---- %%~L
		 ECHO:
	 )

	 SET @MSG=Patch Management Services are Running
	 IF "!@FOUND_PM!"=="" (
		 ECHO  ** No !@MSG! **
		 ECHO:
	 ) ELSE (
		 ECHO  -- The Following !@MSG!
		 FOR %%L IN (!@FOUND_PM!) DO ECHO     ---- %%~L
		 ECHO:
	 )
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Search Logfile Contents for Suspect IP Addresses
 rem === Updated On: 07 Jul 2021
 rem ==========================================================================
:FindSuspectIPs
 IF NOT DEFINED @IPLIST EXIT /B

 CALL :GetTime12 @CTIME
 SET @CMD=Searching Logfile Contents for Suspect IP Addresses: %@IPLIST:;=; %

 ECHO:
 ECHO  [%@CTIME%]: %@CMD%
 ECHO:

 ( rem -- Write to Log
	 NOW \z \s \n \- --- [!TIME!]: %@CMD% \n \- \n

	 READABLE "%@LOGFILE%" -f "%@IPLIST%" --sk "--- [" -o "%@TEMPLOG%"
	 TYPE "%@TEMPLOG%"
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Verify NetBIOS Access To Remote System
 rem === Updated On: 14 Jul 2024 / 19 Jan 2015 / 18 Apr 2014
 rem ==========================================================================
:VerifyAccess
 rem %1 = Current Server To Verify

 SET @ACCESSIBLE=TRUE
 SET @SYS=%~1& SET @SYS=\\!@SYS:\=!
 DIR %@SYS%\ADMIN$ >NUL 2>NUL
 IF ERRORLEVEL 1 (
	 ( rem -- Write to Log
		 ECHO:
		 ECHO PLEASE NOTE: Due to insufficient admin access to [%1], the scan was aborted.  Data collection will be incomplete...
		 ECHO:
	 ) >>"%@LOGFILE%"
	 ECHO:
	 ECHO PLEASE NOTE: Due to insufficient admin access to [%1],
	 ECHO              the scan was aborted. Data collection will be incomplete...
	 ECHO:
	 SET @EULA=SKIP
	 SET @LOGGEDON=*** UNABLE TO DETERMINE CURRENT USER ***
	 SET @SUBJECT=**NO ADMIN ACCESS** %@SUBJECT%
	 SET @ACCESSIBLE=
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Find Matching Subnet based on IP Address
 rem === Updated On: 17 Mar 2008 / 09 Mar 2007
 rem ==========================================================================
:DetermineSubnet
 rem %1 = Name or IP Address To Evaluate

 SET @IS_IP=TRUE

 FOR /F "TOKENS=1-4 DELIMS=./()[]" %%I IN ('ECHO %~1') DO (
	 SET @OCT1=%%I
	 SET @OCT2=%%J
	 SET @OCT3=%%K
	 SET @OCT4=%%L
	 SET @SUBNET=%%I.%%J.%%K.
 )

 FOR %%N IN ("%@OCT1%" "%@OCT2%" "%@OCT3%" "%@OCT4%") DO IF %%~N0 LSS 00 SET @IS_IP=FALSE
 FOR %%N IN ("%@OCT1%" "%@OCT2%" "%@OCT3%" "%@OCT4%") DO IF %%~N0 GTR 2550 SET @IS_IP=FALSE
 IF /I "%@IS_IP%"=="TRUE" FOR /F "TOKENS=*" %%R IN ('TYPE "%@SEGMENTS%" ^| FIND /I "%@SUBNET%"') DO SET @RANGE=%%R
 SET @RANGE=%@RANGE:(=[%
 SET @RANGE=%@RANGE:)=]%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Length of String
 rem === Updated On: 28 Jul 2024 / 03 Feb 2020 / 08 May 2014
 rem ==========================================================================
:GetStringLen
 rem %* = String to Measure

 SET @STR=%*
 SET @LEN=
 FOR /L %%C IN (0,1,399) DO IF NOT "!@STR:~%%C,1!"=="" SET /A @LEN+=1
 SET /A @NEXT=@LEN + 1
 IF DEFINED @COMPSTR CALL SET @COMPSTR=%%@COMPSTR:~0,!@LEN!%%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display Script Section Info
 rem === Updated On: 02 Dec 2013 / 09 Oct 2013
 rem ==========================================================================
:SectionInfo
 rem %1 = Message to Display

 ECHO:
 ECHO:
 ECHO %~1
 ECHO %@DIVIDER-:~-60%
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display Major Notification
 rem === Updated On: 09 Dec 2020 / 21 Jan 2020
 rem ==========================================================================
:Notification
 rem %* = Message to Display

 NOW \z \n \n \* *** %* \n \* \v \n \n ""
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Output Warning Message
 rem === Updated On: 18 Apr 2014 / 27 Mar 2007
 rem ==========================================================================
:SpecialInfo
 ECHO:
 ECHO %@DIVIDER-:~-75%
 ECHO ^| P N ^|  This script may break if all the necessary files have not been
 ECHO ^| L O ^|  downloaded and placed somewhere in your PATH.  Additionally, many
 ECHO ^| E T ^|  of the commands will only provide details if you have sufficient
 ECHO ^| A E ^|  ADMINISTRATIVE ACCESS to the remote system.  This script is to be
 ECHO ^| S   ^|  used for diagnostics or forensics purposes only, on systems for
 ECHO ^| E   ^|  which you have legitimate rights.
 ECHO %@DIVIDER-:~-75%
 ECHO:
 %@PAUSE_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from DATEINFO
 rem === Updated On: 11 Jun 2024 / 24 Sep 2021 / 01 Jun 2020
 rem ==========================================================================
:Get-DATEINFO
 rem %1 = Current System for Which Info Will be Obtained

 %@PSEXEC1% DATEINFO %@BW_PARAMS% 2>NUL | FINDSTR /I "%@BW_SEARCH%" >%@TEMPLOG% 2>NUL
 SET %~1-OSEDITION=an ** UNIDENTIFIED ** operating system
 FOR /F "TOKENS=1-2 DELIMS=@;" %%P IN ('TYPE %@TEMPLOG%') DO SET %~1-%%P=%%~Q
 IF /I "!%~1-OS_ARCH!"=="x64" (SET %~1-ARCH=[x64]& SET %~1-PLATFORM=a 64-bit Windows system)
 IF /I "!%~1-OS_ARCH!"=="x86" (SET %~1-ARCH=[x86]& SET %~1-PLATFORM=a 32-bit Windows system)

 ECHO Machine Serial# ... !%~1-SERIAL_NUM!
 ECHO OS Edition ........ !%~1-OSEDITION!
 ECHO OS Architecture ... !%~1-PLATFORM!
 ECHO CPU Name .......... !%~1-CPU_NAME!
 ECHO CPU Family ........ !%~1-CPU_FAMILY!
 ECHO CPU Sockets ....... !%~1-CPU_SOCKETS!
 ECHO Physical Cores .... !%~1-PHY_CORES!
 ECHO Logical Cores ..... !%~1-LOG_CORES!
 ECHO Physical RAM ...... !%~1-TOTAL_RAM!
 ECHO Needs a Reboot .... !%~1-NEEDS_REBOOT!	%@NEEDS_REBOOT_MSG%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Use CheckParams.exe to Capture Selected Parameters
 rem === Updated On: 21 Jan 2020 / 25 Apr 2016
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
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 13 Jan 2020 / 25 Dec 2018
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

 CALL :Prepare4Syslog %@S_MSG%

 %@VERBOSE_OFF%
 ECHO !@S_MSG!
 IF DEFINED @SYSLOG_UTIL IF /I "%@USE_SYSLOGS%"=="TRUE" FOR %%s IN ("" 0 1 2 3 4) DO IF DEFINED @SYSLOG%%~s (
	 SET @S_PORT=514& IF DEFINED @SYSLOG%%s_PORT SET @S_PORT=!@SYSLOG%%~s_PORT!
	 "%@SYSLOGGEN%" -t:!@SYSLOG%%~s! -p:!@S_PORT! -f:19 -s:!@SEV! -tg:"%~n0" -m:"!@S_MSG2!" -q -hn:%@LOCALHOST% | FIND /V "%@NO_SYSLOGGEN%"
 )
 %@PRINT_IF_DEBUG%
 IF DEFINED #DEBUG ECHO ON
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
 rem === Updated On: 07 Jul 2021 / 30 Nov 2020
 rem ==========================================================================
:HelpMessage
 ECHO Forensics Info for Remote Malware Detection Analysis
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<machine_name ^| machine_ip_address^> [OPTIONS]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO       /Q  .... Generate Log File, But Don't Open It When Script Finishes
 ECHO       /M  .... Mail Log File to Virus Mitigation Team When Completed
 ECHO       /Y  .... Default to YES for Sending Mail
 ECHO       /N  .... Default to NO for Sending Mail  (This is implied)
 ECHO       /T  .... Run Abbreviated Script and Mail to Test Recipients  (requires /M)
 ECHO       /S  .... Generate Short (abbreviated) Diagnostics Log
 ECHO       /V  .... Add A Note To Alert Report Indicating that a Virus Might Be Present
 ECHO       /C  .... Add A Note To Alert Report Indicating What Port and Protocol Information
 ECHO       /E  .... Skip the Running of SetEULA.BAT on Remote System
 ECHO       /I  .... Search for connections to a list of IP Addresses  (delimited by semicolon)
 ECHO       /D  .... Use remote DNS server, rather than default DNS servers for lookups
 ECHO       /U  .... Use username for remote system
 ECHO       /P  .... Use password for remote system  (Must be used with /U)
 ECHO       /F  .... Force a Full Scan, Even if No Admin Access is Available
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 \\MyPC
	 ECHO  %~n0 YourPC /M /Y
	 ECHO  %~n0 \\%%COMPUTERNAME%% /M /Y
	 ECHO  %~n0 \\1.2.3.4 /Q
	 ECHO  %~n0 5.6.7.8
	 ECHO  %~n0 2.3.4.5 /S
	 ECHO  %~n0 \\123.45.67.89 /T
	 ECHO  %~n0 RemoteSys /V:"W32.MonkeyB"
	 ECHO  %~n0 SuspectSys /C:"TCP 1002"
	 ECHO  %~n0 SuspectSys /I:"123.124.125.126;222.212.202.111"
	 ECHO  %~n0 3.4.5.6 /D:12.120.12.120
	 ECHO  %~n0 \\98.76.54.231 /U:ThatDomain\Username /P:"Password"
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
	 ECHO  * Any parameters which contain spaces should be surrounded by quotes.
	 ECHO    This is especially true for parameters associated with /C: and /V:
 )
 CALL :ShowStatus "FINISHED"
                                                                                          