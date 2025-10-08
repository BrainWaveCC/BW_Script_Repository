 rem ==========================================================================
 rem === Set GLOBAL Variables for Logging, Input Files, Date/Time, etc
 rem ==========================================================================
 rem
 rem Created On: 22 Jun 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 22 Sep 2025 / 14 Aug 2025 / 09 Jul 2025 / 17 Jan 2025 / 23 Sep 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2003 or later (Originally: NT4+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    PAEXEC ................. https://www.poweradmin.com/paexec/
 rem    PSTOOLS ................ https://docs.microsoft.com/en-us/sysinternals/
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    FolderDefaults.TXT ..... Determine Location for Scripts and Logs
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem ==========================================================================

 :::  This script sets all the basic variables used by all of the major scripts
 :::  in this script repository.  This makes it possible to fundamentally alter
 :::  and customize the operation of various scripts without having to make
 :::  individual alterations to those scripts. This, of course, makes things
 :::  faster to deploy and update, and minimizes errors and troubleshooting.
 :::
 :::  This script sets GLOBAL variables for virtually every other script used
 :::  within the repository. The CustomVariables.*.TXT files supply the bulk
 :::  of the variables, making the other scripts far more portable.
 :::
 :::  The script TestVars.BAT will enumerate (almost) all the variables so
 :::  that you can see what is available for you to use in each script.  For
 :::  the most part, the variable names should be self-documenting.
 :::
 :::  This script uses DATEINFO.exe for ensuring consistent date and time
 :::  calculations across a variety of regional OS settings beyond just
 :::  US-English.
 :::
 :::  HISTORICAL NOTES:
 :::  -----------------
 :::  {Notes Prior to January 2014 Have Been Purged}
 :::
 :::  (Jan 2014) v6.3 -- The drive letter for the current script repository is
 :::  derived from the drive letter of the current script. This allows the use
 :::  of multiple script repositories (one per drive) in order to facilitate
 :::  flexibility for testing or other purposes.  All scripts belonging to a
 :::  particular repository  should be on the same drive with that repository.
 :::
 :::  (Feb 2014) v6.4 -- Added the capability to send log data to one or more
 :::  Syslog servers using the SyslogGen or NeoLog utilities in conjunction
 :::  with the @SYSLOGx environment variables. Also added the ability to track
 :::  the status of the console sessions to offer more prompts when scripts
 :::  are run interactively.
 :::
 :::  (Oct 2014) v6.6 -- FSUM is now the default hash utility.
 :::
 :::  (Nov 2014) v7.0 -- Added the MakeString utility to provide an alternative
 :::  (and faster) means of generating the @DIVIDERx string variables.  Also
 :::  added a link to the DateInfo utility which has been used since Mar 2012.
 :::
 :::  (Nov 2014) v7.1 -- Reverted to old method of creating string variables
 :::  because it is far less processor intensive.
 :::
 :::  (Nov 2014) v7.2 -- Introduced the mini custom variables INPUT file
 :::  (CustomVariables.MINI.%COMPUTERNAME%.TXT) to fascilitate minor deviations
 :::  from the normal CustomVariables.TXT INPUT file.
 :::
 :::  (Dec 2014) v7.3 -- Version change solely to match @Variables.BAT
 :::
 :::  (Feb 2015) v8.0 -- Changed the name of core input files from xxx.TXT to
 :::  [xxx].TXT to make them easier to identify during system updates.
 :::
 :::  (Apr 2015) v9.0 -- @Variables.BAT is officially deprecated, and will no
 :::  longer be synchronized with SetDrive.BAT. All of the scripts that called
 :::  upon @Variables.BAT have been migrated to use SetDrive.BAT instead.
 :::
 :::  (Sep 2015) v9.3 -- Added new function using DateInfo.exe to generate
 :::  truly unique 5-digit random numbers, stored in @RANDOM.  Falls back to
 :::  using %RANDOM% if DateInfo.exe is unavailable.
 :::
 :::  (Nov 2015) v9.4 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Feb 2016) v9.5 -- Added new day of week functions using DateInfo.exe
 :::
 :::  (Feb 2016) v10.0 -- The @STORAGE variable (and its derivatives) will now
 :::  be determined by the existence of the Storage$ and Logs$ shares. If they
 :::  cannot be found, then the DefaultFolders.TXT values will be used as a
 :::  fallback.
 :::
 :::  (May 2016) v10.1 -- Added variables for tracking \UTILS and \BAT folders.
 :::
 :::  (Jan 2017) v10.2 -- Added input files for checking remote/VPN hosts.
 :::
 :::  (Jan 2017) v10.4 -- Added a new subroutine to improve processing of Input
 :::  lists.
 :::
 :::  (Apr 2017) v11.0 -- Updated to support new, signed versions of BrainWave
 :::  utilities, particularly DateInfo.exe, RandomPass.exe and FileHash.exe,
 :::  streamlining the date and time calculations (among others)
 :::  -- DATEINFO.exe has totally replaced DOFF.exe for all date calculations
 :::  -- The x64 OS detection has been improved
 :::
 :::  (Nov 2017) v11.4 -- Added an input file for cleaning obsolete executables.
 :::
 :::  (Dec 2017) v11.5 -- Added \Utils\Misc (via "%@M_UTILS%") to the search path
 :::  for the HASH utilities, for ROBOCOPY, and for the BrainWave Utilities.
 :::
 :::  (Mar 2018) v11.6 -- The release of FILEHASH v2.x provides the following
 :::  functionality: traverse folders natively; display full path, filenames
 :::  only, or hide base path; perform file exclusions inline; display the size
 :::  of hashed files; provide an FSUM-compatible display mode;
 :::  -- FILEHASH is now the preferred hash utility for the entire script
 :::  repository, and routines which use it have been upgraded accordingly;
 :::  -- Support for both MD5SUM and FCIV have been eliminated;
 :::  -- Added filtered CMD Title Routine
 :::
 :::  (Apr 2018) v12.0 -- Improved the performance of reading variables from
 :::  the CustomVariables.*.TXT INPUT files, using FINDSTR (if available);
 :::  -- Added @SEARCHPATH for searching utilities more quickly;
 :::  -- Added a routine for finding specific Microsoft utils (e.g. FINDSTR);
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (May 2018) v12.1 -- Ensure that %SystemRoot% folders are early in the
 :::  PATH to ensure that utilities work as expected (especially FIND.EXE)
 :::
 :::  (Jul 2018) v12.3 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::  -- Eliminated NeoLog for Syslogging
 :::
 :::  (Aug 2018) v13.0 -- With the release of a 64-bit edition of a BrainWave
 :::  utility (FileHash64.exe), a routine has been added to enable scripts to
 :::  select 64-bit editions of these utilities on Windows x64, if they exist.
 :::
 :::  (Oct 2018) v13.2 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Dec 2018) v14.0 -- Added Global Variables for ADFIND;
 :::  -- Changed all occurrences of ECHO. to ECHO: to avoid the following error:
 :::   'ECHO.' is not recognized as an internal or external command, operable
 :::    program or batch file.  See: https://www.dostips.com/forum/viewtopic.php?t=774
 :::
 :::  (Dec 2018) v15.0 -- DATEINFO has been updated to v4.0, (in both x86 and x64
 :::  editions) providing a more efficient way to generate key date/time variables
 :::  (and core supporting variables) using the new "--Script-Variables" parameter;
 :::  -- Save current code page (in $CODEPAGE), then set the code page to 1252;
 :::
 :::  (Feb 2019) v15.1 -- Additional environment variables are available via
 :::  DATEINFO v4.1, including @OS_ARCH for determining OS bitness (x86 vs x64)
 :::  and @APP_ARCH for determining the bitness of the running DATEINFO;
 :::  -- Updated the @ADQUERY_x variables to include All Computers and Non-DCs;
 :::
 :::  (Feb 2019) v15.2 -- Added some PATH-related environment variables;
 :::  -- Added a separate list for tracking the BrainWave Utilities;
 :::
 :::  (Mar 2019) v15.3 -- Changed the @CLEANUP_LIST variable to @CLEANUP_MAIN
 :::  and added the @CLEANUP_CUSTOM variable for local additions
 :::
 :::  (May 2019) v15.4 -- Added a new BrainWave Utility: GetInput.exe;
 :::  -- Corrected the BrainWave Utilities File List "[BrainWaveUtils].TXT";
 :::  -- Changed some "[*].TXT" input files into "{*}.TXT" input files
 :::
 :::  (Jul 2019) v16.0 -- Set Max Threads for ROBOCOPY to max physical CPUs;
 :::  -- Change ROBOCOPY retry values to /R:3 /W:10;
 :::  -- Removed all Legacy Definitions from the script;
 :::
 :::  (Sep 2019) v16.1 -- Change ROBOCOPY retry values to /R:2 /W:5;
 :::  -- Allow @THREADS definition to be set by DATEINFO unless using old ROBOCOPY;
 :::  -- Locate valid Remote Console Utilities (e.g. PSEXEC, PAEXEC, etc);
 :::
 :::  (Sep 2019) v16.2 -- Added a TEST list for FolderDefaults;
 :::  -- Added FIND.EXE to Microsoft Utilities;
 :::
 :::  (Dec 2019) v16.3 -- Made minor modification to @CONSOLE_SESSSION test routine;
 :::  -- Added some new default input files for upcoming script modifications;
 :::
 :::  (Mar 2020) v17.0 -- Basic cleanup for the existence of stray "ECHO" files;
 :::  -- Replaced FINDSTR with BrainWave ReadConfig.exe for reading config file;
 :::  -- ReadConfig.exe replaces FIND.EXE for parsing script configuration files;
 :::
 :::  (Apr 2020) v17.1 -- Updated ReadConfig.exe to the public release version;
 :::  -- Updated the DebugMode routines to support the STEP option;
 :::
 :::  (May 2020) v17.2 -- Renamed the variable for the MINI custom variables file;
 :::  -- Now support MINI editions of the ARCHIVE-INFO and REPL-INFO config files;
 :::  -- Removed the legacy edition of the OS build number parser;
 :::
 :::  (May 2020) v17.3 -- Updated routine to determine correct Remote Control utility;
 :::  -- Updated the calculation for defining @THREADS (using info from DATEINFO);
 :::  -- Added new input files for OpsLogs, SecurityLogs and UptimeReport);
 :::  -- Added a couple of variables to support CODEPAGE routines;
 :::
 :::  (Jun 2020) v17.4 -- Facilitate the tracking of individual scripts by
 :::  sending the name of the parent script (whatever called SetDrive.BAT) to a
 :::  local syslog server, if the @SCRIPT_METRICS variable is set to TRUE;
 :::
 :::  (Jul 2020) v17.5 -- Complete support for centralized DEBUG mode;
 :::  -- Ensure a valid @SCRIPTS value when this script is called via UNC path;
 :::  -- Display version info;
 :::
 :::  (Sep 2020) v17.6 -- Added support for multiple local Syslog Ports for @SCRIPT_METRICS;
 :::  -- Added another option to the ADFIND pre-set parameters;
 :::
 :::  (Oct 2020) v17.7 -- Corrected the calculation of @WHICHDRV and @BACKUPDRV;
 :::
 :::  (Dec 2020) v17.8 -- Added a \UTILS\XP path for DATEINFO on pre-Vista SP1 systems;
 :::
 :::  (Jan 2022) v18.0 -- Get rid of the UTILS\XP path for DATEINFO [no longer needed];
 :::  -- Check for the existence of an emergency script or utility via @EMERGENCY_JOB;
 :::  -- Update Syslog logging via @SCRIPT_METRICS if an Emergency Job is attempted;
 :::
 :::  (Feb 2022) v18.1 -- Update the @ADQUERY* variables to add %@ADFIND%;
 :::
 :::  (Mar 2022) v18.2 -- Added @CUSTOM-NETWORK for IPConfig.TXT;
 :::
 :::  (Jan 2023) v19.0 -- Added a centralized common name for variable inclusion, as
 :::  an alternative to using only the computername (via @CUSTOM_CONFIG);
 :::
 :::  (Oct 2023) v19.1 -- Added a default date format variable @DATEFMT for use with DATEINFO;
 :::  -- Add another condition for determining if CMD console is interactive;
 :::
 :::  (Feb 2024) v19.2 -- Added a default name for the [SpecialShares].TXT input folder;
 :::  -- Eliminate the obsolete BeyondExecv2 remote console utility from the configuration;
 :::
 :::  (Apr 2024) v19.3 -- Added support for the @NOPROMPT variable to the @CONSOLE_SESSSION routine;
 :::
 :::  (May 2024) v19.4 -- Added the missing @UTILNAMES variable for the [SysInternals].TXT file;
 :::  -- Ensure the existence of baseline BWCC Utilities for scripts;
 :::
 :::  (Jun 2024) v19.5 -- Added the @BUILDINFO and @BUILDINFO-PLUS and @BUILDINFO-LATEST
 :::  variables to store the current summary and extended lists of Windows build numbers;
 :::
 :::  (Jul 2024) v19.6 -- Added overrides for @CONSOLE_SESSION detection, especially
 :::  for systems running Windows Home Edition, via @CONSOLE_SESSION_ON variable;
 :::  -- Replaced the :RunCMD routine with just a CALL command;
 :::  -- Eliminated the long obsolete :MakeDivider routine;
 :::
 :::  (Sep 2024) v19.7 -- Change from Code Page 1252 to Code Page 65001 (Unicode);
 :::  -- Set @VERBOSE_OFF to "ECHO OFF" even outside the DEBUG routines;
 :::  -- All code page to be set to a custom value, if %2 is supplied;
 :::
 :::  (Jan 2025) v19.8 -- Added the @COMPROMISED_IPs variable to track public IP
 :::  addresses related to firewall credential/configuration compromises;
 :::
 :::  (Jul 2025) v19.9 -- Added CHCP to debug output;
 :::
 :::
 :::  SCRIPTING SYNTAX RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  https://ss64.com/ .......... CMD and Powershell syntax
 :::  https://www.dostips.com/ ... Windows Shell Scripting Tips
 :::  -------------------------------------------------------------------------


 rem -- Current Script Version
 SET "@VAR_VER=%~nx0 v19.10.0.1995" a


 rem ==========================================================================
 rem === Check for Essential Utilities and/or Scripts
 rem === Updated On: 10 May 2024
 rem ==========================================================================
 FINDFILES --bw -w -m -o CHOICE.EXE FINDSTR.EXE TIMEOUT.EXE
 IF ERRORLEVEL 64 EXIT /B


 rem ==========================================================================
 rem === Record Current Code Page and Display Announcement
 rem === Updated On: 23 Sep 2024 / 08 Sep 2024 / 01 Sep 2024 / 30 Jul 2020
 rem ==========================================================================
:Announcement
 SET "@CODEPAGE_OEM=437"
 IF "%~2"=="" (SET "@CODEPAGE_BWCC=65001") ELSE (SET "@CODEPAGE_BWCC=%~2")
 IF NOT DEFINED $CODEPAGE FOR /F "TOKENS=1* DELIMS=:" %%B IN ('CHCP') DO SET /A "$CODEPAGE=%%C"
 FOR /F "TOKENS=1* DELIMS=:" %%B IN ('CHCP %@CODEPAGE_BWCC%') DO (
	 ECHO Reading Script Configuration Data via %@VAR_VER:  = % ... Please Wait... {Active code page:%%C}
	 SET /A "@CODEPAGE_CURRENT=%%C"
 )
 ECHO:


 rem ==========================================================================
 rem === Enable Debug Mode If 'Debug' Variable is Set to TRUE/LOG/STEP/VERBOSE
 rem === Updated On: 09 Jul 2025 / 02 Sep 2024 / 05 May 2020 / 24 Apr 2020
 rem ==========================================================================
:DebugMode
 SET "@VERBOSE_OFF=ECHO OFF"
 SET "#DEBUG=" & FOR %%d IN (LOG STEP TRUE VERBOSE) DO IF /I "%Debug%"=="%%~d" SET "#DEBUG=TRUE"
 IF DEFINED #DEBUG (
	 SET "@DIAGMODE=TRUE"
	 SET "@DEBUG_MODE=[DEBUG MODE ON]"
	 SET "@PAUSE_IF_DEBUG=TIMEOUT 5"
	 SET "@PRINT_IF_DEBUG=ECHO:^& CHCP^& SET @^& ECHO:^& TIMEOUT 5"
	 SET "@END_DEBUG_MODE=ECHO:^& ECHO *** DEBUG MODE FINISHED ***^& ECHO:^& SET @^& TIMEOUT 30"
	 IF /I "%Debug%"=="LOG" (SET "@PAUSE_IF_DEBUG=" & SET "@PRINT_IF_DEBUG=ECHO:^& SET @^& ECHO:")
	 IF /I "%Debug%"=="STEP" (SET "@PAUSE_IF_DEBUG=ECHO ##PAUSE##" & SET "@PRINT_IF_DEBUG=ECHO ##PRINT##")
	 IF /I "%Debug%"=="VERBOSE" (SET "@VERBOSE_OFF=ECHO ON") ELSE (FOR %%t IN (ON OFF) DO SET "@VERBOSE_%%t=ECHO %%t")
	 ECHO *** DEBUG MODE = ON ***
	 ECHO ON
 ) ELSE ( FOR %%d IN (DEBUG_MODE PAUSE_IF_DEBUG PRINT_IF_DEBUG END_DEBUG_MODE VERBOSE_ON) DO SET "@%%d=")


 rem ==========================================================================
 rem === Set GLOBAL Variables for Input Files, Logs and Storage
 rem === Updated On: 11 Sep 2024 / 12 Sep 2023 / 16 Mar 2022
 rem ==========================================================================
:Variables
 %@VERBOSE_OFF%

 rem -- Date Variable Definitions (and more) using DATEINFO v4.0+
 rem -- Updated On: 12 Sep 2023 / 04 Jul 2019
 SET @APP_ARCH=& FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"
 IF NOT DEFINED @APP_ARCH (
	 ECHO *** COULD NOT DEFINE ESSENTIAL VARIABLES *** 
	 TIMEOUT 60
	 EXIT /B
 )
 SET @DIVIDER^==%@EQUALDIV%
 IF NOT DEFINED @DATEFMT SET @DATEFMT=-F "mm/dd/yyyy hh:nn:ss.zzz"


 rem -- Pre-pend our Local Scripts Archive to the current PATH
 rem -- Updated On: 27 Dec 2020 / 27 Jul 2020
 FOR %%S IN ("%~0\..") DO SET @SCRIPTS=%%~dpS
 SET @SCRIPTS=%@SCRIPTS:~0,-1%
 SET @UTILS=%@SCRIPTS%\Utils
 SET @M_UTILS=%@UTILS%\Misc
 SET @UTILS64=%@UTILS%\x64
	 IF /I "%@OS_ARCH%"=="x64" (
		 SET @S_UTILS=%@M_UTILS%;%@UTILS%;%@UTILS64%
		 SET @P_UTILS=%@UTILS64%;%@UTILS%
	 ) ELSE (
		 SET @S_UTILS=%@M_UTILS%;%@UTILS%
		 SET @P_UTILS=%@UTILS%
	 )
 SET @DIR_PS=%@SCRIPTS%\PowerShell
 SET @DIR_BAT=%@SCRIPTS%\BAT
 SET @DIR_CMD=%@DIR_BAT%
 SET @DIR_KIX=%@SCRIPTS%\KIX
 SET @DIR_VBS=%@SCRIPTS%\VBS
 SET @DIR_UTILS=%@UTILS%
 SET @WINDOWSPATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem
 SET @SEARCHPATH=%@S_UTILS%;%@WINDOWSPATH%
 IF NOT DEFINED @PATH SET @PATH=%PATH%
 SET PATH=%@DIR_BAT%;%@DIR_PS%;%@P_UTILS%;%@WINDOWSPATH%;%@PATH%;%@M_UTILS%


 rem -- Global AD Search Variables for ADFIND
 rem -- Updated On: 20 Feb 2022 / 28 Sep 2020
 rem C = All Windows Computers; D = Domain Controllers; N = All Non-Domain Controllers; S = Servers; O = Servers w/o Domain Controllers; W = Workstations
 SET @xPARAMS=-nodn -s SUB -maxe 2000 -list attr name -excldn "OBSOLETE;RETIRED;DECOMMISSIONED"
 SET @ADQUERY_C=%@ADFIND% -f "(&(objectcategory=computer)(operatingSystem=Windows*))" %@xPARAMS%
 SET @ADQUERY_D=%@ADFIND% -f "(&(objectCategory=computer)(|(primaryGroupId=516)(primaryGroupId=521)))" %@xPARAMS%
 SET @ADQUERY_N=%@ADFIND% -f "(&(objectcategory=computer)(operatingSystem=Windows*)($$$(primaryGroupID=516)))" %@xPARAMS%
 SET @ADQUERY_S=%@ADFIND% -f "(&(objectcategory=computer)(|(operatingSystem=Windows*Server*)(operatingSystem=Windows*Storage*)))" %@xPARAMS%
 SET @ADQUERY_O=%@ADFIND% -f "(&(objectcategory=computer)(|(operatingSystem=Windows*Server*)(operatingSystem=Windows*Storage*))($$$(primaryGroupID=516)))" %@xPARAMS%
 SET @ADQUERY_W=%@ADFIND% -f "(&(&(objectcategory=computer)(operatingSystem=Windows*))($$$(|(operatingSystem=Windows*Server*)(operatingSystem=Windows*Storage*))))" %@xPARAMS%


 rem -- Default TRUE/FALSE Parameters
 rem -- Updated On: 22 Dec 2018 / 27 Apr 2015
 SET @NOARCHIVE=FALSE
 SET @MAILONLY=FALSE
 SET @NOMAIL=FALSE
 SET @SYNC=FALSE
 SET @HELP=FALSE


 rem -- Determine Which Console Session is Active for this Script
 rem -- Updated On: 21 Jul 2024 / 24 Apr 2024 / 16 Oct 2023 / 21 Dec 2019
 FINDFILES -F QUERY.EXE -Q
 IF ERRORLEVEL 109 (
	 SET @CONSOLE_SESSION_REASON=WINDOWS HOME
	 SET @CONSOLE_SESSION=TRUE
 ) ELSE ( CALL :SetConsoleSession )
 IF DEFINED @NOPROMPT SET @CONSOLE_SESSION=FALSE
 IF DEFINED @CONSOLE_SESSION_ON SET @CONSOLE_SESSION=%@CONSOLE_SESSION_ON%


 rem -- Variables for Scripts, Input Files, and Text Comparisons
 rem -- Updated On: 28 Jul 2024 / 24 Sep 2019 / 15 Feb 2015
 SET @NODIFF=FC: no differences encountered
 SET @TEXTFILES=BAT CMD KIX VBS PL PS TXT INI DAT INPUT CSV XL
 SET @SCRIPTEXT=
 FOR %%E IN (%@TEXTFILES%) DO CALL SET @SCRIPTEXT=%%@SCRIPTEXT%% *.%%~E


 rem -- Obtain Server Input Lists (Customized or Default)
 rem -- Updated On: 17 Jan 2025 / 18 Jun 2024 / 16 Jun 2024 / 10 May 2024
 SET @INPUT=%~dp0Input\
 SET @L_INPUT=%~dp0LogonScripts\Scripts\Bat\Input\

 CALL :FindList ORIGINALS_LIST   {PlaceHolders-Exemption}
 CALL :FindList SYNC-EXCLUDE     {Sync-Exclude}

 CALL :FindList COPYEXEMPT       [CopyExemption]
 CALL :FindList COPYEXEMPT-PLUS  [CopyExemption-Plus]
 CALL :FindList BW_UTIL_LIST     [BrainWaveUtils]
 CALL :FindList SOURCEINPUT      [ScriptInput]
 CALL :FindList CLEANUP_MAIN     [SyncScripts]

 CALL :FindList AUDIT-INFO       [AuditSettings]
 CALL :FindList BAD_PROCESS      [BadProcesses]
 CALL :FindList BAD_SERVICE      [BadServices]
 CALL :FindList COMPROMISED_IPS  [CompromisedIPs]
 CALL :FindList GOOD_SERVICE     [KnownServices]
 CALL :FindList PROCESS-INFO     [LongProcesses]
 CALL :FindList SCANEXEMPT       [ScanExemption]
 CALL :FindList SPECIALSHARES    [SpecialShares]
 CALL :FindList TESTJOBS         [TestSchedJobs]
 CALL :FindList UTILNAMES        [SysInternals]
 CALL :FindList BUILDINFO        [WindowsBuilds]
 CALL :FindList BUILDINFO-PLUS   [WindowsBuilds-Plus]
 CALL :FindList BUILDINFO-LATEST [WindowsBuilds-Latest]

 CALL :FindList STORAGELIST      FolderDefaults
 CALL :FindList TESTSTORLIST     FolderDefaults.TEST
 CALL :FindList PROCESS-INFO2    LongProcesses-MINI
 CALL :FindList SOURCELIST       ScriptSource

 CALL :FindList DC-LIST          AD-DCs
 CALL :FindList VPNLIST          CheckVPN
 CALL :FindList WANLIST          CheckWAN
 CALL :FindList SCANLIST         ScanList
 CALL :FindList EXCHANGELIST     ExchangeList
 CALL :FindList EXCHANGETEST     ExchangeTest
 CALL :FindList LOWDISKLIST      LowDisk
 CALL :FindList NETWORKLIST      NetworkList
 CALL :FindList TESTNETLIST      NetworkList.TEST
 CALL :FindList OPSCONFIG        MonitoringConfig
 CALL :FindList TESTOPSCFG       MonitoringConfig.TEST
 CALL :FindList SECURITYLIST     SecurityList
 CALL :FindList SERVERLIST       ServerList
 CALL :FindList TESTSRVLIST      SmallList
 CALL :FindList UPTIMELIST       UptimeList

 CALL :FindList ARCHIVE-INFO     ArchiveInfo
 CALL :FindList ARCH-INFO-MINI   ArchiveInfo.MINI
 CALL :FindList CUSTOM-VARS      CustomVariables
 CALL :FindList CUST-VARS-MINI   CustomVariables.MINI
 CALL :FindList CUSTOM-NETWORK   IPConfig
 CALL :FindList MRTG-INFO        MRTG-Info
 CALL :FindList REPL-INFO        ReplicationInfo
 CALL :FindList REPL-INFO-MINI   ReplicationInfo.MINI
 CALL :FindList REPORT-INFO      ReportSettings
 CALL :FindList MY_SOFTWARE      SoftwareList
 CALL :FindList TS_SOFTWARE      SoftwareList-Citrix
 CALL :FindList SMIGRATION       StorageMigrationInfo
 CALL :FindList CLEANUP_CUSTOM   SyncScripts
 CALL :FindList LIBRARYLIST      WinLibraryList

 rem -- Flags and MasterList
 SET @MASTERLIST=%@INPUT%SystemList.CSV
 SET @DONT_COPY=%@INPUT%DontCopyFlag.DAT
 SET @BKUPSET=%@INPUT%SystemState-Plus.BKS
 SET @CUSTOMINPUT=%@INPUT%CopyCustomInput.DAT
 SET @NOCUSTOMINPUT=%@INPUT%CopyCustomInput.DAT
 SET @NODEFRAG=%@INPUT%NoDefrag.DAT
 SET @NOEXCHANGE=%@INPUT%NoExchangeData.DAT
 SET @NOBACKUP=%@INPUT%NoSystemState.DAT

 rem -- Determine If Backup Set should Be Used, Or Just SystemState Only...
 IF EXIST "%@NOBACKUP%" (SET @SSBACKUP=TRUE) ELSE (SET @SSBACKUP=FALSE)

 rem -- Determine Current CORE List of Script Input Files
 SET @GLOBALTXT=AuditSettings BadProcesses BadServices CopyExemption CopyExemption-Plus KnownServices LongProcesses PlaceHolders-Exemption ScanExemption ScriptInput SpecialShares Sync-Exclude SysInternals TestSchedJobs ValidSecTools
 FOR %%I IN (%@GLOBALTXT%) DO FOR %%F IN ("%@INPUT%" "%@L_INPUT%") DO IF EXIST "%%~F%%~I.TXT" (
	 RENAME "%%~F%%~I.TXT" "[%%~I].TXT" 2>NUL
	 DEL "%%~F%%~I.TXT" 2>NUL
 )
 SET @CORELIST=& IF EXIST "%@SOURCEINPUT%" FOR /F "SKIP=2 TOKENS=*" %%I IN ('TYPE "%@SOURCEINPUT%" ^| FIND "["') DO CALL SET @CORELIST=%%@CORELIST%% %%~I
 IF NOT DEFINED @CORELIST SET @CORELIST=%@GLOBALTXT%

 rem -- Determine Current COMPLETE List of Script Input Files
 SET @CUSTOMLIST=AD-DCs ArchiveInfo BasicInfo Browser-Exempt CheckVPN CheckWAN CustomVariables ExchangeList ExchangeTest FolderDefaults LongProcesses-MINI LowDisk MRTG-Info MyServers NetworkList NetworkSegmentsNetworkSegments-Expanded OpenCMD ReplicationInfo ScriptSource SecurityList ServerList SmallList SoftwareList SoftwareList-Citrix SpecialRoutes StorageMigration SyncScripts UptimeList WinLibrary
 SET @SOURCETXT=& IF EXIST "%@SOURCEINPUT%" FOR /F "USEBACKQ SKIP=2 TOKENS=*" %%I IN ("%@SOURCEINPUT%") DO CALL SET @SOURCETXT=%%@SOURCETXT%% %%~I
 IF NOT DEFINED @SOURCETXT (
	 FOR %%I IN (%@CORELIST%) DO CALL SET @SOURCETXT=%%@SOURCETXT%% [%%~I]
	 FOR %%I IN (%@CUSTOMLIST%) DO CALL SET @SOURCETXT=%%@SOURCETXT%% %%~I
 )


 rem -- Determine Location/Existence of BrainWave Utilities (x64 and x86)
 rem -- Updated On: 28 Jul 2024 / 24 Feb 2019 / 12 Dec 2018
 SET @BW_UTILITIES=& IF EXIST "%@BW_UTIL_LIST%" FOR /F "USEBACKQ TOKENS=*" %%I IN ("%@BW_UTIL_LIST%") DO CALL SET @BW_UTILITIES=%%@BW_UTILITIES%% %%~I
 IF NOT DEFINED @BW_UTILITIES SET @BW_UTILITIES=ChangeCase CheckParams DateInfo FileHash GetPrimeNumbers MakeString RandomPass Placeholder PrintFileInfo
 SET @SEARCH64=""& IF /I "%@OS_ARCH%"=="x64" SET @SEARCH64="" 64
 FOR %%F IN (%@BW_UTILITIES%) DO (
	 SET @%%F$=
	 FOR %%P IN (%@S_UTILS%) DO FOR %%E IN (%@SEARCH64%) DO IF EXIST "%%~P\%%F%%~E.EXE" SET @%%F$=%%~P\%%F%%~E.EXE
 )

 rem -- Determine Location/Existence of Various Microsoft Utilities
 rem -- Updated On: 24 Sep 2019 / 19 Apr 2018
 FOR %%F IN (CHOICE FINDSTR FORFILES FIND) DO (
	 SET @%%F=
	 FOR %%P IN (%@SEARCHPATH%) DO IF EXIST "%%~P\%%F.EXE" SET @%%F=%%~P\%%F.EXE
 )

 rem -- Determine Location/Existence of Remote Console Utilities
 rem -- Updated On: 26 Feb 2024 / 21 May 2020
 SET @REXEC_UTILS=PAEXEC PSEXEC
 FOR /F "TOKENS=*" %%R IN ('WHERE %@REXEC_UTILS% 2^>NUL') DO (
	 SET @REXEC_UTIL=%%~nxR
	 IF /I NOT "%@NOPAEXEC%"=="TRUE" IF /I "%%~nR"=="PAEXEC" SET @REXEC_UTIL=PAEXEC.EXE
	 IF /I NOT "%@NOPSEXEC%"=="TRUE" IF /I "%%~nR"=="PSEXEC" SET @REXEC_UTIL=PSEXEC.EXE %@PSPARAMS%
 )


 rem -- Create Full Version Info for Calling Script
 rem -- Updated On: 21 Apr 2015
 SET @SCRIPTPATH=SCRIPTS$\BAT
 SET @SCRIPTVER=%~dp0%@VER%
 SET @SCRIPTVER_UNC=\\%COMPUTERNAME%\%@SCRIPTPATH%\%@VER%


 rem -- Determine Custom Task Scheduler Folder from CustomVariables.TXT
 rem -- Updated On: 28 Jul 2024 / 15 May 2020 / 24 Apr 2020
 IF %@OSBUILD% LSS 6000 (SET @TASKFOLDER=) ELSE (
	 SET @TASKFOLDER=BW-Scripts\
	 FOR %%C IN ("%@CUSTOM-VARS%" "%@CUST-VARS-MINI%") DO IF EXIST "%%~C" (
		 FOR /F "TOKENS=*" %%V IN ('READCONFIG "%%~C" -S @TASKFOLDER 2^>NUL') DO CALL %%V
	 )
 )
 IF DEFINED @TASKFOLDER SET @TASKFOLDER=%@TASKFOLDER:\\=\%

 rem -- Determine OS-specific Variables for Task Scheduler
 rem -- Updated On: 19 Sep 2019 / 04 Jul 2019
 SET @FORCE=& IF %@OSBUILD% GEQ 3790 SET @FORCE=/F
 SET @JOBLEVEL=& IF %@OSBUILD% GEQ 6000 SET @JOBLEVEL=/RL HIGHEST

 rem -- Set Additional Variables for Using XCOPY vs ROBOCOPY
 rem -- Updated On: 19 Apr 2018 / 01 Jan 2018
 SET @COPYMODE=XCOPY
 SET @ROBOCOPY=& FOR %%P IN (%@SEARCHPATH%) DO IF EXIST "%%~P\RoboCopy.EXE" (
	 SET @ROBOCOPY=%%~P\RoboCopy.EXE
	 SET @COPYMODE=ROBOCOPY
 )
 SET @RETRIES=/R:2 /W:5& IF %@OSBUILD% LSS 7600 SET @THREADS=

 rem -- Determine Number of Threads to Set for ROBOCOPY
 rem -- Updated On: 26 May 2020 / 22 May 2020
 IF NOT DEFINED @THREADS (
	 IF DEFINED @PHY_CORES   (SET @AVAIL_CORES=%@PHY_CORES%)   ELSE (SET @AVAIL_CORES=%NUMBER_OF_PROCESSORS%)
	 IF DEFINED @AVAIL_CORES (SET @THREADS=/MT:%@AVAIL_CORES%) ELSE (SET @THREADS=)
 )


 rem -- Set Variables for File Checksum Utilities (FSUM and FileHash, respectively)
 rem -- Updated On: 24 Feb 2019 / 09 Aug 2018
 SET @HASHUTILS=FSUM FILEHASH
 SET @HASHUTIL=
 SET @XCOMPARE=FALSE
 FOR %%H IN (%@HASHUTILS%) DO (
	 SET @%%~H=
	 FOR %%P IN (%@S_UTILS%) DO IF EXIST "%%~P\%%~H.EXE" (
		 SET @%%~H=%%~P\%%~H.EXE
		 SET @XCOMPARE=TRUE
		 SET @HASHUTIL=%%~H
		 IF /I "%%~P"=="%@UTILS64%" (SET @HU_EDITION=x64) ELSE (SET @HU_EDITION=x86)
	 )
 )


 rem -- Set Variables for Syslog Output Utilities (SyslogGen)
 rem -- Updated On: 09 Aug 2018 / 20 Jul 2018 / 19 Apr 2018
 SET @SYSLOG_UTILS=SYSLOGGEN
 SET @SYSLOG_UTIL=
 SET @USE_SYSLOGS=FALSE
 SET @NO_SYSLOGGEN=Unable to recognize target address or hostname: No such host is known.
 FOR %%S IN (%@SYSLOG_UTILS%) DO (
	 SET @%%~S=
	 FOR %%P IN (%@S_UTILS%) DO IF EXIST "%%~P\%%~S.EXE" (
		 SET @%%~S=%%~P\%%~S.EXE
		 SET @USE_SYSLOGS=TRUE
		 SET @SYSLOG_UTIL=%%~S
	 )
 )


 rem -- Determine Log and Storage Drives and Folders
 rem -- Updated On: 22 Oct 2020 / 29 Jul 2020
 SET @SETCFG=FALSE
 SET @WHICHDRV=%SystemDrive%
 FOR /F "TOKENS=2 DELIMS=\ " %%D IN ('NET SHARE Storage$ 2^>NUL ^| FIND /I "PATH"') DO SET @WHICHDRV=%%D
 FOR /F "TOKENS=2 DELIMS=\ " %%D IN ('NET SHARE Backups$ 2^>NUL ^| FIND /I "PATH"') DO SET @BACKUPDRV=%%D

 IF DEFINED @RESETDRIVE (
	 SET @WHICHDRV=%SystemDrive%
	 SET @BACKUPDRV=%SystemDrive%
	 FOR /F "TOKENS=1-4 EOL=|" %%L IN (%@STORAGELIST%) DO FOR %%C IN ("%COMPUTERNAME%" ";%COMPUTERNAME%") DO IF /I "%%~L"=="%%~C" (
		 SET @SETCFG=TRUE
		 IF EXIST "%%~M\" (SET @WHICHDRV=%%~M& SET @BACKUPDRV=%%~M)
		 FOR %%A IN (%@ALPHABET%) DO IF /I "%%~O"=="%%~A:" IF EXIST "%%~O\" SET @BACKUPDRV=%%~O
	 )
 )
 SET @STORAGE=%@WHICHDRV%\Storage
 SET @LOGBASE=%@STORAGE%\Logs
 SET @ZIPPATH=%@LOGBASE%\ZipFiles
 FOR %%D IN (Backups Downloads Installs) DO SET @%%D=%@BACKUPDRV%\Storage\%%D


 rem -- Determine Script Repository Folders, If They Exist
 rem -- Updated On: 08 Mar 2017
 FOR %%F IN (H: G: F: E: D: C: %SystemDrive%) DO IF EXIST "%%~F\Storage\Work" SET @LOCAL_REPOSITORY=%%~F\Storage\Work
 FOR /F "TOKENS=2 DELIMS= " %%D IN ('NET SHARE Scripts_Source$ 2^>NUL ^| FIND /I "PATH"') DO SET @SCRIPTS_SOURCE0=%%D


 rem -- Grab Appropriate Custom Variables from CustomVariables.*.TXT -- Use ReadConfig.exe
 rem -- Updated On: 28 Jul 2024 / 15 May 2020 / 24 Apr 2020
 IF NOT "%~1"=="" FOR %%C IN ("%@CUSTOM-VARS%" "%@CUST-VARS-MINI%") DO IF EXIST "%%~C" (
	 SET #CALLED-%%~C=TRUE
	 FOR /F "TOKENS=*" %%P IN ('READCONFIG "%%~C" -F "%~1" 2^>NUL') DO CALL %%P
 )


 rem -- Generate Fully-Qualified Name for Local Host
 rem -- Updated On: 19 Feb 2014
 IF DEFINED @INTFQDN (
	 SET @LOCALHOST=%COMPUTERNAME%.%@INTFQDN%
 ) ELSE (
	 FOR /F "TOKENS=2 DELIMS=:" %%D IN ('IPCONFIG /ALL ^| FIND /I "Primary DNS Suffix"') DO SET @LOCALHOST=%COMPUTERNAME%.%%D
 )
 SET @LOCALHOST=%@LOCALHOST: =%


 rem -- If @EMERGENCY_JOB is defined, run the script or utility that is referenced by full path
 rem -- Updated On: 02 Jan 2022
 SET @EJ_INFO=[EJ] - "%@EMERGENCY_JOB%"
 SET @EJ_FILE="%TEMP%\EMERGENCYJOB.%@FILESTAMP_R%"
 IF DEFINED @EMERGENCY_JOB (
	 IF EXIST "%@EMERGENCY_JOB%" (
		 ECHO .....
		 ( rem -- Write to Log
			 NOW \z Running "%@EMERGENCY_JOB%"
			 CALL "%@EMERGENCY_JOB%"
		 ) >%@EJ_FILE% 2>&1
		 REN "%@EMERGENCY_JOB%" "*.%@DIRSTAMP_R%"
	 ) ELSE (
		 SET @EJ_INFO=%@EJ_INFO:[EJ]={EJ}%
		 ECHO ...
		 NOW \z Could Not Find "%@EMERGENCY_JOB%" >%@EJ_FILE% 2>&1
	 )
 ) ELSE (
	 SET @EJ_INFO=
 )


 rem -- Send Name of Calling Shell Script to Local Syslog, if @SCRIPT_METRICS=TRUE
 rem -- Updated On: 02 Jan 2022 / 21 Sep 2020
 SET @SYSLOG_MSG=%DATE% at %TIME: =0% -- Initiated %@EJ_INFO%
 SET @SYSLOG_MSG=!@SYSLOG_MSG:\=\x5B!
 SET @SYSLOG_MSG=!@SYSLOG_MSG:"=\x22!

 IF NOT DEFINED @MY_SYSLOG_PORTS SET @MY_SYSLOG_PORTS=514
 IF /I "%@SCRIPT_METRICS%"=="TRUE" (
	 FOR %%P IN (%@MY_SYSLOG_PORTS%) DO (
		 "%@SYSLOGGEN%" -t:127.0.0.1 -p:%%~P -f:19 -s:6 -tg:"%~1" -m:"%@SYSLOG_MSG%" -q -hn:localhost 2>NUL | FIND /V "%@NO_SYSLOGGEN%"
	 )
 )


 rem ==========================================================================
 rem === Exit Script (But Do NOT Reset Environment Variables)
 rem === Updated On: 22 Sep 2025 / 21 Jul 2024 / 29 Jul 2020 / 05 May 2015
 rem ==========================================================================
:ExitBatch
 IF NOT DEFINED @CUSTOM_TITLE SET @CUSTOM_TITLE=Command Prompt
 IF DEFINED DEBUG ECHO SETTING STORAGE FOLDER TO "%@STORAGE%" [%@VAR_VER:  = %]
 %@VERBOSE_ON%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Find the Most Relevant Input List
 rem === Updated On: 15 Jan 2023 / 09 Mar 2017
 rem ==========================================================================
:FindList
 rem %1 = Variable Name
 rem %2 = Base Filename

 IF "%~2"=="" EXIT /B
 FOR %%I IN ("%@INPUT%%~2.TXT" "%@INPUT%%~2.%COMPUTERNAME%.TXT" "%@INPUT%%~2.%@CUSTOM_CONFIG%.TXT") DO IF EXIST "%%~I" SET @%~1=%%~I
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Query/Determine Console Session State
 rem === Updated On: 21 Jul 2024
 rem ==========================================================================
:SetConsoleSession
 rem %* = No Parameters Needed/Used

 SET @VALID_SESSIONS="Console" "RDP-TCP"
 SET @SERVICE_ACCTS="SYSTEM" "NTAUTHORITY" "%COMPUTERNAME%$"
 SET @SESSION_USER=%USERNAME%
 SET @SESSION_NAME=-& FOR /F "DELIMS=># " %%s IN ('QUERY SESSION 2^>NUL ^| FIND ">"') DO SET @SESSION_NAME=%%s
 SET @CONSOLE_SESSION=FALSE
	 IF NOT DEFINED USERNAME SET @CONSOLE_SESSION=FALSE
	 IF "%USERNAME:~-1%"=="$" SET @CONSOLE_SESSION=FALSE
	 IF "%@SESSION_NAME%"=="-" SET @CONSOLE_SESSION=FALSE
	 FOR %%s IN (%@VALID_SESSIONS%) DO IF /I "%@SESSION_NAME%"=="%%~s" SET @CONSOLE_SESSION=TRUE
	 FOR %%u IN (%@SERVICE_ACCTS%)  DO IF /I "%@SESSION_USER%"=="%%~u" SET @CONSOLE_SESSION=FALSE
 EXIT /B
                                                                