@ECHO OFF
 rem ==========================================================================
 rem === Generate System Uptime Report for Server Operations Team
 rem ==========================================================================
 rem
 rem Created On: 08 Sep 1998
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 03-04 Feb 2026 / 13 Jan 2026 / 01 Jan 2026 / 30 Oct 2025
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem    Unix Ports ............. https://sourceforge.net/projects/unxutils/
 rem
 rem    ADFind ................. http://www.joeware.net/freetools/tools/adfind/
 rem    Blat ................... http://www.blat.net/
 rem    DISKSPD ................ https://github.com/microsoft/diskspd
 rem    InfoZip Utilities ...... http://sourceforge.net/projects/infozip/files/
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html (no longer on their site)
 rem    UPTIME2 ................ https://techibee.com/tools/say-hello-to-uptime2-exe-alternative-for-uptime-exe/1728
 rem
 rem    PAEXEC ................. https://www.poweradmin.com/paexec/
 rem    PSTOOLS ................ https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem    UptimeList.TXT ......... List of Servers to Track for Uptime Monitoring
 rem    MonitoringConfig.TXT ... List of Enabled and Disabled Settings for Monitoring
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script is a derivative of the OPSLOGS.BAT script that focuses on
 :::  information relevant to uptime and availability.
 :::
 :::  This script requires the Windows Resource Kit as well as the list of
 :::  utilities linked above, such as BLAT, various PSTOOLS from SysInternals,
 :::  and ports of Unix utils (e.g. HEAD, TAIL). You can obtain more info on
 :::  these utilities at their respective sites.
 :::
 :::
 :::  ENUMERATING SYSTEMS IN THE DOMAIN
 :::  -------------------------------------------------------------------------
 :::  First we used NET VIEW, then we moved to NETDOM, but now we use ADFIND
 :::  from the excellent JoeWare utilities.  You can use /L to use a static
 :::  list of systems to scan, rather than enumerating the systems within your
 :::  domain.
 :::
 :::
 :::  INPUT FILES
 :::  -------------------------------------------------------------------------
 :::  A list of the servers should be placed in the INPUT folder. Also, the
 :::  "@Variables.BAT" file is needed from the INPUT folder in order to set all
 :::  of the global variables for this script, along with some of the other
 :::  scripts that can be found in the UTKB archive.   You are free to modify
 :::  any or all of the scripts to make them more independent.  At some point,
 :::  I need to document some of the recent changes in the "@Variables.BAT"
 :::  script which allow you to use custom input files for any given server,
 :::  without having to modify the scripts.  One such example is the ServerList
 :::  input file which is usually:  C:\Scripts\Bat\Input\ServerList.TXT
 :::
 :::  The custom version would contain the name of the current server as
 :::  follows:  C:\Scripts\Bat\Input\ServerList.localservername.TXT
 :::  e.g. C:\Scripts\Bat\Input\ServerList.SERVER1A.TXT
 :::
 :::
 :::  DEBUGGING YOUR SCRIPTS
 :::  -------------------------------------------------------------------------
 :::  You'll notice that there are several sections with %@PAUSE_IF_DEBUG% or
 :::  %@PRINT_IF_DEBUG% statements.  I tend to use these mechanisms quite a bit
 :::  in larger scripts.  This way, if the script fails to run properly, I
 :::  can go to a command prompt and issue the following command:
 :::  SET DEBUG=TRUE
 :::
 :::  Now, when I run the script in that command session, it will turn ECHO
 :::  on, and enable a PAUSE or delay after each major section, so that I can
 :::  see and review the output.  This is helpful for determining where things
 :::  are going wrong without having to go back into the script and add a bunch
 :::  of PAUSE statements manually.
 :::
 :::
 :::  CHANGE LOG NOTES
 :::  -------------------------------------------------------------------------
 :::  (Apr 2011) v3.1 -- Added a new *.ERRORS.TXT log that contains only the
 :::  lines in the report that have words like ERROR or FAILED. Provided as a
 :::  means to quickly spot-check the state of errors within the report.
 :::
 :::  (Apr 2011) v3.3 -- Added a platform indicator for each system to
 :::  indicate whether or not it is an x86 or x64 system.  Also added a
 :::  function to determine if the time setting on each machine is on track
 :::  with the time on the current system. If not, an OFFSET is displayed next
 :::  to the time and time zone info.
 :::
 :::  (Dec 2011) Simplified the job scheduling section by way of environment
 :::  variables for verifying whether to use SCHTASKS or the AT command.
 :::
 :::  (Dec 2012) Made it possible for the scheduled tasks to be stored in their
 :::  own folder, rather than the default root folder of the Task Scheduler.
 :::
 :::  (Oct 2013) v3.9 -- The delimiter for all parameters can be either the
 :::  "-" or the "/" character.  This includes the help parameters.
 :::
 :::  (Feb 2014) v3.12 -- Added the capability to send log data to one or more
 :::  Syslog servers using the SyslogGen or NeoLog utilities in conjunction
 :::  with the @SYSLOGx environment variables.
 :::
 :::  (Mar 2014) v3.13 -- Upgraded the DebugMode options to add another
 :::  variable (@PRINT_IF_DEBUG). Also revamped the routines for logging to
 :::  Syslog servers.
 :::
 :::  (Nov 2014) v4.0 -- Log files are now compressed before emailing, in
 :::  order to reduce attachment size.
 :::
 :::  (Dec 2014) v4.1 -- Added new logfile management.
 :::
 :::  (Mar 2015) v4.3 -- Update TITLE info; Added support for both the main
 :::  and MINI editions of the CustomVariables.TXT configuration files.
 :::
 :::  (Mar 2015) v4.4 -- Capture elapsed time between script routines using
 :::  an updated version of DATEINFO.
 :::
 :::  (Apr 2015) v5.0 -- Major changes to the routines associated with temp
 :::  file generation and log processing. Temp files are now placed into
 :::  timestamped folders to facilitate multiple instances of the job running
 :::  simultaneously. Configuration info is now derived from SetDrive.BAT
 :::  rather than from @Variables.BAT.
 :::
 :::  (Nov 2015) v5.2 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Dec 2015) v5.3 -- Will now set the RemoteRegistry service to AUTO and
 :::  start it, in order to facilitate several maintenance routines, including
 :::  system uptime and patch validation.
 :::
 :::  (Jan 2016) v5.4 -- Added checks for SystemState Backups, and other file
 :::  replication jobs.
 :::
 :::  (Feb 2016) v6.0 -- Eliminated the use of the @BIGLISTMIN variable;
 :::  Made substantial script changes to cut the total execution time by 50%:
 :::   --- Changed the NTP Events routine to run concurrently
 :::   --- Changed the Extended Uptime routine to run concurrently
 :::
 :::  (Mar 2016) v6.2 -- Streamlined the concurrency routines, and added
 :::  several new concurrency jobs, to improve the overall performance of the
 :::  information collection across multiple systems.
 :::
 :::  (Mar 2016) v6.3 -- Implemented enhanced diagnostics via v3.1 of the
 :::  DATEINFO utility;  Synchronized subroutines between all three of the
 :::  operations monitoring scripts: OpsLogs, SecurityLogs, UptimeReport
 :::
 :::  (Apr 2016) v6.4 -- Moved more diagnostics output to separate diagnostics
 :::  logfiles, based upon the value of the @SHOW_RUNNING and the existence of
 :::  the @EXTENDED_DIAG variable.
 :::
 :::  (Apr 2016) v6.6 -- Create summary zip file for emailing purposes (all
 :::  logs except the full detailed report).
 :::
 :::  (May 2016) v6.7 -- Added routines for verifying domain and computer
 :::  trust within Active Directory domains via the NETDOM utility;
 :::
 :::  (May 2016) v6.8 -- Expanded domain verification routines using NLTEST
 :::  and REPADMIN;
 :::
 :::  (Jun 2016) v6.9 -- Streamlined the processing of conditional assessments;
 :::  -- Added/modified several job concurrency routines;
 :::
 :::  (Apr 2017) v6.10 -- DATEINFO.exe has totally replaced DOFF.exe.
 :::
 :::  (Jan 2018) v6.12 -- Changed the HELP routine to use FINDSTR;
 :::  Migrated :SaveJobHistory to a subroutine, for additional flexibility;
 :::  Invalid job attempts are now recorded in the .RECORDING.TXT file.
 :::
 :::  (Feb 2018) v6.13 -- Changed Script Documentation to www.BrainWaveCC.com
 :::  -- Changed one instance of "FINDSTR /R" to "FIND" to avoid a parsing
 :::  problem with FINDSTR under certain builds of Windows 10 (first observed
 :::  under Version 1709).
 :::
 :::  (Apr 2018) v7.0 -- Replaced the troublesome UPTIME.EXE utility that
 :::  first came via the Windows NT Resource Kit with UPTIME2.EXE, which is
 :::  unfortunately somewhat less versatile in its reporting.  I'll get around
 :::  to developing my own UPTIME utility in a few months or so -- hopefully.
 :::
 :::  (Jun 2018) v7.1 -- Expanded JobHistory Routine to include SaveLogs;
 :::  -- Corrected an issue with UPTIME reporting (from UPTIME2.EXE);
 :::  -- Support for NeoLogger has been eliminated from this script;
 :::
 :::  (Jul 2018) v7.2 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v7.3 -- Removed AT command support;
 :::
 :::  (Sep 2018) v7.4 -- Added the -NoBanner parameter to supported SysInternals
 :::  utilities (e.g. PSINFO, PSLIST, etc);
 :::
 :::  (Oct 2018) v7.5 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Dec 2018) v8.0 -- Significantly overhauled the concurrency routines;
 :::  -- Changed concurrency processing from process based (HANDLE.EXE) to file
 :::  marker based (*.---) to improve performance, accuracy and stability;
 :::  -- Added exemption and max time options to the concurrency routines;
 :::  -- Replaced NETDOM / NET VIEW with ADFIND to generate dynamic device lists;
 :::  -- Added global @DNSDOMAINS variable for processing multiple AD domains;
 :::  -- Changed ECHO. to ECHO: for displaying blank lines;
 :::  -- Change Code Page to 437 to avoid problems with FINDSTR /R and some other
 :::  code pages;
 :::
 :::  (Feb 2019) v8.1 -- Added a check for missing Concurrency Script routines;
 :::  -- Move MBSA/WSUS cleanup routines to the beginning of the processing job;
 :::
 :::  (Feb 2019) v8.2 -- Display duration variance for each section as compared
 :::  to most recently completed job;
 :::
 :::  (Mar 2019) v8.3 -- Enabled Code Page 1252 Support;
 :::  -- Record additional attributes in the Job History log;
 :::  -- Prevent DEBUG MODE data from being stored in the .RECORDING.TXT file
 :::
 :::  (Sep 2019) v8.4 -- Use CHECKPARAMS to evaluate parameters besides /? /H;
 :::  -- Enhanced routine for displaying excessive process file handles;
 :::  -- Debut of SubString.exe to more easily manage string substitutions;
 :::
 :::  (Sep 2019) v8.5 -- Add A+ option to enable AD Info and override config settings;
 :::
 :::  (Oct 2019) v8.6 -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v9.0 -- Return of the MINI report (for large networks);
 :::  -- Increase Maximum Currency Jobs to 199 (from 99);
 :::  -- Ensure a single pass for each system through the concurrency routines;
 :::  -- Changed the :CheckJobHistory routine to run concurrently;
 :::
 :::  (Oct 2019) v9.1 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Oct 2019) v9.2 -- Change default dynamic list to Servers Only, and add
 :::  an option for stipulating a server and workstation dynamic list;
 :::
 :::  (Dec 2019) v9.3 -- Eliminate blank directories in SYSTEMSTATE reports;
 :::  Update script duration check in both parts of the concurrency routines;
 :::  Added the @MAX_SPAWN_TIME variable to control concurrency job initiation;
 :::
 :::  (Jan 2020) v9.4 -- Added new Time Calculation Subroutine;
 :::  -- Capture Mini CPU Benchmark Results (based on GetPrimeNumbers.exe);
 :::  -- Corrected the :GetParams routine to deal with quoted custom values;
 :::  -- Added a routine for validating integer parameters;
 :::  -- Refactored the :Prepare4Syslog routine;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::
 :::  (Feb 2020) v9.5 -- Refactored the time calculation routines;
 :::
 :::  (May 2020) v10.0 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::  -- Added :Get-DATEINFO routine to obtain detailed OS Build Info;
 :::  -- Added Remote Execution via PSEXEC, PAEXEC, and BeyondExec (in that order);
 :::  -- Added new input files (@OPSCONFIG and @TESTOPSCFG) to control which
 :::  monitoring routines are enabled or disabled in production and test modes;;
 :::  -- Changed default for Remote Execution from PAEXEC to PSEXEC to fix logging;
 :::  -- Log remote network sessions via NetSess.exe;
 :::  -- Removed obsolete/legacy routines;
 :::
 :::  (Jun 2020) v10.1 -- Updated :DisplayTitle routine to suppress STDERR output;
 :::  -- Updated :ComparePerformance to use new DATEINFO comparison feature;
 :::
 :::  (Jun 2020) v10.2 -- Added Sorted Output for CPU Benchmarking;
 :::  -- Added the option for custom MonitorConfig list;
 :::
 :::  (Jul 2020) v10.3 -- Streamline the search for memory dump files (*.DMP) in
 :::  conjunction with the StorageInfo.BAT script;
 :::
 :::  (Nov 2020) v10.4 -- SystemState Backups moved to \Backups$\SystemState;
 :::
 :::  (Nov 2020) v11.0 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Dec 2020) v11.1 -- Expanded Get-DATEINFO to obtain physical memory;
 :::
 :::  (Dec 2020) v11.2 -- Check if Windows Is Waiting on a Reboot;
 :::  -- The /UP2 parameter ensures the use of UPTIME2.EXE vs UPTIME.EXE;
 :::  -- The /UPL parameter ensures the use of the legacy Microsoft UPTIME.EXE;
 :::
 :::  (Jan 2021) v11.3 -- Display Disk I/O Calculations via Microsoft DiskSpd;
 :::  -- Display CPU benchmarks sorted (by time) and unsorted;
 :::
 :::  (Feb 2021) v11.4 -- Update CPU Benchmarks to include Multithreaded Results
 :::  using the new/updated BrainWave PrimePlus;
 :::
 :::  (Mar 2021) v11.5 -- Add GPO assessment and validation to the AD reporting;
 :::  -- Fixed an issue where scheduled jobs are saved with the /S option in them;
 :::  -- Streamline "Needs a Reboot" checking;
 :::
 :::  (Apr 2021) v11.6 -- Provide tally of the OS Version/Build;
 :::  -- Expanded header summary to include output and configuration file info;
 :::  -- Improve the condensed reporting format for SystemState backups;
 :::
 :::  (Nov 2021) v11.7 -- Delete All Temp MSBA/WSUS Files at start, regardless of age;
 :::
 :::  (Jan 2022) v12.0 -- Added a routione for Remote System Validation Checks;
 :::  -- Modify the @NAMECHK verification to include \ prefix;
 :::  -- Corrected and expanded sorting in CPU Benchmark summary;
 :::
 :::  (Feb 2022) v12.1 -- Added a routine to capture and display machine serial#;
 :::
 :::  (May 2022) v12.2 -- Added the @NEEDS_REBOOT variable to the OS info routine;
 :::
 :::  (Oct 2023) v12.3 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::  -- Added more flexibility in the Concurrency Scripts by way of @MAX_RUN_TIME;
 :::
 :::  (Jan 2024) v12.4 -- Eliminate BeyondExecv2 and favor PAEXEC for remote access;
 :::
 :::  (Mar 2024) v13.0 -- Added several support routines for summary reporting;
 :::  -- Added the @PATCH_LIST variable to highlight systems needing to be patched;
 :::  -- Added the @REBOOT_LIST variable to highlight systems needing a reboot;
 :::  -- Updated the :VerifyAccess routine and applied it to Concurrency routines;
 :::
 :::  (Apr 2024) v13.1 -- Changed log generation order to streamline log review;
 :::  -- Correct deficiency in /A+ and /A- parameters and how AD Info is checked;
 :::  -- Add a clean-execution mode to the concurrency routines;
 :::
 :::  (May 2024) v13.2 -- Check for essential utilities with FINDFILES;
 :::  -- Tracking Old User and Machine Accounts via NetPWage;
 :::  -- Added file validation to Concurrency scripts via FINDFILES;
 :::  -- Added PID info to the checks for excess file handles;
 :::  -- Added logging when (un)scheduling jobs;
 :::
 :::  (May 2024) v13.3 -- Added Domain Controller counts for the AD routines;
 :::  -- Added count and summary for tracking domain trust issues;
 :::  -- Allow Monitor config settings to be overridden at command prompt;
 :::
 :::  (Jun 2024) v13.4 -- Expanded time tracking within each concurrency section;
 :::  -- Add Release Date of Current Windows Build to Output;
 :::  -- Streamline the serial# acquisition process via DATEINFO;
 :::
 :::  (Jul 2024) v13.5 -- Streamlined the accessibility verification routines;
 :::  -- Replaced the :RunCMD routine with just a CALL command;
 :::  -- Capture primary Private and Public IP Addresses of monitoring system;
 :::
 :::  (Sep 2024) v13.6 -- Check for running AV/Endpoint Protection processes;
 :::  -- Check for running OS and Application patch management processes;
 :::  -- Provide a limited testing mode with special settings enabled: /QA;
 :::  -- Refactoring of the scheduled jobs verification routine;
 :::  -- Extended :ForwardToSyslog to update any locally running syslog service;
 :::
 :::  (Sep 2024) v13.7 -- Create Unicode Logs with a new utility: WriteBOM.exe;
 :::  -- Created :LogCriticalFailure routine for early job failures;
 :::  -- Removed :ChangeCodePage routine;
 :::
 :::  (Feb 2025) v13.8 -- Process string tokens accurately via a new utility: FindToken.exe;
 :::  -- New data capture with MiTec System Information X utility (incomplete);
 :::
 :::  (Jul 2025) v13.9 -- Ensure that logs are consistently generated in UTF8;
 :::  -- Added checks for WMIC.exe since Microsoft has deprecated it in Windows;
 :::  -- Refactor subroutines related to obtaining and displaying serial numbers;
 :::
 :::  (Aug 2025) v13.10 -- Corrected error the generated invalid count for @LIVESYS;
 :::
 :::  (Aug 2025) v14.0 -- Added aggregated per-server time tracking statistics;
 :::  -- Streamlined the UPTIME2 process by running it via remote shell;
 :::
 :::  (Sep 2025) v14.1 -- Generate hashes of zipped integrity logs to email;
 :::  -- Streamline file handle notification processing;
 :::
 :::  (Oct 2025) v14.2 -- Replaced instances of HEAD/TAIL/TYPE with READABLE;
 :::  -- Expanded the logging of time for the ADINFO routines;
 :::
 :::  (Oct 2025) v14.3 -- Added Config File Sizes to Summary Info;
 :::  -- Try to install the now deprecated WMIC via DISM if not found in path;
 :::
 :::  (Jan 2026) v14.4 -- Update Syslog logging routine for script metrics;
 :::
 :::  (Feb 2026) v14.5 -- Streamline system looping procedures for all evaluations;
 ::: -- Track non-domain devices via @BASIC_SCANS for network-based evaluations;
 ::: -- Add a PING and TRACERT concurrency routine for non-nMap connectivity tests;
 :::
 :::
 :::  WINDOWS SHELL SCRIPTING RESOURCES:
 :::  -------------------------------------------------------------------------
 :::  CMD and Powershell syntax ...... https://ss64.com/
 :::  Windows Shell Scripting Tips ... https://www.dostips.com/
 :::  Batch Script Linter ............ https://github.com/tboy1337/Blinter/
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 07 Jun 2020 / 11 Apr 2018
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 03-04 Feb 2026 / 29 Sep 2025 / 01 Sep 2025 / 29 Aug 2025
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v14.5.0.3155

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT" CCALC.EXE CHANGECASE.EXE FILEHASH.EXE FINDTOKEN.EXE MAKESTRING.EXE READABLE.EXE SUBSTRING.EXE WRITEBOM.EXE
 SET #MSUTILS=FINDSTR.EXE PING.EXE TRACERT.EXE SCHTASKS.EXE WHERE.EXE
 SET #O_UTILS=BLAT.EXE SYSLOGGEN.EXE ZIP.EXE
 SET @ADUTILS=NETDOM NLTEST REPADMIN GPOTOOL NETPWAGE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS% -o %@ADUTILS% RESOLVE.EXE CURL.EXE
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES & GOTO :ExitBatch)

 rem -- Main Variables
 SET @CMDLINE=%CMDCMDLINE% %0 %*
 SET @PARAMS=%*
 SET @QATEST=
 SET @DIAGMODE=
 SET @EXTENDED_DIAG=
 SET @NEWLOG=FALSE
 SET @HISTORY=6
 SET @PURGE_TEMP=TRUE
 SET @KEEP_TEMP=7
 SET @SECTIONS=0
 SET @PROC_LIMIT=30
 SET @CONCURRENCY=TRUE
 SET @HIGH_CONCURRENCY=FALSE
 SET @SHOW_RUNNING=FALSE
 SET @RUNONCE=
 SET @QUERY_AD=TRUE
 SET @NO_AD=-- Queries to Active Directory have been disabled, or NETDOM.EXE could not be found
 SET @NO_NETDOM=-- NETDOM Domain Trust assessment is disabled, or NETDOM.EXE could not be found
 SET @NO_WMIC=-- WMI Command line is disabled, or WMIC.EXE could not be found
 SET @RUN_WMIC=TRUE
 SET @EPP_PROCESSES=MsMpEng MpDefenderCoreService MsSense NisSrv
 SET @PATCH_PROCESSES=NiniteAgent DCAgentService Action1
 SET @TINY_TIME=00:01:00
 SET @SHORT_TIME=00:10:00
 SET @MAX_RUN_TIME=01:00:00
 SET @MAX_SPAWN_TIME=00:10:00
 SET @TREE_REGEX="|.*|.*[|+\\] \.SAFE Folder.PATH Volume.serial ---InstallRoot ---Logs ---Database _vti_"
 SET @MINI_REGEX="|.*|.*[|+\\] \[..\...\...\] \\....-..-.. 2.......-......\. 2...-..-.. \\WINS_ \\SystemState- _PGP _gnupg \\ZIA \.7Z \.ZIP \.TAR \.TGZ \.GZ"
 SET @FULL_REGEX="|.*|.*[|+\\] \[..\...\...\] \\....-..-.. 2.......-......\.            \\WINS_ \\SystemState- _PGP _gnupg"
 SET @ERROR_TOKENS="failed failure. error denied PATCHING --LOW-- \*\*\*.UNABLE UNAVAILABLE Risk\> Severe Critical NO.VALID Insecure.certificate.signature SSLv3"
 SET @SUCCESS=The command completed successfully
 SET @VERIFIED= has been verified.
 SET @DEFAULT=*** DEFAULT ***
 SET @SCRIPT_TOKENS=#LOCAL# #REMOTE_REG#
 SET @PRIME_LIMIT=1000000000
 SET @ADQUERY_O=%@ADQUERY_S%
 SET @DEFAULT_CONFIG=ADINFO OSPLATFORM SYSTIME UPTIME_SUMMARY BOOTTIME CPUBENCH MEMDUMP HANDLES SSBACKUPS_SUMMARY NTP TRUSTS PROCINFO_BW JOBHISTORY UPTIME
 SET @BW_PARAMS=--Script-Variables --No-Symbols

 rem -- Checksum Variables for Log Validation
 SET @VALID_HASHES=MD5 SHA1 SHA2 SHA3 SHA256 BLAKE2 BLAKE3
 SET @LOG_HASH=BLAKE3

 rem -- Time and Date Formats for DATEINFO-related Subroutines
 SET @TIMEFORMAT="mm/dd/yyyy hh:nn:ss.zz"
 SET @TIME1FMT=-e "000:min:sec.ms"
 SET @TIME2FMT=-f "hh:nn:ss.zz"
 SET @AGGREGATE=-e "###:min:sec.ms" -o "\\\-\\--- [#ZZ] \v - *** AGGREGATE JOB TIME ***\n\\\-"
 SET @TRACK_METRICS=TRUE

 rem -- IP Address Info
 SET @PRIVATE_IP={UNKNOWN}
 SET @PUBLIC_IP={UNKNOWN}
 SET @FIND_PUBLIC_IP=https://ipinfo.io/ip

 rem -- Concurrent Job Variables
 SET @FLAG=.---
 SET @DONE=.~~~

 rem -- Job Scheduling Variables
 SET @JOBNAME=Daily Uptime Report
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=04:01:00
 SET @JOBDATE=
 SET @JOBPATH="%~f0" %@PARAMS%
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Set Job Specific Information, Including Valid @MACHINELIST Variable
 SET @MACHINELIST=%@UPTIMELIST%
 SET @MONITORCFG=%@OPSCONFIG%
 SET @LOGNAME=UptimeReport
 SET @JOBINFO_F=Complete %@JOBNAME% from %COMPUTERNAME% for %@TODAY%
 SET @JOBINFO_S=%@JOBINFO_F:Complete=Summary%
 SET @JOBINFO_P=%@JOBINFO_F:Complete=Partial%
 SET @FINAL=*FINAL*

 rem -- Standard Log Variables
 SET @LOGPATH=%@LOGBASE%\%@LOGNAME%
 SET @TMPPATH=%@LOGPATH%\%@DIRSTAMP_R%
 SET @LFORMAT=%@LOGPATH%\%@LOGNAME%
 SET @TIMINGS="%@LFORMAT%.RECORDING.TXT"
 SET @LOGFILE="%@LFORMAT%.%@FILESTAMP%"
 FOR %%L IN (TESTLOG ERRORS SUMMARY PARTIAL DIAGLOG TEMPLOG SORTLOG CHECKSUM) DO SET @%%L="%@LFORMAT%.%%L.%@FILESTAMP%"
 SET @LOGLIST=%@LOGFILE% %@ERRORS% %@DIAGLOG% %@SUMMARY% %@TESTLOG%
 SET @CLEANUP=%@TEMPLOG% %@ERRORS% %@DIAGLOG% %@PARTIAL% %@SORTLOG%
 SET @CORELOGS=%@TIMINGS% %@SUMMARY% %@ERRORS% %@DIAGLOG% %@LOGFILE%
 SET @TINYZIP="%@ZIPPATH%\%COMPUTERNAME%-%@LOGNAME%.PARTIAL.%@ZIPSTAMP%"
 SET @FULLZIP=%@TINYZIP:.PARTIAL.=.%
 SET @OLDPERF="%@LOGPATH%\PERFORMANCE.OLD"
 SET @NEWPERF="%@LOGPATH%\PERFORMANCE.NEW"
 SET @DBGPATH=%TEMP%\%~n0.%@DIRSTAMP_R%
 SET @MINDIV=\%@DIVIDER-:~-77%\
 SET @MAXDIV=\%@DIVIDER:~-77%\

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*& CALL :SwapCharacters @ALL_PARAMS "=" ":"
 CALL :GetParams "S"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Schedule Job Only;&          SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE& CALL SET @JOBPATH=%%@JOBPATH:!@USED!=%%)
 CALL :GetParams "U"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Unschedule Job Only;&        SET @UNSCHED=TRUE)
 CALL :GetParams "N"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Run w/o Scheduling;&         SET @NOSCHED=TRUE)
 CALL :GetParams "D DIAG"    & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Diagnostics Mode;&           SET @DIAGMODE=TRUE)
 CALL :GetParams "QA QATEST" & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Enable QA Testing;&          SET @DIAGMODE=TRUE& SET @QATEST=TRUE)
 CALL :GetParams "M"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Only Send Mail;&             SET @MAILONLY=TRUE)
 CALL :GetParams "Q"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Don't Send Mail;&            SET @NOMAIL=TRUE)
 CALL :GetParams "L"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Use Static List;&            SET @NEWLOG=FALSE)
 CALL :GetParams "G"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Make Dynamic Server List;&   SET @NEWLOG=TRUE& SET @ADQUERY_O=%@ADQUERY_S%)
 CALL :GetParams "GW"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Make Dynamic System List;&   SET @NEWLOG=BOTH& SET @ADQUERY_O=%@ADQUERY_N%)
 CALL :GetParams "UPL"       & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Use Legacy UPTIME.EXE;&      SET @USE_UPTIME_LEGACY=TRUE)
 CALL :GetParams "UP2"       & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Use UPTIME2.EXE;&            SET @USE_UPTIME_LEGACY=FALSE)
 CALL :GetParams "C"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Purge Temp Folder;&          SET @PURGE_TEMP=TRUE)
 CALL :GetParams "IM+"       & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Track Individual Metrics;&   SET @TRACK_METRICS=TRUE)
 CALL :GetParams "IM-"       & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Disable Individual Metrics;& SET @TRACK_METRICS=)
 CALL :GetParams "A+"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Get AD Domain Info;&         SET @QUERY_AD=TRUE)
 CALL :GetParams "A-"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! No AD Domain Info;&          SET @QUERY_AD=)
 CALL :GetParams "P+"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Enable Concurrency;&         SET @CONCURRENCY=TRUE)
 CALL :GetParams "P-"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Disable Concurrency;&        SET @CONCURRENCY=FALSE)
 CALL :GetParams "HC"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! High Concurrency;&           SET @HIGH_CONCURRENCY=TRUE)
 CALL :GetParams "R+"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Show Concurrency Log;&       SET @SHOW_RUNNING=TRUE)
 CALL :GetParams "R-"        & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Hide Concurrency Log;&       SET @SHOW_RUNNING=FALSE)
 CALL :GetParams "T"         & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Use Test List;
	 SET @MACHINELIST=%@TESTSRVLIST%
	 SET @MONITORCFG=%@TESTOPSCFG%
	 SET @LOGFILE=%@TESTLOG%
	 SET @RCPT-TO=%@TEST-RCPTS%
 )

 rem -- Set Variables for Test Configurations
 IF /I "%@DIAGMODE%"=="TRUE" (
	 CALL :GetInteger @MINROWS "%@T_MIN_LOG_ROWS%" 003 001 010
	 CALL :GetInteger @MAXROWS "%@T_MAX_LOG_ROWS%" 030 010 049
	 SET DEBUG=COPY
	 SET @SHOW_RUNNING=TRUE
	 SET @EXTENDED_DIAG=TRUE
	 SET @MONITORCFG=%@TESTOPSCFG%
	 SET @MAILSENDER=LogAdmin-Test%@ORGFQDN%
	 SET @RCPT-TO=%@TEST-RCPTS%
	 SET @ALERT-TO=%@TEST-RCPTS%
	 SET @NOSCHED=TRUE
	 SET @NMAP_TIME=00:05:00
	 SET @MAX_RUN_TIME=00:10:00
	 SET @MAX_SPAWN_TIME=00:02:00

	 rem -- Set Variables for QA Testing
	 IF /I "%@QATEST%"=="TRUE" (
		 SET @RUNMODE=!@RUNMODE! // QA-TESTING
		 SET @RUN_NMAP=
		 SET @QUERY_AD=
		 SET @CONCURRENCY=TRUE
		 SET @HIGH_CONCURRENCY=TRUE
		 SET @LOGFILE=%@TESTLOG%
		 SET @MACHINELIST=%@TESTSRVLIST%
		 IF DEFINED @MAIL_OVERRIDE (SET @NOMAIL=FALSE) ELSE (SET @NOMAIL=TRUE)
	 ) ELSE (
		 SET @DOMAINS=%@DOMAINS% TEST
		 SET @RUNMODE=!@RUNMODE! // TESTMODE
	 )
 )

 rem -- Process Special Command-line Parameters (Continued -- overrides other assigments)
 CALL :GetParams "RC" & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Use Regular Config List;&  SET @MONITORCFG=%@OPSCONFIG%)
 CALL :GetParams "LC" & IF DEFINED @OK (SET @NOTICE=!@NOTICE! Use Limited Config List;&  SET @MONITORCFG=%@TESTOPSCFG%)

 CALL :GetParams "CL CUSTOM"  @CUSTOM_SVR_LIST & IF DEFINED @CUSTOM_SVR_LIST (SET @NOTICE=!@NOTICE! Use Custom Server List;&  SET @MACHINELIST=!@CUSTOM_SVR_LIST!& SET @TESTSRVLIST=!@CUSTOM_SVR_LIST!& SET @NEWLOG=FALSE)
 CALL :GetParams "CC CUSTCFG" @CUSTOM_CFG_LIST & IF DEFINED @CUSTOM_CFG_LIST (SET @NOTICE=!@NOTICE! Use Custom Config List;&  SET @MONITORCFG=!@CUSTOM_CFG_LIST!&  SET @TESTOPSCFG=!@CUSTOM_CFG_LIST!)

 rem -- Check for Valid Monitor Configuration List
 IF EXIST "%@MONITORCFG%" (
	 FOR /F "TOKENS=*" %%P IN ('READCONFIG "%@MONITORCFG%" -F "%~n0" 2^>NUL') DO CALL %%P
 ) ELSE (
	 FOR %%M IN (%@DEFAULT_CONFIG%) DO SET *%%~M=TRUE
 )

 rem -- Calculate Oldest Viable Patch Date (Min=30 / Max=60)
 CALL :GetInteger @PATCHTIME    "%@PATCHTIME%"    030 001 090
 CALL :GetInteger @PATCHTIMEMAX "%@PATCHTIMEMAX%" 060 010 366
 FOR /F %%D IN ('DATEINFO -p "%@PATCHTIMEMAX%" -q 2^>NUL') DO SET @OLD_PATCH_DATE=%%D

 rem -- Check for Special AD Admin Utilities
 FOR %%U IN (%@ADUTILS%) DO (SET @HAS_%%~U=& FOR /F "TOKENS=*" %%F IN ('FINDFILES -F %%~U 2^>NUL') DO SET @HAS_%%~U=TRUE)

 rem -- Determine if aggregated, per-server time tracking statistics should be tracked
 IF DEFINED @TRACK_METRICS (SET @TRACK_TIME=CALL :TrackDuration) ELSE (SET @TRACK_TIME=rem CALL :TrackDuration)

 rem -- Ensure Valid Checksum Variable
 SET @GOODHASH=& FOR %%C IN (%@VALID_HASHES%) DO IF /I "%%~C"=="%@LOG_HASH%" SET @GOODHASH=TRUE
 IF NOT DEFINED @GOODHASH SET @LOG_HASH=BLAKE3

 rem -- Determine Which Logs to Use for Concurrency Diagnostics
 SET @BROADCAST=CON %@LOGFILE% %@DIAGLOG%
 IF /I "%@SHOW_RUNNING%"=="TRUE" (SET @THESE_LOGS=%@BROADCAST%) ELSE (SET @THESE_LOGS=%@DIAGLOG%)
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Identify/Validate Various Executable Paths (nMap, WMIC, etc)
 rem === Updated On: 30 Oct 2025 / 07 Jul 2025
 rem ==========================================================================
:Check4These

 rem -- WMIC
 FINDFILES --RC -F WMIC.EXE || DISM /Online /Add-Capability /CapabilityName:WMIC || SET @RUN_WMIC=
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 10 May 2024 / 22 Jan 2022 / 15 Sep 2019
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

 rem -- Check to Remove Scheduled Job
 IF /I "%@UNSCHED%"=="TRUE" (
	 SCHTASKS /DELETE /TN "!@TASKFOLDER!%@JOBNAME%" %@FORCE% 2>NUL
	 ECHO Task has been UNscheduled.  Now exiting script...
	 CALL :SaveJobHistory JOB UNSCHEDULED ONLY
	 GOTO :ExitBatch
 )

 rem -- Check for Schedule Update Parameters
 IF /I "%@UPDATESCHED%"=="TRUE" (!@SET_SCHED!) ELSE (CALL :CheckSched "%~f0")
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
 rem === Delete Any Old Existing Temp Folders Before Execution [Keep Last 7]
 rem === Updated On: 09 Apr 2017 / 12 Apr 2016
 rem ==========================================================================
:DeleteOldFolders
 IF /I "%@MAILONLY%"=="TRUE" GOTO :SendLog

 rem -- Create/Clean Necessary Folders
 FOR %%D IN ("%@LOGPATH%" "%@TMPPATH%" "%@DBGPATH%") DO IF NOT EXIST %%D MD %%D >NUL
 FOR %%D IN (DAT TMP TIM BAT) DO IF EXIST "%@LOGPATH%\*.%%~D" DEL "%@LOGPATH%\*.%%~D" >NUL

 IF /I "%@PURGE_TEMP%"=="TRUE" (
	 SET @TEMP_CHECK=~
	 IF DEFINED @KEEP_TEMP FOR /L %%I IN (0,1,%@KEEP_TEMP%) DO FOR /F %%D IN ('DATEINFO -s -p %%I -f "yyyymmdd" -q') DO SET @TEMP_CHECK=!@TEMP_CHECK! %%D
	 ECHO:
	 ECHO Cleaning Old Temp Folders...
	 FOR /F "TOKENS=*" %%D IN ('DIR /B /AD "%@LOGPATH%" ^| FINDSTR /V "!@TEMP_CHECK!"') DO (
		 ECHO  - Deleting: %@LOGPATH%\%%~D
		 RD /S /Q "%@LOGPATH%\%%~D"
	 )
	 ECHO %@DIVIDER-%
	 ECHO:
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Log Header
 rem === Updated On: 02 Sep 2025 / 09 Jul 2025 / 29 Sep 2024 / 28 Jul 2024
 rem ==========================================================================
:InitialLogHeader
 FOR /F "TOKENS=*" %%I IN ('RESOLVE %COMPUTERNAME% 2^>NUL') DO SET @PRIVATE_IP=%%~I
 FOR /F "TOKENS=*" %%I IN ('CURL %@FIND_PUBLIC_IP% 2^>NUL') DO SET @PUBLIC_IP=%%~I

 FOR %%L IN (%@ERRORS% %@DIAGLOG% %@PARTIAL%) DO WRITEBOM "%%~L"
 WRITEBOM "%@LOGFILE%" "!DATE! at !TIME: =0! -- %@SCRIPTVER_UNC%"
 ( rem -- Write to Log
	 ECHO %@LOGNAME% repository found here: \\%COMPUTERNAME%\LOGS$\%@LOGNAME%
	 ECHO Private IP address: %@PRIVATE_IP%  /  Public IP address: %@PUBLIC_IP%
	 ECHO:
	 ECHO %@DIVIDER*%
	 ECHO *** SYSTEM UPTIME REPORT for %@ORGNAME% [%@SYSENVIRONMENT%]
	 ECHO ***
	 ECHO *** For questions/comments/complaints, contact %@ORGADMIN%
	 ECHO ***
	 ECHO *** Please identify and remediate any configuration discrepancies...
	 ECHO ***
	 ECHO ***
	 ECHO *** Additional BWCC script documentation can be found at:
	 FOR %%R IN (%@SCRIPT_DOCS%) DO ECHO *** -- %%~R
	 ECHO ***
	 ECHO %@DIVIDER*%
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate List Of Servers using ADFIND
 rem === Updated On: 20 Oct 2019 / 18 Feb 2019
 rem ==========================================================================
:GetList
 IF NOT EXIST "%@MACHINELIST%" SET @NEWLOG=TRUE
 FOR %%V IN ("" FALSE) DO IF /I "%@NEWLOG%"=="%%~V" GOTO :#GetList

:NewLog
 ECHO Generating New Server List...
 CALL :AppendDate "%@MACHINELIST%" @SAVELIST
 FOR %%D IN (%@DNSDOMAINS%) DO (
	 CALL :GetDomainName %%D
	 FOR /F %%M IN ('ADFIND !@BASEDN! %@ADQUERY_D:$$$=^!%') DO ECHO \\%%~M >>"%@MACHINELIST%"
	 FOR /F %%M IN ('ADFIND !@BASEDN! %@ADQUERY_O:$$$=^!%') DO ECHO \\%%~M >>"%@MACHINELIST%"
 )

 FC "%@MACHINELIST%" "%@SAVELIST%" | FIND /I "%@NODIFF%" >NUL
 ( rem -- Write to Log
	 IF ERRORLEVEL 1 (
		 ECHO *** LIST OF SERVERS HAS CHANGED *** >CON
		 ECHO *** LIST OF SERVERS HAS CHANGED ***
		 ECHO:
	 ) ELSE (
		 DEL "%@SAVELIST%"
	 )
 ) >>%@LOGFILE% 2>&1
:#GetList
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Initialize Looping Variables and process Limited Scan list
 rem === Updated On: 03 Feb 2026
 rem ==========================================================================
:ListProcessingVars
 SET @BASIC_ONLY=0
 SET @MACHINE_LOOP#=FOR /F "USEBACKQ EOL=;" %%s IN ("%@MACHINELIST%") DO
 SET @MACHINE_LOOP$=%@MACHINE_LOOP#% IF NOT DEFINED @LIMITED_%%~s

 rem -- Generate Limited Scan List
 FOR %%Z IN (%@BASIC_SCANS%) DO (
	 SET /A @BASIC_ONLY+=1
	 SET    @LIMITED_%%~Z=****
	 SET    @LIMITED_\\%%~Z=****
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Get List Count and Maximum Length of All System Names in Server List
 rem === Updated On: 03-04 Feb 2026 / 24 Jan 2022 / 06 Oct 2019
 rem ==========================================================================
:GetMaxNameLen
 SET @MAXLEN=0
 SET @NUMSYS=0
 SET @ALLSYS=0
 SET @SKIPPED=0
 SET @BASIC_LIST=
 %@MACHINE_LOOP#% (
	 SET /A @ALLSYS+=1& IF NOT DEFINED @LIMITED_%%~s SET /A @NUMSYS+=1
	 SET @LEN=
	 SET @STRING=%%~s
	 FOR /L %%Z IN (0,1,17) DO IF NOT "!@STRING:~%%~Z,%%~Z!"=="" SET @LEN=%%~Z
	 IF DEFINED @LEN SET /A @LEN+=1
	 IF !@LEN! GTR !@MAXLEN! SET @MAXLEN=!@LEN!
	 FOR %%Z IN (%@BASIC_SCANS%) DO IF /I "!@STRING:\=!"=="%%~Z" (SET /A @SKIPPED+=1& SET @BASIC_LIST=!@BASIC_LIST! %%~Z)
 )
 SET /A @MAXLEN+=10
 SET /A @CPU_SORT1=@MAXLEN + 22
 SET /A @CPU_SORT2=@MAXLEN + 9
 SET /A @CPU_SORT3=@MAXLEN + 26
 IF /I "%@MACHINELIST%"=="%@TESTSRVLIST%" IF !@NUMSYS! GEQ 10 (SET /A @PROC_LIMIT=@NUMSYS / 2) ELSE (SET @PROC_LIMIT=2)
 IF /I "%@HIGH_CONCURRENCY%"=="TRUE" SET @PROC_LIMIT=199
 IF 1%@PROC_LIMIT% GEQ 199 SET @PROC_LIMIT=199
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Initial Summary, Error and Diagnostics Logfiles
 rem === Updated On: 03-04 Feb 2026 / 30 Oct 2025 / 27 Sep 2024 / 06 Apr 2021
 rem ==========================================================================
:GenerateBaseLogs
 CALL :GetFileSize @MC "%@MONITORCFG%"
 CALL :GetFileSize @ML "%@MACHINELIST%"
 CALL :GetFileSize @BL "%@BUILDINFO-LATEST%"

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER*%
	 ECHO *** PRIMARY OUTPUT FILE ... %@LOGFILE%
	 ECHO *** CONFIGURATION FILE .... %@MC%
	 ECHO *** LIST OF SYSTEMS ....... %@ML%
	 ECHO *** LIST OF OS VERSIONS ... %@BL%
	 ECHO *** TOTAL # OF SYSTEMS .... %@NUMSYS% / %@ALLSYS%
	 ECHO *** BASIC SCANS ONLY ...... %@SKIPPED%  %@BASIC_LIST%
	 ECHO *** MAX JOB CONCURRENCY ... %@PROC_LIMIT%
	 IF NOT DEFINED @NOTICE SET @NOTICE= NONE
	 ECHO *** SELECTED PARAMETERS ... %@PARAMS%
	 ECHO *** ENABLED OPTIONS .......!@NOTICE!
	 ECHO %@DIVIDER*%
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 FOR %%O IN (%@SUMMARY% %@DIAGLOG% %@ERRORS% CON) DO TYPE %@LOGFILE% >>%%O 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Temp Script for Concurrency Jobs
 rem === Updated On: 04 Feb 2026 / 30 Aug 2025 / 18 Aug 2025 / 13 Jul 2025
 rem ==========================================================================
:GenerateTempScripts
 CALL :Heading GENERATE CONCURRENCY SCRIPTS
 CALL :Make-Concurrency-Script "BWSYSINFO" DATEINFO "%@BW_PARAMS%" #LOCAL#
 CALL :Make-Concurrency-Script "GETSYS" GETSYS "/so /ld /na /la /id /usb" #LOCAL#
 CALL :Make-Concurrency-Script "JOBHISTORY" XCOPY "%%%%~1\Logs$\*.RECORDING.TXT %@TMPPATH%\%%%%~1 /I /C /S"
 CALL :Make-Concurrency-Script "NTP1" W32TM "/QUERY /COMPUTER:%%%%@LSERVER%%%% /CONFIGURATION"
 CALL :Make-Concurrency-Script "NTP2" PSLOGLIST "%@PSACCEPT% %%%%~1 -I 11,17,22,29,35,37,38,47,50 -D 1"
 CALL :Make-Concurrency-Script "PSLIST1" PSLIST "%@PSPARAMS% %%%%~1"
 CALL :Make-Concurrency-Script "SYSINFO" SYSTEMINFO "/S %%%%~1"

 CALL :Make-Concurrency-Script "PING" PING "%%%%@LSERVER%%%%"
 CALL :Make-Concurrency-Script "TRACEROUTE" TRACERT "%%%%@LSERVER%%%%"

 IF /I "%@USE_UPTIME_LEGACY%"=="TRUE" (
	 CALL :Make-Concurrency-Script "UPTIME1" UPTIME "%%%%~1"              #REMOTE_REG#
	 CALL :Make-Concurrency-Script "UPTIME2" UPTIME "%%%%~1 /P:%@AGE% /A" #LOCAL#
 ) ELSE (
	 CALL :Make-Concurrency-Script "UPTIME1" UPTIME2 "/NOLOGO /COMPUTERNAME:%%%%@LSERVER%%%%"           #REMOTE_REG#
	 CALL :Make-Concurrency-Script "UPTIME2" UPTIME2 "/NOLOGO /COMPUTERNAME:%%%%@LSERVER%%%% /S:%@AGE%" #LOCAL#
 )

 rem -- Copy Scripts for Debug Purposes
 IF /I "%DEBUG%"=="COPY" (
	 ECHO Making Debug Copy of Concurrency Scripts...
	 ECHO %@DIVIDER-%
	 COPY "%@TMPPATH%\*.BAT" "%@DBGPATH%" /Y
	 ECHO %@DIVIDER-%
	 ECHO:
 )

 FOR /F "TOKENS=1* DELIMS=@= " %%S IN ('SET "@@" 2^>NUL') DO (
	 SET @NAME=%%S!@DOTS!
	 ECHO  !@NAME:~0,20!%%T >>%@LOGFILE% 2>NUL
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Get Hardware, Software and Network Status for Each System
 rem === Updated On: 03-04 Feb 2026 / 13 Jul 2025 / 07 Jul 2025 / 19 Sep 2024
 rem ==========================================================================
:SystemInfo
 rem -- Please use [] or {} rather than "()" in the HEADING titles/descriptions...

 IF DEFINED *ADINFO (
	 CALL :Heading VERIFY ACTIVE DIRECTORY INFO
	 IF DEFINED @QUERY_AD (
		 FOR %%s IN (%@DOMAINS%) DO CALL :GetADInfo %%~s
	 ) ELSE (
		 FOR %%O IN (CON %@LOGFILE%) DO ECHO  %@NO_AD% >>%%O 2>&1
	 )
 )

	 CALL :Heading INITIALIZE SYSTEM VARIABLES*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "BWCC System Info"      BWSYSINFO
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Microsoft System Info" SYSINFO

 IF DEFINED *TRUSTS (
	 CALL :Heading VERIFY DOMAIN TRUST
	 IF DEFINED @HAS_NETDOM (
		 %@MACHINE_LOOP$% CALL :VerifyTrusts %%~s
		                  CALL :VerifyTrusts ----
	 ) ELSE (
		 FOR %%O IN (CON %@LOGFILE%) DO ECHO  %@NO_NETDOM% >>%%O 2>&1
	 )
 )

 IF DEFINED *SERIALNUM (
	 CALL :Heading MACHINE SERIAL NUMBER [via BWSYSINFO]
	 %@MACHINE_LOOP$% CALL :SerialNumber %%~s
 )

 IF DEFINED *OSPLATFORM (
	 CALL :Heading WINDOWS OS VERSION AND ARCHITECTURE
	 %@MACHINE_LOOP$% CALL :OSPlatform %%~s
	                  CALL :OSPlatform ----
 )

 IF DEFINED *SYSTIME (
	 CALL :Heading CURRENT SYSTEM TIME
	 %@MACHINE_LOOP$% CALL :SystemTime %%~s
 )

 IF DEFINED *UPTIME_SUMMARY (
	 CALL :Heading SYSTEM UPTIME [BASIC]*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Basic Uptime Info" UPTIME1
	 %@MACHINE_LOOP$% CALL :UpTime %%~s
	                  CALL :UpTime ----
 )

 IF DEFINED *BOOTTIME (
	 CALL :Heading SYSTEM UPTIME / BOOT TIME
	 %@MACHINE_LOOP$% CALL :BootTime %%~s
 )

 IF DEFINED *SHOWMEM (
	 CALL :Heading SYSTEM MEMORY [via SYSTEMINFO]
	 %@MACHINE_LOOP$% CALL :ShowMem %%~s
 )

 IF DEFINED *ENDPOINT_PROTECTION (
	 CALL :Heading ENDPOINT PROTECTION PROCESS*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Running Processes" PSLIST1
	 %@MACHINE_LOOP$% CALL :EndPointProtection %%~s
 )

 IF DEFINED *3RD_PARTY_PATCHING (
	 CALL :Heading 3RD PARTY OS and APPLICATION PATCHING*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Running Processes" PSLIST1
	 %@MACHINE_LOOP$% CALL :3rdPartyPatching %%~s
 )

 IF DEFINED *MEMDUMP (
	 CALL :Heading MEMORY DUMP FILES
	 %@MACHINE_LOOP$% CALL :MemoryDumps %%~s
 )

 IF DEFINED *HANDLES (
	 CALL :Heading PROCESSES WITH MORE THAN %@MINHANDLES% OPEN HANDLES*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Running Processes" PSLIST1
	 %@MACHINE_LOOP$% CALL :HandleCount %%~s
 )

 IF DEFINED *GETSYS_INFO (
	 CALL :Heading GET DETAILED SYSTEM INFO*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Extended System Info" GETSYS
	 %@MACHINE_LOOP$% CALL :GetSysInfo %%~s
 )

 IF DEFINED *SSBACKUPS_SUMMARY (
	 CALL :Heading SYSTEMSTATE and CONFIGURATION BACKUPS
	 %@MACHINE_LOOP$% CALL :SSBackups %%~s
 )

 IF DEFINED *CPUBENCH (
	 CALL :Heading BASIC CPU BENCHMARK, SORTED [SUMMARY]
	 %@MACHINE_LOOP$% CALL :CheckBenchmark_SUMMARY %%~s
	                  CALL :CheckBenchmark_SUMMARY ----
 )

 IF DEFINED *PROCINFO_BW (
	 CALL :Heading OS and CPU INFO w/ARCHITECTURE
	 %@MACHINE_LOOP$% CALL :ProcessorInfo-BW %%~s
 )

 IF DEFINED *PING (
	 CALL :Heading LOCAL PING PROBE*
	 %@MACHINE_LOOP#% CALL :Get-Concurrent-Info %%~s "Ping Probe" PING "%@TINY_TIME%" $$
	 %@MACHINE_LOOP#% CALL :PingProbe %%~s
 )

 IF DEFINED *TRACEROUTE (
	 CALL :Heading LOCAL TRACEROUTE PROBE*
	 %@MACHINE_LOOP#% CALL :Get-Concurrent-Info %%~s "Traceroute Probe" TRACEROUTE "%@TINY_TIME%" $$
	 %@MACHINE_LOOP#% CALL :TraceRouteProbe %%~s
 )

 IF DEFINED *JOBHISTORY (
	 CALL :Heading CUSTOM JOB HISTORY [Last %@HISTORY% Jobs]*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Job History Reports" JOBHISTORY
	 %@MACHINE_LOOP$% CALL :CheckJobHistory %%~s
 )

 IF DEFINED *UPTIME (
	 CALL :Heading SYSTEM UPTIME [EXTENDED INFO]*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "Extended Uptime Info" UPTIME2
	 %@MACHINE_LOOP$% CALL :UpTimeExt %%~s
 )

 IF DEFINED *NTP (
	 CALL :Heading NTP TIME SERVER SOURCES*
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "NTP Configuration" NTP1
	 %@MACHINE_LOOP$% CALL :Get-Concurrent-Info %%~s "NTP Events" NTP2
	 %@MACHINE_LOOP$% CALL :TimeSource %%~s
 )

 IF DEFINED *DISKSPEED_SUMMARY (
	 CALL :Heading DISK I/O MEASUREMENTS [SUMMARY]
	 %@MACHINE_LOOP$% CALL :DiskPerf %%~s
 )

 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Capture Detailed Diagnostics Info to Logs
 rem === Updated On: 03-04 Feb 2026 / 29 Aug 2025 / 05 Nov 2024 / 29 Sep 2024
 rem ==========================================================================
:DiagnosticsLogging
 CALL :Heading DIAGNOSTICS INFO
 ( rem -- Write to Log
	 ECHO %@DIVIDER*%
	 ECHO:
	 FOR /F "TOKENS=*" %%F IN ('DIR /B /S /OGD "%@TMPPATH%\*.TIM"') DO (
		 FOR /F "TOKENS=2 DELIMS=[]" %%E IN ('ECHO %%~nF') DO IF NOT DEFINED @DEBUGINFO_%%~E (SET @DEBUGINFO_%%~E=TRUE& ECHO:)
		 TYPE "%%~F" | FIND "~~~"
	 )

	 IF DEFINED @TRACK_METRICS (
		 FOR /F "USEBACKQ EOL=; DELIMS=\ " %%s IN ("%@MACHINELIST%") DO (
			 FOR /F "TOKENS=4" %%D IN ('TYPE "%@TMPPATH%\%%~s.*.TIM" 2^>NUL ^| FIND "---"') DO (
				 %@TRACK_TIME% \\%%~s "%%~D" ADD
			 )
		 )
		 NOW \s \n\n \* *** Approximate processing duration for each monitored system [sorted]\n \*
		 FOR /F "TOKENS=1 DELIMS=_=" %%t IN ('SET "\\" 2^>NUL ^| FIND /I "TTIME"') DO (
			 %@TRACK_TIME% %%~t FINAL
			 CALL :PadRight @TT "  Total time for %%~t " "." 64
			 ECHO !@TT! !%%~t_TTIME!	!@LIMITED_%%~t!
		 ) >>%@SORTLOG%
		 TYPE %@SORTLOG% | SORT /+60
	 )
 ) >%@TEMPLOG% 2>&1
 FOR %%O IN (%@LOGFILE% %@DIAGLOG%) DO TYPE %@TEMPLOG% >>%%O 2>&1

 CALL :SummarizeList @UNREACHABLE_LIST "SYSTEMS NOT FULLY ACCESSIBLE"
 CALL :SummarizeList @REBOOT_LIST "SYSTEMS TO REBOOT"
 CALL :SummarizeList @BASIC_LIST "SYSTEMS WITH BASIC SCANS ONLY"

 IF /I "!@EXTENDED_DIAG!"=="TRUE" ( rem -- Write More Info to the Debug Log
	 ECHO:
	 ECHO:
	 ECHO:
	 DIR /OGD %@TMPPATH%\*.*
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
	 SET
 ) >>%@DIAGLOG% 2>&1

 ( rem -- Write to Error Log
	 ECHO:
	 FINDSTR /I /R "%@ERROR_TOKENS:"=% " %@LOGFILE%
	 ECHO %@DIVIDER#%
 ) >>%@ERRORS% 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Compare Performance with Most Recent Completed Job Run
 rem === Updated On: 09 Jul 2025 / 08 Jun 2020 / 17 Feb 2020
 rem ==========================================================================
:ComparePerformance
 CALL :Heading COMPARING EXECUTION PERFORMANCE

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER*%
	 ECHO COMPARING EXECUTION PERFORMANCE FOR EACH SECTION
	 ECHO %@DIVIDER*%
	 ECHO:
 ) >>%@DIAGLOG% 2>&1

 rem -- Initialize the Performance Log
 WriteBOM %@TEMPLOG%

 ( rem -- Write to Log
	 IF EXIST !@NEWPERF! (
		 ECHO Preparing Comparison Files...
		 COPY !@NEWPERF! !@OLDPERF! /Y
	 ) ELSE (
		 ECHO FIRST RUN - Nothing to Compare...
	 )
	 ECHO:
 ) >%@TEMPLOG% 2>&1

 ( rem -- Write to Log
	 TYPE %@LOGFILE% | FIND "\--- [#"
	 DATEINFO -t !@SCRIPT_BEG#! %@AGGREGATE%
 ) >%@NEWPERF% 2>NUL

 rem -- Use DATEINFO v5.0 to track TOTAL, FASTER, SLOWER and UNCHANGED sections
 IF EXIST !@OLDPERF! DATEINFO --CompareOld=!@OLDPERF! --CompareNew=!@NEWPERF! >>%@TEMPLOG% 2>NUL
 FOR %%O IN (%@LOGFILE% %@DIAGLOG%) DO TYPE %@TEMPLOG% >>%%O 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Compress Log Files and Send via Email
 rem === Updated On: 02 Sep 2025 / 08 Jul 2025 / 02 Feb 2020 / 10 Dec 2019
 rem ==========================================================================
:SendLog
 CALL :SaveJobHistory
 CALL :CreateLogFooter "EMAIL"
 SET @FULL_LIST=& FOR %%F IN (%@CORELOGS%) DO IF EXIST %%F SET @FULL_LIST=!@FULL_LIST! %%F
 SET @TINY_LIST=!@FULL_LIST:%@LOGFILE%=!

 rem -- Generate Summary Info
 CALL :Heading GENERATING FINAL EMAIL SUMMARY
 ( rem -- Write to Log
	 ECHO:
	 ECHO Today's Complete %@JOBNAME% Can Be Found At The Following Location:
	 ECHO       \\%COMPUTERNAME%\LOGS$\%@LOGNAME%\%@LOGNAME%.TXT
	 ECHO       \\%COMPUTERNAME%\LOGS$\%@LOGNAME%\%@LOGNAME%.ERRORS.TXT
	 ECHO:
	 FOR %%F IN (!@FULL_LIST!) DO DIR "%%~F" | FIND /I "%%~nxF"
	 ECHO %@DIVIDER-%
	 ECHO:
	 TYPE %@LOGFILE% | FIND "\--- [#"
	 DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "days hours mins secs.ms" -o "\*\\--- Total Assessment Time: \v\n\*\n * = Jobs Using Concurrency Routines\n" 2>NUL
 ) >>%@SUMMARY% 2>&1

 rem -- Compress Logs Before Sending Email
 CALL :Heading CREATING ZIP ARCHIVES
 ( rem -- Write to Log
	 PUSHD "%@LOGPATH%"
	 ZIP -9 -v -T -j  %@FULLZIP% !@FULL_LIST!
	 ZIP -9 -v -T -j  %@TINYZIP% !@TINY_LIST!
	 POPD
	 ECHO:
	 ECHO Job Logs Compressed -- [!DATE! at !TIME!]
	 ECHO:
	 FILEHASH --%@LOG_HASH% -g %@CHECKSUM% -d "%@ZIPPATH%" "%COMPUTERNAME%-%@LOGNAME%*"
	 ECHO:
	 TYPE %@CHECKSUM% | FIND /I "%@ZIPSTAMP%"
	 ECHO:
 ) >>%@LOGFILE% 2>&1

 rem -- Send Email to Primary/Secondary Recipients, If Configured/Enabled
 CALL :Heading MAILING REPORT ARCHIVES
 ( rem -- Write to Log
 IF /I "%@NOMAIL%"=="FALSE" (
	 IF DEFINED @RCPT-TO ECHO Complete Logs to: %@RCPT-TO:-to =%
	 IF DEFINED @RCPT-T2 ECHO  Summary Logs to: %@RCPT-T2:-to =%
	 ECHO               on: !DATE! at !TIME!
	 ECHO:
	 FOR %%F IN (!@FULL_LIST! %@PARTIAL% %@CHECKSUM% %@FULLZIP% %@TINYZIP%) DO DIR "%%~F" 2>NUL | FIND /I "%%~nxF"
	 ECHO:
	 TYPE %@CHECKSUM% | FIND /I "%@ZIPSTAMP%"
	 ECHO %@DIVIDER-%
	 ECHO:
	 BLAT -install %@MAILSERVER% %@MAILSENDER% 2 %@MAILPORT%
	 ECHO:

	 IF DEFINED @RCPT-T2 (
		 ECHO:
		 BLAT %@SUMMARY% %@RCPT-T2% -s "%@JOBINFO_S%" -attach %@TINYZIP%,%@CHECKSUM%
		 CALL :ForwardToSyslog "6" Mailed %@JOBINFO_S% -- %@TINYZIP%
		 ECHO %@DIVIDER~%
		 ECHO:
	 )

	 IF DEFINED @RCPT-TO (
		 ECHO:
		 BLAT %@SUMMARY% %@RCPT-TO% -s "%@JOBINFO_F%" -attach %@FULLZIP%,%@CHECKSUM%
		 CALL :ForwardToSyslog "6" Mailed %@JOBINFO_F% -- %@FULLZIP%
		 ECHO %@DIVIDER~%
		 ECHO:
	 )
 )) >%@TEMPLOG% 2>&1
 FOR %%O IN (CON %@LOGFILE%) DO TYPE %@TEMPLOG% >>%%O 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Log Management/Maintenance (Or Copy Them for Debug Purposes)
 rem === Updated On: 09 Jun 2020 / 25 Mar 2016
 rem ==========================================================================
:LogMaint
 CALL :Heading PERFORMING FINAL LOG MAINTENANCE

 IF DEFINED DEBUG (
	 ECHO Making Debug Copy of Job Logs
	 ECHO %@DIVIDER-%
	 XCOPY "%@TMPPATH%\*.*" "%@DBGPATH%" /D /Y
	 FOR %%L IN (%@LOGLIST% %@CLEANUP%) DO IF EXIST %%L COPY %%L "%@DBGPATH%" /Y
 )

 FOR %%L IN (%@LOGLIST%) DO IF EXIST %%L (
	 SET @THISLOG=%%L
	 COPY %%L !@THISLOG:%@FILESTAMP%=TXT! /Y
	 IF %%L==%@LOGFILE% (ECHO: & DIR %%L)
 )

 FOR %%L IN (%@CLEANUP%) DO IF EXIST %%L DEL %%L >NUL
 IF EXIST "%@TMPPATH%" RD /S /Q "%@TMPPATH%" >NUL

 rem -- Generate Log Footer with Aggregate Job Timing
 CALL :Heading %@FINAL%
 CALL :CreateLogFooter "%@FINAL%"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 04 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ###***###***###***###***###***###***###***###***###***###***###***###***###
 rem ###***###***###***###***###***###***###***###***###***###***###***###***###


 rem ==========================================================================
 rem === SUBROUTINE: Store Current Date and Time in Variable (Native vs DATEINFO)
 rem === Updated On: 02 Sep 2025 / 16 Oct 2023 / 21 Apr 2015
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 SET %~1#="!%~1:~4,10! !%~1:~18!"
 IF NOT "%~2"=="" FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Capture per-Server Time Tracking Statistics
 rem === Updated On: 28 Aug 2025 / 25 Aug 2025
 rem ==========================================================================
:TrackDuration
 rem %1 = Current Server For Which Stats Will be Calculated
 rem %2 = Initialize time tracking on START; Finish on STOP; Format on FINAL

 IF /I "%~3"=="ADD"   FOR /F "TOKENS=*" %%d IN ('DATEINFO -q -t !%~1_TTIME! -z "%~2" %@TIME2FMT% 2^>NUL') DO SET %~1_TTIME="%%~d" && EXIT /B
 IF /I "%~2"=="FINAL" FOR /F "TOKENS=*" %%d IN ('DATEINFO -q -t !%~1_TTIME! -n %@ALL_ZEROES% %@TIME1FMT% 2^>NUL') DO SET "%~1_TTIME=%%~d" && EXIT /B
 IF /I "%~2"=="START" FOR /F "TOKENS=*" %%d IN ('DATEINFO -q -s %@DATEFMT% 2^>NUL') DO SET %~1_STIME="%%~d" && EXIT /B
 IF /I "%~2"=="STOP"  FOR /F "TOKENS=*" %%d IN ('DATEINFO -q -s %@DATEFMT% 2^>NUL') DO SET %~1_ETIME="%%~d"

 IF NOT DEFINED %~1_TTIME SET %~1_TTIME="%@ALL_ZEROES%"
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -q -t !%~1_STIME! -n !%~1_ETIME! %@TIME1FMT% 2^>NUL') DO SET %~1_PTIME="%%~d"
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -q -t !%~1_TTIME! -z !%~1_PTIME! %@TIME2FMT% 2^>NUL') DO SET %~1_TTIME="%%~d"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Calculate and Format Elapsed Time
 rem === Updated On: 02 Feb 2020 / 19 Jan 2020
 rem ==========================================================================
:CalcElapsed
:CalcBenchmark
 rem %1 = Variable to Store Date/Time
 rem %2 = Starting Time
 rem %3 = Ending Time
 rem %4 = Optional Alternate Format - %4 %5

 SET "%~1=%@NO_TIME%"
 SET "#HR=hr:" & IF "%~0"==":CalcBenchmark" SET "#HR="
 FOR /F "DELIMS=" %%d IN ('DATEINFO -t "%~2" -n "%~3" -e "!#HR!min:sec.ms" %4 %5 -q 2^>NUL') DO SET "%~1=%%d"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Generate Heading for Current Category
 rem === Updated On: 21 Mar 2024 / 29 Oct 2023
 rem ==========================================================================
:Heading
 rem %* = Heading Name  (Convert parenthesis into [])

 CALL :GetTime @SECTION_BEG
 SET @SPAWNED=z%@RANDOM%
 SET @SYSCOUNT=0
 SET @HEADING=%*
 SET @HEADING=%@HEADING:(=[%
 SET @HEADING=%@HEADING:)=]%
 SET /A @SECTIONS+=1& CALL :PadLeft @SC "!@SECTIONS!" "0" 2

 ECHO:
 ECHO:
 FOR %%E IN ("TITLE %~n0 --" ECHO) DO %%~E Current Category: #!@SC! - %@HEADING%
 ECHO:
 ( rem -- Write to Log
	 IF DEFINED @SECTION_END# DATEINFO -t %@SECTION_BEG#% -n %@SECTION_END#% -e "###:min:sec.ms" -o "\n\%@MINDIV%\\n\\--- [%@O_SC%] \v - %@O_HEADING%\t !@TASKSTATUS!\n\%@MINDIV%\\n\n" 2>NUL
	 ECHO:
	 IF /I NOT "%@HEADING%"=="%@FINAL%" (
		 ECHO:
		 ECHO %@MAXDIV%
		 ECHO \=== Category #%@SC%: %@HEADING%
		 ECHO \=== Generated On: %@SECTION_BEG%
		 ECHO %@MAXDIV%
		 ECHO:
	 )
 ) >>%@LOGFILE% 2>&1

 rem -- Capture Current Info for Future Calculation
 SET @TASKSTATUS=
 SET @O_SC=#%@SC%
 SET @O_HEADING=%@HEADING%
 SET @SECTION_END#=%@SECTION_BEG#%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Save Results of Parsing Operation to Logfile
 rem === Updated On: 29 Apr 2016 / 20 Mar 2016
 rem ==========================================================================
:LogResults
 rem %1 = Current Server For Which Stats Will be Logged
 rem %2 = Destination Logfile
 rem %3 = # of Blank Lines To Output After Data
 rem %4 = Suppress Server Name if Non-Blank entry here
 rem %5 = Provide a *** (or alternate) Separator if Non-Blank entry here
 rem %6 = Output to ERROR logfile instead of default logfile if Non-Blank entry here

 SET @WHICHLOG=%@LOGFILE%& IF NOT "%~6"=="" SET @WHICHLOG=%@ERRORS%
 ( rem -- Write to Log
	 IF "%~4"=="" (
		 CALL :DisplaySysInfo %~1
		 ECHO !@SYSINFO!
	 )
	 TYPE %~2
	 IF NOT "%~4"=="" IF DEFINED @LOGTIME IF EXIST %@LOGTIME% (ECHO: & TYPE %@LOGTIME% | FIND "---")
	 IF NOT "%~5"=="" IF DEFINED @DIVIDER%~5 (ECHO !@DIVIDER%~5!) ELSE (ECHO %@DIVIDER*%)
	 FOR /L %%C IN (1,1,%~3) DO ECHO:
 ) >>%@WHICHLOG% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Generate Log Footer for a Specified Log
 rem === Updated On: 08 Apr 2024 / 09 Jun 2020 / 19 May 2020
 rem ==========================================================================
:CreateLogFooter
 rem %1 = Type of Logging Completed

 CALL :GetTime @SCRIPT_END

 IF /I "%~1"=="%@FINAL%" (
	 SET @OUTPUT=%@LOGFILE% !@LOGFILE:%@FILESTAMP%=TXT!
	 SET @LOGMSG=***      STATUS of DAILY UPTIME REPORT ---- FINAL JOB REPORT COMPLETED      ***
 ) ELSE (
	 SET @OUTPUT=%@LOGFILE% %@DIAGLOG%
	 SET @LOGMSG=***   STATUS of DAILY UPTIME REPORT ---- PRELIMINARY JOB REPORT COMPLETED   ***
 )

 rem -- Display Log Footer Message
 FOR %%O IN (%@OUTPUT%) DO (
	                         DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -o "\n!@SCRIPT_END! -- Script Processing Duration: \v\n\*%@LOGMSG%\n\*\n"
	 IF /I "%~1"=="%@FINAL%" DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! %@AGGREGATE%
 ) >>%%O 2>NUL

 rem -- Capture Current Info for Future Calculation
 SET @SECTION_END#=!@SCRIPT_END#!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Swap Characters in Variable's Content
 rem === Updated On: 26 May 2020
 rem ==========================================================================
:SwapCharacters
 rem %1 = Variable to Make the Swap
 rem %2 = Original Character(s)
 rem %3 = New Character(s)

 IF "%~1"=="" EXIT /B
 SET @VAR=!%~1!
 SET @VAR=!@VAR:"=´!
 FOR /F "TOKENS=*" %%a IN ('SUBSTRING "!@VAR!" "%~2" "%~3" 2^>NUL') DO SET @VAR=%%a
 SET @VAR=!@VAR:´="!
 SET %~1=!@VAR!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Add a Computer Name to an Existing Variable
 rem === Updated On: 23 Jun 2024 / 21 Mar 2024 / 19 Mar 2024
 rem ==========================================================================
:AddName
 rem %1 = Variable to Add Unique Computername to
 rem %2 = Optional Data to Store in Variable

 IF "!%~1!"=="***NONE***" SET %~1=
 SET @Z1=·!%~1!·
 SET @Z1=!@Z1: =·!
 SET @Z2=%~2& IF "%~2"=="" SET @Z2=%@CNAME%
 SET @Z2=!@Z2:\=!
 SET @ZZ=·!@Z2!·
 IF /I "!@Z1!"=="!@Z1:%@ZZ%=!" SET %~1=!%~1! !@Z2!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display a Summarized List of All Systems Affected in Area
 rem === Updated On: 02 Sep 2025 / 27 May 2024 / 07 Apr 2024 / 26 Mar 2024
 rem ==========================================================================
:SummarizeList
 rem %1 = Variable to Display Contents of
 rem %2 = Message to Display for Summary Info

 SET @LIST_ITEMS=

 ( rem -- Write to Log
	 IF NOT DEFINED %~1 (
		 SET %~1=***NONE***
	 ) ELSE (
		 FOR %%Z IN (!%~1!) DO SET /A @LIST_ITEMS+=1
		 CALL :ChangeCase %~1 -U
	 )
	 SET @MSG=%~2
	 CALL :ChangeCase @MSG -P
	 ECHO:
	 ECHO  %@DIVIDER~:~-77%
	 ECHO   ## !@MSG!: !%~1!
	 IF DEFINED @LIST_ITEMS ECHO   ## COUNT = !@LIST_ITEMS!
	 ECHO  %@DIVIDER~:~-77%
 ) >>%@LOGFILE% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Change Case of Variable Contents
 rem === Updated On: 07 Apr 2024
 rem ==========================================================================
:ChangeCase
 rem %1 = Variable to Change Contents of
 rem %2 = Change Case to (-P or -U or - L or -I)

 IF NOT "%~1"=="" IF NOT "%~2"=="" FOR /F "TOKENS=*" %%z IN ('CHANGECASE %~2 "!%~1!" 2^>NUL') DO SET %~1=%%z
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
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get File Size Info
 rem === Updated On: 30 Oct 2025
 rem ==========================================================================
:GetFileSize
 rem %1 = Variable to Store New Content
 rem %2 = Filename to evaluate

 IF "%~1"=="" GOTO EXIT /B
 IF "%~2"=="" GOTO EXIT /B
 FOR %%F IN ("%~2") DO SET %~1="%%~F" [%%~zF]
 %@PRINT_IF_DEBUG%
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
 rem === Updated On: 04 Feb 2026 / 29 Sep 2025 / 18 Aug 2025 / 26 Sep 2024 / 13 Jan 2020
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 SET @LIVESYS=0& FOR /F %%C IN ('SET "\\" 2^>NUL ^| FIND /C "-PLATFORM="') DO SET @LIVESYS=%%~C
 CALL :Heading UPDATING JOB HISTORY
 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @NS "%@LIVESYS%/%@NUMSYS%/%@ALLSYS%" "." 11
 CALL :PadLeft @PL "%@PROC_LIMIT%" "0" 3
 CALL :CalcElapsed @ELAPSED !@SCRIPT_BEG#! !@SCRIPT_END#!

 SET @TRUNCATED=
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 SET @JOBHISTORY=%@JOBNAME% // SECTIONS.%@SC% // SYSTEMS.%@NS% [!@PL!] // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: %@SCRIPT_END% // %~n0 %@VERSION% %@PARAMS%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>%@TIMINGS%
 SET @ROWCOUNT=0& FOR /F %%c IN ('READABLE %@TIMINGS% -F "/" --TO -Q 2^>NUL') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY %@TIMINGS% !@OLDTIME! /V /Y >CON
	 READABLE !@OLDTIME! --ST -%@MINROWS% -O %@TIMINGS%
	 ECHO:
	 CALL :ForwardToSyslog "5" %@JOBNAME%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>%@LOGFILE% 2>>%@ERRORS%

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@RUNMODE!!@TRUNCATED! >>%@TIMINGS% 2>>%@ERRORS%
 %@VERBOSE_ON%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 13 Jan 2026 / 01 Jan 2026 / 25 Sep 2024 / 13 Jan 2020
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
			 "%@SYSLOGGEN%" -t:!@SYSLOG%%~s! -p:!@S_PORT! -f:19 -s:!@SEV! -tg:"%~n0" -m:"!@S_MSG2!" -q -hn:%@LOCALHOST% 2>NUL | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )

	 IF /I "%@SCRIPT_METRICS%"=="TRUE" (
		 FOR %%P IN (%@MY_SYSLOG_PORTS%) DO (
			 "%@SYSLOGGEN%" -t:127.0.0.1 -p:%%~P -f:19 -s:6 -tg:"%~n0+" -m:"%DATE% at %TIME: =0% -- !@S_MSG2!" -q -hn:localhost 2>NUL | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )
 )
 %@VERBOSE_ON%
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Prepare Messages for SyslogGen Syslog Utility
 rem === Updated On: 23 Jun 2024 / 14 Jan 2020 / 12 Jun 2018
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
 rem === SUBROUTINE: Verify Access to Remote System
 rem === Updated On: 14 Jul 2024 / 26 Mar 2024 / 10 Jan 2022
 rem ==========================================================================
:VerifyAccess
 rem %1 = Current Server to be Verified

 SET @ACCESSIBLE=
 DIR "%~1\C$" >NUL 2>NUL
 IF ERRORLEVEL 1 (
	 CALL :AddName @UNREACHABLE_LIST %~1
	 FOR %%f IN (%@LOGINFO% %@LOGTEMP% %@NOREACH%) DO IF NOT EXIST "%%~f" ECHO %~1 IS NOT ONLINE... >"%%~f"
 ) ELSE (
	 SET @ACCESSIBLE=TRUE
	 IF EXIST %@NOREACH% FOR %%f IN (%@LOGINFO% %@LOGTEMP% %@NOREACH%) DO IF EXIST "%%~f" DEL "%%~f"
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display Current Server Info
 rem === Updated On: 25 Aug 2025 / 11 Jun 2024 / 15 Mar 2021 / 23 Dec 2020
 rem ==========================================================================
:DisplaySysInfo
 rem %1 = Current Server For Which Stats Will be Displayed
 rem %2 = Special Parameter for Displaying System Info without Time "MINI"
 rem %3 = Only Display to Console if Non-Blank Parameter Here

 %@TRACK_TIME% %~1 START
 IF NOT DEFINED %~1-ARCH CALL :Get-DATEINFO %~1 "@OS @CPU _CORE @TOTAL_RAM @IS_ @REBOOT_ @NEEDS_ @SERIAL"

 SET @SYSARCH=--- %~1 !%~1-ARCH!
 SET @SYSINFO=!@SYSARCH! @ !TIME: =0!
 SET @SYSINFO-CON=!@SYSARCH! %@SPACES%
 SET @SYSINFO-CON=!@SYSINFO-CON:~0,%@MAXLEN%!
 SET @SYSINFO-TIME=!@SYSINFO-CON! @ !TIME: =0!
 SET @CNAME=%~1& SET @CNAME=!@CNAME:\=!
 SET @CNAME1=%~1 !%~1-ARCH! %@DOTS%& SET @CNAME1=!@CNAME1:~0,25!& SET @CNAME2=!@CNAME1:~2,25!

 IF "%~3"=="" IF /I "%~2"=="MINI" (
	 ECHO !@SYSINFO-CON! >CON
 ) ELSE (
	 ECHO !@SYSINFO-TIME! >CON
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Make Temp Variables for Info Logging
 rem === Updated On: 28 Mar 2024 / 26 Mar 2024 / 24 Dec 2018
 rem ==========================================================================
:MakeTempVariables
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Concurrency Task Name
 rem %3 = Search Criteria for the Execution Results

 SET @SEARCH=%3
 SET @LSERVER=%~1
 SET @LSERVER=%@LSERVER:\=%
 SET @LSERVER=%@LSERVER:/=__%
 SET @LOGINFO="%@TMPPATH%\%@LSERVER%.[%~2].DAT"
 SET @LOGTEMP=!@LOGINFO:.DAT"=.TMP"!
 SET @LOGTIME=!@LOGINFO:.DAT"=.TIM"!
 SET @NOREACH=!@LOGINFO:.DAT"=.BAD"!
 IF "!@LSERVER!"=="!@LSERVER:__=!" (SET @OBJTYPE=SYSTEM) ELSE (SET @OBJTYPE=NETWORK)
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from SYSTEMINFO
 rem === Updated On: 26 Mar 2024 / 19 May 2020
 rem ==========================================================================
:Get-SYSTEMINFO
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 FOR %%Z IN (%@SKIP_SYSTEMINFO%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "SYSINFO" %2
 CALL :VerifyAccess %~1

 IF NOT EXIST %@LOGINFO% SYSTEMINFO /S %~1                    >%@LOGINFO% 2>&1
 IF DEFINED @SEARCH TYPE %@LOGINFO% | FINDSTR /I /R %@SEARCH% >%@LOGTEMP% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from DATEINFO
 rem === Updated On: 04 Feb 2026 / 22 Aug 2025 / 18 Jun 2024 / 16 Jun 2024
 rem ==========================================================================
:Get-DATEINFO
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 IF DEFINED @LIMITED_%~1 EXIT /B
 FOR %%Z IN (%@SKIP_DATEINFO%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "BWSYSINFO" %2
 CALL :VerifyAccess %~1
 IF DEFINED @ACCESSIBLE CALL :GetRemoteConsole %~1

 IF NOT EXIST %@LOGINFO% %@RMTCONSOLE% DATEINFO %@BW_PARAMS% >%@LOGINFO% 2>NUL
 IF DEFINED @SEARCH TYPE %@LOGINFO% | FINDSTR /I %@SEARCH%   >%@LOGTEMP% 2>&1

 rem -- Determine Remote OS and CPU Architecture Info, plus Reboot Status
 IF NOT DEFINED %~1-ARCH (
	 SET "%~1-ARCH=     " & SET %~1-OSEDITION=an ** UNIDENTIFIED ** operating system
	 FOR /F "TOKENS=1-2 DELIMS=@;" %%P IN ('TYPE %@LOGTEMP%') DO SET %~1-%%P=%%~Q
 )

 rem -- Determine Age of Current Windows Build
 IF NOT DEFINED %~1-RELEASED (
	 SET %~1-OSDATE=----------
	 SET %~1-RELEASED=!%~1-OSEDITION!
	 FOR /F "TOKENS=1" %%Z IN ('TYPE "%@BUILDINFO-LATEST%" 2^>NUL ^| FIND "!%~1-OSVER!"') DO IF NOT DEFINED %~1-LATEST SET %~1-LATEST=%%~Z
	 FOR /F "TOKENS=1" %%Z IN ('TYPE "%@BUILDINFO-PLUS%" 2^>NUL ^| FIND "!%~1-OSBUILDX!"') DO (
		 SET %~1-OSDATE=%%~Z& IF "!%~1-OSDATE!"=="!%~1-LATEST!" SET %~1-LATEST=CURRENT
		 SET %~1-RELEASED=!%~1-OSEDITION! %@DOTS%
		 SET %~1-RELEASED=!%~1-RELEASED:~0,80! Released on %%~Z  [!%~1-LATEST!]
	 )
 )

 IF /I "!%~1-OS_ARCH!"=="x64" SET %~1-ARCH=[x64]& SET %~1-PLATFORM=a 64-bit Windows system
 IF /I "!%~1-OS_ARCH!"=="x86" SET %~1-ARCH=[x86]& SET %~1-PLATFORM=a 32-bit Windows system
 IF /I "!%~1-NEEDS_REBOOT: =!"=="TRUE" (
	 CALL :AddName @REBOOT_LIST %~1
	 SET %~1-REBOOT_MSG=Â»Â»Â» WINDOWS REQUESTS A REBOOT Â«Â«Â«
 )
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from UPTIME or UPTIME2
 rem === Updated On: 26 Mar 2024 / 27 Dec 2020
 rem ==========================================================================
:Get-UPTIME
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Selected Parameters for the UPTIME/UPTIME2 Utility
 rem %3 = Value to Add to File Extension
 rem %4 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 FOR %%Z IN (%@SKIP_UPTIME%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "UPTIME%~3" "%~4"
 CALL :VerifyAccess %~1

 IF NOT EXIST %@LOGINFO% (
	 IF /I "%@USE_UPTIME_LEGACY%"=="TRUE" (
		 UPTIME %~1 %~2
	 ) ELSE (
		 UPTIME2 /NOLOGO /COMPUTERNAME:%@LSERVER% %~2
	 )
 ) >%@LOGINFO% 2>&1
 IF DEFINED @SEARCH TYPE %@LOGINFO% | FIND /I %@SEARCH% >%@LOGTEMP% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant NTP Info from EventLog (PSLOGLIST)
 rem === Updated On: 26 Mar 2024 / 24 Dec 2018
 rem ==========================================================================
:Get-EVENTS
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 FOR %%Z IN (%@SKIP_PSLOGLIST%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "NTP2" "%~2"
 CALL :VerifyAccess %~1

 IF NOT EXIST %@LOGINFO% PSLOGLIST %@PSACCEPT% %~1 -I 11,17,22,29,35,37,38,47,50 -D 1 >%@LOGINFO% 2>&1
 IF DEFINED @SEARCH TYPE %@LOGINFO% | FIND /I %@SEARCH%                               >%@LOGTEMP% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from PSLIST
 rem === Updated On: 26 Mar 2024 / 24 Dec 2018
 rem ==========================================================================
:Get-PSLIST
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Selected Parameters for the PSLIST Utility
 rem %3 = Value to Add to File Extension
 rem %4 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 FOR %%Z IN (%@SKIP_PSLIST%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "PSLIST%~3" %4
 CALL :VerifyAccess %~1

 IF NOT EXIST %@LOGINFO% PSLIST %@PSPARAMS% %~1 %~2           >%@LOGINFO% 2>&1
 IF DEFINED @SEARCH TYPE %@LOGINFO% | FINDSTR /I /R %@SEARCH% >%@LOGTEMP% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from NET TIME and W32TM
 rem === Updated On: 26 Mar 2024 / 24 Dec 2018
 rem ==========================================================================
:Get-TimeSource
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 FOR %%Z IN (%@SKIP_TIMESOURCE%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "NTP1" %2
 CALL :VerifyAccess %~1

 IF NOT EXIST %@LOGINFO% ( rem -- Write to Log
	 FOR %%V IN (/RTSDOMAIN %~1) DO NET TIME %%V | FIND "\\"
	 ECHO:

	 IF %@OSBUILD% GEQ 6000 ( rem -- W32TM is preferred for Windows versions after 2003
		 W32TM /QUERY /COMPUTER:%~1 /PEERS | FIND /I "peer"
		 ECHO:
	 )
 ) >%@LOGINFO% 2>&1

 IF DEFINED @SEARCH TYPE %@LOGINFO% | FIND /I %@SEARCH% >%@LOGTEMP% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from PING
 rem === Updated On: 04 Feb 2026
 rem ==========================================================================
:Get-PING
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 FOR %%Z IN (%@SKIP_PING%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "PING" "%~2"

 IF NOT EXIST %@LOGINFO% PING %@LSERVER%                >%@LOGINFO% 2>&1
 IF DEFINED @SEARCH TYPE %@LOGINFO% | FIND /I %@SEARCH% >%@LOGTEMP% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Parse Relevant Info from TRACERT
 rem === Updated On: 04 Feb 2026
 rem ==========================================================================
:Get-TRACEROUTE
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Search Criteria for the Execution Results

 rem -- Check for Systems to Exclude
 FOR %%Z IN (%@SKIP_TRACEROUTE%) DO FOR %%U IN ("" "\\") DO IF /I "%%~U%%~Z"=="%~1" (
	 SET @THIS_SECTION=%~0
	 ECHO *** !@THIS_SECTION:~5,99! scan skipped for %~1 >>%@LOGFILE% 2>&1
	 EXIT /B
 )

 CALL :MakeTempVariables %~1 "TRACEROUTE" "%~2"

 IF NOT EXIST %@LOGINFO% TRACERT %@LSERVER%             >%@LOGINFO% 2>&1
 IF DEFINED @SEARCH TYPE %@LOGINFO% | FIND /I %@SEARCH% >%@LOGTEMP% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Initiate Selected Job Across Systems Concurrently
 rem === Updated On: 03-04 Feb 2026 / 02 Sep 2025 / 03 Jun 2024 / 07 Apr 2024
 rem ==========================================================================
:Get-Concurrent-Info-Clean
 FOR %%O IN (%@BROADCAST%) DO (IF EXIST "%@TMPPATH%\*[%~3]*" DEL "%@TMPPATH%\*[%~3]*" /S) >>%%O 2>&1

:Get-Concurrent-Info
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Description of Task to Spawn Concurrently
 rem %3 = Base Name of Script to Spawn Concurrently
 rem %4 = Maximum Job Time, Optional  (Default = "01:00:00")
 rem %5 = [Blank] = @NUMSYS; # = @NETWORKS; Other non-blank = @ALLSYS

 rem -- Abort If No Script Name OR No Concurrency OR Concurrency Previously Completed
 IF EXIST "%@TMPPATH%\$TOTAL$TIME$.[%~3].TIM" EXIT /B
 IF /I NOT "%@CONCURRENCY%"=="TRUE" EXIT /B
 IF "%~3"=="" EXIT /B

 rem -- Set Defaults
 IF NOT DEFINED @MAX_RUN_TIME SET @MAX_RUN_TIME="01:00:00"
 IF "%~4"==""   (SET @MAXTIME=%@MAX_RUN_TIME%) ELSE (SET @MAXTIME="%~4")
 IF "%~5"==""   (SET @TOTAL=%@NUMSYS%) ELSE (SET @TOTAL=%@ALLSYS%)
 IF "%~5"=="##" (SET @TOTAL=%@NETWORKS%)

 rem -- Track Max Time for Spawning Concurrent Processes
 IF NOT DEFINED @MAX_SPAWN_TIME SET @MAX_SPAWN_TIME="00:10:00"
 IF NOT DEFINED @RUN_UNTIL_%~3 FOR /F "TOKENS=*" %%u IN ('DATEINFO -z %@MAX_SPAWN_TIME% -f %@TIMEFORMAT% -q 2^>NUL') DO SET @RUN_UNTIL_%~3="%%~u"

 rem -- Initiate Concurrent Jobs
 SET @MYSCRIPT=!@@%~3_Script!
 SET @TRACKING="%@TMPPATH%\*.[%~3]%@FLAG%"
 SET @TASKTIME="%@TMPPATH%\$TOTAL$TIME$.[%~3].TIM"
 SET @TASKSTATUS=

 IF NOT DEFINED @BEGIN_%~3 (
	 CALL :GetTime @BEGIN_%~3
	 FOR %%O IN (%@BROADCAST%) DO (ECHO  *** [!TIME: =0!] Initiating Concurrent Processes...) >>%%O 2>&1
 )

 FOR /F %%C IN ('DIR /B /A %@TRACKING% 2^>NUL ^| FIND /I "%@FLAG%" /C') DO SET @CONCURRENT=%%C
 IF !@CONCURRENT! LSS %@PROC_LIMIT% (
	 SET /A @SYSCOUNT+=1
	 SET /A @NUMPROC=@CONCURRENT + 1
	 CALL :PadRight @CNAME "%~1" " " 20
	 CALL :PadLeft  @NS "!@SYSCOUNT! of %@TOTAL%" "." 10
	 CALL :PadLeft  @CC "!@NUMPROC!" "." 3
	 CALL :PadRight @SPAWN_INFO "[!TIME: =0!] %~2 SCAN for !@CNAME!" " " 65
	 SET @SPAWN_INFO=!@SPAWN_INFO! [#!@NS! / C.!@CC! / M.%@PROC_LIMIT%]
	 IF NOT DEFINED $%~3%~1 (
		 START "!@SPAWN_INFO:  = !" /MIN CMD /C "!@MYSCRIPT! %~1"
		 FOR %%O IN (%@THESE_LOGS%) DO (ECHO  *** !@SPAWN_INFO!) >>%%O 2>&1
		 SET $%~3%~1=SPAWNED
	 )
 ) ELSE (
	 GOTO :Get-Concurrent-Info
 )

 rem -- Ensure that all jobs process successfully before continuing...
 IF !@SYSCOUNT! LSS %@TOTAL% EXIT /B
 CALL :GetTime @LOOP_BEG
 CALL :CalcBenchmark @ELAPSED !@BEGIN_%~3#! !@LOOP_BEG#!
 FOR /F "TOKENS=*" %%u IN ('DATEINFO -z %@MAXTIME% -f %@TIMEFORMAT% -q 2^>NUL') DO SET @RUN_UNTIL_%~3="%%~u"
 IF "!DATE:~4! !TIME: =0!" GTR !@RUN_UNTIL_%~3! (SET @TASKSTATUS=**TIME EXCEEDED: %@MAX_SPAWN_TIME:"=%**)
 FOR %%O IN (%@BROADCAST%) DO (ECHO  *** [!TIME: =0!] Waiting for Concurrent Processes to Finish...       {Elapsed Time: !@ELAPSED!} !@TASKSTATUS!) >>%%O 2>&1

:Wait4Work
 IF "!DATE:~4! !TIME: =0!" GTR !@RUN_UNTIL_%~3! (SET @TASKSTATUS=**TIME EXCEEDED: %@MAX_SPAWN_TIME:"=%** & GOTO :Wait4Zero)
 IF NOT EXIST !@TRACKING! GOTO :Wait4Work

:Wait4Zero
 FOR /F %%E IN ('DIR /B /A %@TRACKING% 2^>NUL ^| FIND /I "%@FLAG%" /C') DO SET @REMAINING=%%E
 IF "!DATE:~4! !TIME: =0!" GTR !@RUN_UNTIL_%~3! (SET @TASKSTATUS=**TIME EXCEEDED: %@MAXTIME:"=%** & GOTO :LogTime) ELSE (SET @TASKSTATUS=)
 IF !@REMAINING! NEQ 0 GOTO :Wait4Zero

:LogTime
 SET @SYSCOUNT=0
 CALL :GetTime @END_%~3
 CALL :CalcBenchmark @ELAPSED !@LOOP_BEG#!    !@END_%~3#!
 CALL :CalcBenchmark @THUSFAR %@SECTION_BEG#% !@END_%~3#!
 FOR %%O IN (%@BROADCAST%) DO (
	 ECHO  *** [!TIME: =0!] All Concurrent Processes Have Finished...           {Elapsed Time: !@ELAPSED!} !@TASKSTATUS!
	 ECHO  *** [!TIME: =0!] Total Time Elapsed Since Section Begun...           {Elapsed Time: !@THUSFAR!}
	 ECHO:
 ) >>%%O 2>&1
 DATEINFO -t !@BEGIN_%~3#! -n !@END_%~3#! -e "hr:min:sec.ms" -o " \~ ~~~ TASK CONCURRENCY SUMMARY .... DURATION: \v   START: !@BEGIN_%~3#:"=!   END: !@END_%~3#:"=!  for %~3  !@TASKSTATUS!\n \~" >>!@TASKTIME! 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Generate Custom Concurrency Script
 rem === Updated On: 02 Sep 2025 / 18 Aug 2025 / 14 Jul 2024 / 14 May 2024
 rem ==========================================================================
:Make-Concurrency-Script
 rem %1 = Name of Script to Generate
 rem %2 = Command/Utility for Custom Concurrency Task
 rem %3 = Command/Utility Parameters for Custom Concurrency Task
 rem %* = Search for following tokens in any order: #LOCAL# #REMOTE_REG#

 FOR %%Z IN (%@SCRIPT_TOKENS%) DO SET %%Z=
 FOR %%Y IN (%*) DO FOR %%Z IN (%@SCRIPT_TOKENS%) DO IF /I "%%~Y"=="%%~Z" SET %%Z=TRUE

 FOR /F "TOKENS=1 DELIMS==" %%V IN ('SET "@LINE" 2^>NUL') DO SET %%V=
 SET @@%~1_SCRIPT="%@TMPPATH%\%~n0-%~1-TEMP.BAT"
 SET @LINE000=@rem -- Generated on !DATE! at !TIME: =0! by %~n0 %@VERSION%
 SET @LINE001=@ECHO OFF
 SET @LINE002= ECHO *** Obtaining Detailed %~1 Information for: %%~1 ***
 SET @LINE003= SETLOCAL ENABLEDELAYEDEXPANSION
 SET @LINE004= SET @RMTCONSOLE=
 SET @LINE005= SET @TNAME=%~1%@SPACES%
 SET @LINE006= SET @SNAME=%%~1%@SPACES%
 SET @LINE007= SET @SNAME=%%@SNAME:\=%%
 SET @LINE008= SET @LSERVER=%%@SNAME: =%%
 SET @LINE009= SET @LSERVER=%%@LSERVER:/=__%%
 SET @LINE010= SET @LOGINFO="%@TMPPATH%\%%@LSERVER%%.[%~1].DAT"
 SET @LINE011= SET @LOGTIME=%%@LOGINFO:.DAT"=.TIM"%%
 SET @LINE012= SET @TMARKER=%%@LOGINFO:.DAT"=.---"%%
 SET @LINE013= SET @MINI= --- Elapsed Time: \v
 SET @LINE014= SET @STIME=%%DATE:~4%% %%TIME: =0%%

 SET @LINE020= ECHO %%@STIME%% ^>%%@TMARKER%%
 SET @LINE021= ECHO FINDFILES --bw -w -m -f "%~1" WHERE
 SET @LINE022= ECHO IF ERRORLEVEL 64 GOTO :WrapThingsUp

 IF /I "%~1"=="NTP1" (
	 SET @LINE060= rem -- Get Time Source Info
	 SET @LINE061= FOR %%%%V IN ^(/RTSDOMAIN %%~1^) DO NET TIME %%%%V ^| FIND "\\"
	 SET @LINE062= ECHO:
	 SET @LINE063= IF %@OSBUILD% GEQ 6000 ^( rem -- Use W32TM after Win2K
	 SET @LINE064=	 W32TM /QUERY /COMPUTER:%%~1 /PEERS ^| FIND /I "peer"
	 SET @LINE065=	 ECHO:
	 SET @LINE066= ^)
 )

 IF DEFINED #LOCAL# (
	 SET @LINE030= rem -- Determine if Remote System is Available
	 SET @LINE031= DIR "%%~1\C$" ^>NUL 2^>NUL
	 SET @LINE032= IF ERRORLEVEL 1 GOTO :WrapThingsUp

	 SET @LINE910= rem -- Execute Command Locally over Remote Shell
	 SET @LINE911= FOR /F "TOKENS=*" %%%%R IN ^('WHERE PSEXEC PAEXEC 2^^^>NUL'^) DO ^(
	 SET @LINE912=	 SET @RMTCONSOLE=%%%%~nxR %%~1
	 SET @LINE913=	 IF /I "%%%%~nR"=="PSEXEC" SET @RMTCONSOLE=PSEXEC.EXE %@PSPARAMS% %%~1
	 SET @LINE914= ^)
	 SET @LINE915= IF /I "%%~1"=="\\%%COMPUTERNAME%%" SET @RMTCONSOLE=
 )

 IF DEFINED #REMOTE_REG# (
	 SET @LINE930= rem -- Enable Remote Registry
	 SET @LINE931= FOR /F "TOKENS=4" %%%%S IN ^('SC %%~1 QUERY "RemoteRegistry" ^^^| FIND "STATE"'^) DO ^(
	 SET @LINE932=	 IF NOT "%%%%~S"=="RUNNING" ^(
	 SET @LINE933=		 ECHO Starting Remote Registry Service on %%~1...
	 SET @LINE934=		 SC %%~1 CONFIG RemoteRegistry start= AUTO
	 SET @LINE935=		 SC %%~1 START RemoteRegistry
	 SET @LINE936=	 ^)
	 SET @LINE937= ^)
 )

 SET @LINE990= %%@RMTCONSOLE%% %2 %~3 ^>%%@LOGINFO%% 2^>NUL
 SET @LINE991=:WrapThingsUp
 SET @LINE992= SET @ETIME=%%DATE:~4%% %%TIME: =0%%
 SET @LINE993= SET @FULL= ~~~ %%@SNAME:~0,16%% %%@TNAME:~0,12%% DURATION: \v   START: %%@STIME%%   END: %%@ETIME%%
 SET @LINE994= FOR %%%%T IN ("%%@MINI%%" "%%@FULL%%") DO DATEINFO -t "%%@STIME%%" -n "%%@ETIME%%" -e "hr:min:sec.ms" -o "%%%%~T" ^>^>%%@LOGTIME%% 2^>^&1
 SET @LINE995= IF EXIST %%@TMARKER%% DEL %%@TMARKER%% ^>NUL

 (FOR /F "TOKENS=1* DELIMS==" %%b IN ('SET "@LINE" 2^>NUL') DO @ECHO %%c) >!@@%~1_SCRIPT!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Construct Necessary Remote Console Command for Execution
 rem === Updated On: 21 May 2020 / 19 Sep 2019
 rem ==========================================================================
:GetRemoteConsole
 rem %1 = Current System for Which Info Will be Obtained

 IF /I "%~1"=="\\%COMPUTERNAME%" (SET @RMTCONSOLE=) ELSE (SET @RMTCONSOLE=%@REXEC_UTIL% %~1 2^>NUL)
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Format Numbers with Thousands Separator
 rem === Updated On: 07 Jul 2025
 rem ==========================================================================
:FormatNumber
 rem %1 = Current Number to be Formatted
 rem %2 = Unit of Measurement to be Used
 rem %3 = New Variable To Store Formatted Number

 SET @FORMATTED=
 FOR /F %%N IN ('CCALC %~1 * 1024 -F 2^>NUL') DO SET @FORMATTED=%@DOTS% %%~N
 SET %~3=!@FORMATTED:~-17! %~2
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Append Current Date to Filename
 rem === Updated On: 31 Dec 2003
 rem ==========================================================================
:AppendDate
 rem %1 = Current Filename Variable
 rem %2 = Variable Name To Store New Filename

 SET %~2=%~dpn1.%@TODAY%.TXT
 CALL :CopyToVariable "%~1" "%%%~2%%"
 ECHO: >"%~1"
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Return Date and/or Time According to Specific Format
 rem === Updated On: 02 Feb 2020
 rem ==========================================================================
:ReturnDateTime
 rem %1 = Variable to Store Date/Time
 rem %2 = Date/Time
 rem %3 = Date/Time Format

 SET @ZZ=%~2
 SET @ZZ=!@ZZ:?=!
 SET %~1=& FOR /F "TOKENS=*" %%d IN ('DATEINFO -s "!@ZZ!" -f "%~3" -q 2^>NUL') DO SET %~1=%%d
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Copy File Data To Variable Filename
 rem === Updated On: 31 Dec 2003
 rem ==========================================================================
:CopyToVariable
 rem %1 = Source Filename Variable
 rem %2 = Destination Filename Variable

 COPY "%~1" "%~2" >NUL
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

 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ###***###***###***###***###***###***###***###***###***###***###***###***###
 rem ###***###***###***###***###***###***###***###***###***###***###***###***###


 rem ==========================================================================
 rem === SUBROUTINE: Display System Uptime (or Boot Time) using SYSTEMINFO
 rem === Updated On: 25 Aug 2025 / 20 Apr 2016 / 21 Apr 2015
 rem ==========================================================================
:BootTime
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 CALL :Get-SYSTEMINFO %~1 /C:" Time: "

 FOR /F "USEBACKQ TOKENS=3* DELIMS=: " %%T IN (%@LOGTEMP%) DO (
	 IF %@OSBUILD% LEQ 3790 ( rem -- Vista and above call this "Boot Time" rather than "System Up Time"
		 ECHO  -%@CNAME2% has been up for: %%~U
	 ) ELSE (
		 ECHO  -%@CNAME2% was last booted up on: %%~U
	 )
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display System Uptime using UPTIME/UPTIME2
 rem === Updated On: 25 Aug 2025 / 14 Jul 2024 / 26 Mar 2024 / 21 Mar 2024
 rem ==========================================================================
:UpTime
 rem %1 = Current System for Which Info Will be Obtained

 rem -- Print Summary of All Systems Needing Reboot
 IF "%~1"=="----" (
	 CALL :SummarizeList @REBOOT_LIST "SYSTEMS TO REBOOT"
	 CALL :SummarizeList @PATCH_LIST  "CHECK FOR PATCHES"
	 EXIT /B
 )

 rem -- Main Routine
 CALL :DisplaySysInfo %~1
 CALL :Get-UPTIME %~1 "" 1 "\\"

 SET @CHAR=-
 SET @DAYS_UP=0
 SET "@USTATUS= "
 SET @UPTIME=*** UNABLE TO OBTAIN UPTIME DATA FROM THIS HOST ***

 FOR /F "TOKENS=1*" %%S IN ('TYPE %@LOGTEMP%') DO SET @UPTIME=%%~T
 SET @UPTIME=%@UPTIME:(s)=s%
 SET @UPTIME=%@UPTIME:dayss,=days,%
 FOR /F "TOKENS=5" %%D IN ('ECHO %@UPTIME%') DO (
	 SET @DAYS_UP=%%~D
	 SET /A @DAYS_UP_N=%%~D
 )

 ( rem -- Write to Log
	 IF "%@DAYS_UP%"=="0" IF DEFINED @ACCESSIBLE SET @USTATUS=*** REBOOTED ^< 24 HOURS AGO ***
	 IF %@DAYS_UP_N% GTR %@PATCHTIME% SET @USTATUS=--- POSSIBLY NEEDS PATCHING ---
	 IF %@DAYS_UP_N% GTR %@PATCHTIMEMAX% SET @USTATUS=### DEFINITELY NEEDS PATCHING ###
	 IF /I NOT "!@USTATUS:PATCHING=!"=="!@USTATUS!" CALL :AddName @PATCH_LIST %~1
	 IF DEFINED %~1-REBOOT_MSG SET @USTATUS=!%~1-REBOOT_MSG!
	 SET @SYSINFO= %@CHAR%%@CNAME2% %@UPTIME% %@SPACES%
	 ECHO !@SYSINFO:~0,90! !@USTATUS!
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display System Uptime - Extended via UPTIME2
 rem === Updated On: 25 Aug 2025 / 12 Dec 2018 / 12 Jun 2018
 rem ==========================================================================
:UpTimeExt
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 CALL :Get-UPTIME %~1 /S 2

 ( rem -- Write to Log
	 ECHO !@SYSINFO!
	 TYPE %@LOGINFO% | FIND "\\"
	 ECHO:
	 ECHO --- Historical Startup/Shutdown Uptime Log of %~1
	 ECHO:
	 TYPE %@LOGINFO% | FIND /I " at: "
	 ECHO:
	 ECHO For Complete Details, Type:  UPTIME2 /NOLOGO /COMPUTERNAME:%@LSERVER% /S
	 IF DEFINED @LOGTIME IF EXIST %@LOGTIME% (ECHO: & TYPE %@LOGTIME% | FIND "---")
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display System Uptime - Extended
 rem === Updated On: 25 Aug 2025 / 20 Mar 2016 / 03 Mar 2016
 rem ==========================================================================
:UpTimeExt_MS
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 CALL :Get-UPTIME %~1 "   "

 ( rem -- Write to Log
	 ECHO !@SYSINFO!
	 TYPE %@LOGINFO% | FIND /I "Day(s)"
	 ECHO:
	 ECHO --- Uptime Stats of %~1 for past %@AGE% days
	 ECHO:
	 TYPE %@LOGTEMP% | FIND /I /V "Event Prior"
	 ECHO:
	 ECHO For Complete Details, Type:  UPTIME %~1 /P:%@AGE% /A
	 IF DEFINED @LOGTIME IF EXIST %@LOGTIME% (ECHO: & TYPE %@LOGTIME% | FIND "---")
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Capture Handle Counts and Alarm If Over Minimum (%@MINHANDLES%)
 rem === Updated On: 02 Sep 2025 / 25 Aug 2025 / 14 May 2024 / 16 Sep 2019
 rem ==========================================================================
:HandleCount
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 CALL :Get-PSLIST %~1 "" 1
 SET @FOUND=FALSE
 SET @CNAME=%~1!@SPACES!& SET @CNAME=!@CNAME:~2,16!

 ( rem -- Write to Log
	 IF NOT "%@HHEADER%"=="TRUE" (
		 SET @HHEADER=TRUE
		 ECHO  SERVER NAME          PID  PROCESS NAME %@SPACES:~-25% OPEN HANDLES
		 ECHO %@DIVIDER-%
	 )

	 FOR /F "USEBACKQ SKIP=3 TOKENS=1-12" %%A IN (%@LOGINFO%) DO (
		               IF NOT "%%~L"=="" SET @HANDLE=%%~I
		 IF "%%~L"=="" IF NOT "%%~K"=="" SET @HANDLE=%%~H
		 IF "%%~K"=="" IF NOT "%%~J"=="" SET @HANDLE=%%~G
		 IF "%%~J"=="" IF NOT "%%~I"=="" SET @HANDLE=%%~F
		 IF "%%~I"=="" IF NOT "%%~H"=="" SET @HANDLE=%%~E

		 IF !@HANDLE! GTR %@MINHANDLES% (
			 SET @FOUND=TRUE
			 SET @CERRMSG=& IF !@HANDLE! GTR %@MAXHANDLES% SET @CERRMSG=-- Excessive Handles [^>%@MAXHANDLES%]
			                IF NOT "%%~L"=="" CALL :SetHandleInfo "%%~A %%~B %%~C %%~D %%~E" "%%~F" "%%~I"
			 IF "%%~L"==""  IF NOT "%%~K"=="" CALL :SetHandleInfo "%%~A %%~B %%~C %%~D"      "%%~E" "%%~H"
			 IF "%%~K"==""  IF NOT "%%~J"=="" CALL :SetHandleInfo "%%~A %%~B %%~C"           "%%~D" "%%~G"
			 IF "%%~J"==""  IF NOT "%%~I"=="" CALL :SetHandleInfo "%%~A %%~B"                "%%~C" "%%~F"
			 IF "%%~I"==""  IF NOT "%%~H"=="" CALL :SetHandleInfo "%%~A"                     "%%~B" "%%~E"
			 ECHO  !@CNAME! !@CPID!  !@CPROCESS! !@CHANDLE! !@CERRMSG!
		 )
	 )

	 IF "!@FOUND!"=="TRUE" ECHO:
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Set Variables for Handle Count
 rem === Updated On: 14 May 2024
 rem ==========================================================================
:SetHandleInfo
 rem %1 = Process Name
 rem %2 = Process ID
 rem %3 = Open Handles

 SET @PNAME=%~1
 SET @HANDLE=%~3
 CALL :PadRight @CPROCESS "%~1" " " 40
 CALL :PadLeft  @CPID     "%~2" " "  7
 CALL :PadLeft  @CHANDLE  "%~3" " " 10
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Check for running Endpoint Protection (EPP) Processes
 rem === Updated On: 19 Sep 2024 / 11 Sep 2024
 rem ==========================================================================
:EndPointProtection
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Process name to search for (substring accepted)

 IF NOT DEFINED @EPP_PROCESSES SET "@EPP_PROCESSES= "
 CALL :Get-PSLIST %~1 "" 1 "%@EPP_PROCESSES:"=% Pid.Pri"
 CALL :LogResults %~1 !@LOGTEMP! 2
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Check for running OS and Application Patching Processes
 rem === Updated On: 19 Sep 2024
 rem ==========================================================================
:3rdPartyPatching
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Process name to search for (substring accepted)

 IF NOT DEFINED @PATCH_PROCESSES SET "@PATCH_PROCESSES= "
 CALL :Get-PSLIST %~1 "" 1 "%@PATCH_PROCESSES:"=% Pid.Pri"
 CALL :LogResults %~1 !@LOGTEMP! 2
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display System Memory (via SYSTEMINFO)
 rem === Updated On: 25 Aug 2025 / 18 Aug 2025 / 07 Jul 2025 / 28 Mar 2024
 rem ==========================================================================
:ShowMEM
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 CALL :Get-SYSTEMINFO %~1 /C:"Total Physical Memory: "
 SET @MEMORY=
 FOR /F "USEBACKQ TOKENS=4" %%M IN (!@LOGTEMP!) DO SET @MEMORY=%%~M
 IF DEFINED @MEMORY (
	 SET @MEMORY=!@MEMORY:,=!
	 CALL :FormatNumber !@MEMORY! Bytes @MEMORY
 ) ELSE (
	 SET @MEMORY=.... *** UNAVAILABLE ***
 )
 ECHO Memory for %@CNAME1%!@MEMORY! >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Show Current Time on Server
 rem === Updated On: 25 Aug 2025 / 11 Jan 2022 / 06 Jan 2021
 rem ==========================================================================
:SystemTime
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 SET @TIMEDIAG=
 SET @ALERTMSG=%@SPACES%
 CALL :Get-SYSTEMINFO %~1 "Zone: "

 FOR /F "TOKENS=*" %%T IN ('NET TIME %~1 2^>NUL ^| FIND /I "CURRENT TIME"') DO (
	 FOR /F "TOKENS=5*" %%C IN ('ECHO %%~T') DO CALL :ReturnDateTime @COMPTIME "%%~D" %@TIMEFORMAT%
	 CALL :ReturnDateTime @BASETIME "!TIME!" %@TIMEFORMAT%
	 CALL :CalcElapsed @OFFSET "!@BASETIME!" "!@COMPTIME!" -e Seconds
	 CALL :CalcElapsed @ELAPSED "!@BASETIME!" "!@COMPTIME!"
	 IF !@OFFSET! GEQ 2 SET "@ALERTMSG=[Variance: !@OFFSET! seconds]   "
	 IF "%@DIAGMODE%"=="TRUE" SET @TIMEDIAG="!@COMPTIME!" "!@BASETIME!" "!@OFFSET!" "!@ELAPSED!"
	 SET @CURRENTTIME=%%~T
	 SET @CURRENTTIME=!@CURRENTTIME:?=0!
	 SET @CURRENTTIME=!@CURRENTTIME:%~1 is=%@CNAME1%!
	 FOR /F "USEBACKQ TOKENS=2-3 DELIMS=()" %%O IN (%@LOGTEMP%) DO ECHO !@CURRENTTIME!  [%%~O] %%~P	!@ALERTMSG:~0,114!	!@TIMEDIAG!
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Show NTP Server Settings
 rem === Updated On: 25 Aug 2025 / 16 Dec 2018 / 20 Mar 2016
 rem ==========================================================================
:TimeSource
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 CALL :Get-TimeSource %~1
 CALL :LogResults %~1 %@LOGINFO% 1
 CALL :Get-EVENTS %~1 "NTP"
 CALL :LogResults %~1 %@LOGTEMP% 2 HIDE *
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display OS Platform Information (via DATEINFO)
 rem === Updated On: 25 Aug 2025 / 18-19 Aug 2025 / 30 Sep 2024 / 18 Jun 2024
 rem ==========================================================================
:OSPlatform
 rem %1 = Current System for Which Info Will be Obtained

 rem -- Print Count of Discovered Systems by OS
 IF "%~1"=="----" (
	 ECHO:
	 FOR /F "TOKENS=2-3 DELIMS==#" %%F IN ('SET "#COUNT#" 2^>NUL') DO (
		 CALL :ChangeCase #NAME#%%F -U
		 SET @THISOS=%%F
		 SET @THISOS=!@THISOS:_=,!
		 ECHO 	%%G 	!@THISOS:–= !
		 ECHO 		 -- !#NAME#%%F!
		 ECHO:
	 )
	 EXIT /B
 ) >>%@LOGFILE% 2>&1

 rem -- Main Routine
 CALL :DisplaySysInfo %~1
 IF DEFINED %~1-PLATFORM (
	 ECHO  -%@CNAME2% is running !%~1-RELEASED!
	 SET @THISOS=!%~1-OSEDITION!  {!%~1-OSDATE:-=.!}  !%~1-LATEST:-=.!
	 SET @THISOS=!@THISOS:^(=[!
	 SET @THISOS=!@THISOS:^)=]!
	 SET @THISOS=!@THISOS:,=_!
	 SET @THISOS=!@THISOS: =–!
	 SET /A #COUNT#!@THISOS!+=1
	 CALL :AddName #NAME#!@THISOS!
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display OS and CPU Information (via BWCC DATEINFO)
 rem === Updated On: 25 Aug 2025 / 13 Jul 2025 / 16 Jun 2024 / 20 May 2022
 rem ==========================================================================
:ProcessorInfo-BW
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = If "." Output Another Newline

 CALL :DisplaySysInfo %~1

 ( rem -- Write to Log
	 ECHO !@SYSINFO!
	 ECHO:
	 IF DEFINED %~1-PLATFORM (
		 IF /I "!%~1-TOTAL_RAM!"=="0KB" SET %~1-TOTAL_RAM=***UNKNOWN***
		 ECHO Machine Serial# ... !%~1-SERIAL_NUM!
		 ECHO OS Edition ........ !%~1-RELEASED!
		 ECHO OS Architecture ... !%~1-PLATFORM!
		 ECHO CPU Name .......... !%~1-CPU_NAME!
		 ECHO CPU Family ........ !%~1-CPU_FAMILY!
		 ECHO CPU Sockets ....... !%~1-CPU_SOCKETS!
		 ECHO Physical Cores .... !%~1-PHY_CORES!
		 ECHO Logical Cores ..... !%~1-LOG_CORES!
		 ECHO Physical RAM ...... !%~1-TOTAL_RAM!
		 ECHO Needs a Reboot .... !%~1-NEEDS_REBOOT: =!
		 ECHO %@DIVIDER-%
		 ECHO:
		 IF "%~2"=="." ECHO:
	 )
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Display Machine Serial Number (via BWCC DATEINFO)
 rem === Updated On: 13 Jul 2025 / 09 Feb 2022
 rem ==========================================================================
:SerialNumber
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 ECHO %@CNAME2% Serial # !%~1-SERIAL_NUM! >>%@LOGFILE% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Show SystemState Backups Directories
 rem === Updated On: 25 Aug 2025 / 06 Apr 2021 / 05 Nov 2020
 rem ==========================================================================
:SSBackups
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Optional Parameter to Generate FULL List

 CALL :DisplaySysInfo %~1
 SET @BK_ROOT=%~1\Backups$
 SET @SYSSTATE=%@BK_ROOT%\SystemState
 SET @BACKUPS_DIR="%@TMPPATH%\%@CNAME%.BI-DIR.TXT"
 SET @BACKUPS_TREE="%@TMPPATH%\%@CNAME%.BI-TREE.TXT"

 IF EXIST "!@BK_ROOT!" ( rem -- Obtain or Generate Current Backups$ Share Info
	 ( IF EXIST "%~1\Logs$\Maint\BackupsInfo-TREE.TXT" (TYPE "%~1\Logs$\Maint\BackupsInfo-TREE.TXT") ELSE (
		 TREE "!@BK_ROOT!" /A | FINDSTR /I /R /V %@TREE_REGEX%
	 )) >%@BACKUPS_TREE% 2>&1

	 ( IF EXIST "%~1\Logs$\Maint\BackupsInfo-DIR.TXT"  (TYPE "%~1\Logs$\Maint\BackupsInfo-DIR.TXT")  ELSE (
		 DIR /OGN /B /S "!@BK_ROOT!" | FINDSTR /I /V /R %@MINI_REGEX% | SORT
		 ECHO %@DIVIDER~%
		 DIR /OGD "!@SYSSTATE!" | FIND /I "SystemState-"
		 ECHO %@DIVIDER~%
		 DIR /OGN /S "!@BK_ROOT!" | FINDSTR /I /R "\.ZIP \.7Z"
	 )) >%@BACKUPS_DIR%  2>&1

	 ( rem -- Write to Log
		 ECHO !@SYSINFO!
		 ECHO:

		 IF /I "%~2"=="FULL" (
			 TYPE !@BACKUPS_TREE! | FINDSTR /I /R /V %@FULL_REGEX%
			 ECHO:
			 TYPE !@BACKUPS_DIR!  | FINDSTR /I /R /V %@FULL_REGEX%
		 ) ELSE (
			 TYPE !@BACKUPS_TREE! | FINDSTR /I /R /V %@MINI_REGEX% | FIND /V "          "
			 ECHO:
			 TYPE !@BACKUPS_DIR!  | FINDSTR /I /R /V %@MINI_REGEX%
		 )

		 ECHO %@DIVIDER-%
		 ECHO:
		 ECHO:
	 ) >>%@LOGFILE% 2>&1
 )
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Show or Capture Disk I/O Performance
 rem === Updated On: 25 Aug 2025 / 04 Jan 2021
 rem ==========================================================================
:DiskPerf
 rem %1 = Current System for Which Info Will be Obtained
 rem %2 = Optional Parameter to Generate FULL List

 CALL :DisplaySysInfo %~1
 SET @DISK_IO_LOGS=%~1\Logs$\Maint\Disk-IO.TXT
 SET @READABLE_OPTIONS=-F=" |  " --SK="CPU" --LB="total:" --LA="thread |" --SA="total:"

 ( rem -- Write to Log
	 IF NOT EXIST "%@DISK_IO_LOGS%" (
		 ECHO %@SYSINFO-CON% -- No Logfile Found...
		 ECHO:
	 ) ELSE (
		 FOR %%S IN ("%@DISK_IO_LOGS%") DO SET /A @LOGSIZE=%%~zS
		 ECHO %@SYSINFO-CON% -- This Logfile is Approximately !@LOGSIZE! bytes in size...
		 ECHO:
		 IF "%~2"=="FULL" (READABLE "%@DISK_IO_LOGS%") ELSE (READABLE "%@DISK_IO_LOGS%" %@READABLE_OPTIONS%)
	 )
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Show Any Memory Dump Files (Crash Diagnostics)
 rem === Updated On: 25 Aug 2025 / 23 Jul 2020 / 22 May 2020
 rem ==========================================================================
:MemoryDumps
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 SET @DUMP_REPORT=%~1\Logs$\Maint\OS_DUMPS.TXT

 ( rem -- Write to Log
	 ECHO !@SYSINFO!
	 IF EXIST "%@DUMP_REPORT%" (
		 ECHO %@DIVIDER-%
		 TYPE "%@DUMP_REPORT%"
	 ) ELSE (
		 DIR "%~1\Admin$\*.DMP" /OGD 2>NUL | FINDSTR /R ":[0-9]"
	 )
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Ping Info
 rem === Updated On: 04 Feb 2026
 rem ==========================================================================
:PingProbe
 rem %1 = Current System for Which Info Will be Obtained

 %@TRACK_TIME% %~1 START
 CALL :Get-PING %~1
 CALL :LogResults %~1 %@LOGINFO% 2 "" *
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Traceroute Info
 rem === Updated On: 04 Feb 2026
 rem ==========================================================================
:TraceRouteProbe
 rem %1 = Current System for Which Info Will be Obtained

 %@TRACK_TIME% %~1 START
 CALL :Get-TRACEROUTE %~1
 CALL :LogResults %~1 %@LOGINFO% 2 "" *
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Show GetPrimeNumbers Benchmark Report
 rem === Updated On: 30 Sep 2025 / 25 Aug 2025 / 24 Jan 2022 / 12 Feb 2021
 rem ==========================================================================
:CheckBenchmark_SUMMARY
 rem %1 = Current System for Which Info Will be Obtained

 rem -- Print Sorted List
 IF "%~1"=="----" (
	 TYPE %@TEMPLOG%
	 ECHO:
	 ECHO %@DIVIDER~%
	 ECHO ~~~ FROM LEAST TO MOST NUMBER OF THREADS [CORE COUNT]
	 ECHO %@DIVIDER~%
	 SORT /+%@CPU_SORT1% %@TEMPLOG%
	 ECHO:
	 ECHO %@DIVIDER~%
	 ECHO ~~~ FROM FASTEST TO SLOWEST [SINGLE THREAD]
	 ECHO %@DIVIDER~%
	 SORT /+%@CPU_SORT2% %@TEMPLOG%
	 ECHO:
	 ECHO %@DIVIDER~%
	 ECHO ~~~ FROM FASTEST TO SLOWEST [MULTI-THREAD]
	 ECHO %@DIVIDER~%
	 SORT /+%@CPU_SORT3% %@TEMPLOG%
	 SET #1STRUN=
	 EXIT /B
 ) >>%@LOGFILE% 2>&1

 rem -- Main Routine
 CALL :DisplaySysInfo %~1
 SET @BENCHMARK=%~1\Logs$\Maint\CPU_Benchmark.RECORDING.TXT

 IF NOT DEFINED #1STRUN (
	 TYPE NUL >%@TEMPLOG%
	 SET #1STRUN=TRUE
 )
 IF EXIST "%@BENCHMARK%" FOR /F "TOKENS=3*" %%a IN ('READABLE "%@BENCHMARK%" --ST -1') DO ECHO !@SYSINFO-CON! %%b >>%@TEMPLOG% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Check Job History Logs
 rem === Updated On: 29 Sep 2025 / 25 Aug 2025 / 07 Oct 2019 / 12 Jun 2018
 rem ==========================================================================
:CheckJobHistory
 rem %1 = Current System for Which Info Will be Obtained

 CALL :DisplaySysInfo %~1
 IF NOT DEFINED @LOGFOLDERS SET @LOGFOLDERS="OperationsLog" "SecurityLog" "UptimeReport" "Maint" "EventLogs" "Archiving" "Replication" "Backups" "Audit"

 ( rem -- Write to Log
	 ECHO !@SYSINFO!
	 FOR %%F IN (%@LOGFOLDERS%) DO FOR %%H IN ("%@TMPPATH%\%~1\%%~F\*.RECORDING.TXT") DO (
		 ECHO:
		 READABLE "%%~H" --ST -%@HISTORY%
	 )
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Active Directory Info (via NETDOM/NLTEST/REPADMIN/GPOTOOL)
 rem === Updated On: 13-14 Oct 2025 / 09 Jul 2025 / 29 Sep 2024 / 31 May 2024
 rem ==========================================================================
:GetADInfo
 rem %1 = Current Domain for Which Info Will be Obtained

 ECHO --- DOMAIN: %~1
 SET @DOMAIN-%~1=& FOR /F "TOKENS=2 DELIMS=\_" %%P IN ('NLTEST /DCNAME:%~1 2^>^&1') DO SET @DOMAIN-%~1=%%~P
 SET @MINIDIV=%@DIVIDER~:~-65%

 ( rem -- Write to Log
	 ECHO --- DOMAIN: %~1
	 IF /I "!@DOMAIN-%~1!"=="DCNotFound" (
		 ECHO Cannot Reach the %~1 Domain
	 ) ELSE (
		 IF DEFINED @HAS_NETDOM (
			 SET @DC_LIST=
			 SET @DC_COUNT=0
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 FOR /F "TOKENS=*" %%D IN ('NETDOM QUERY /DOMAIN:%~1 DC 2^>NUL ^| FIND /V " "') DO (
				 ECHO %%D
				 SET /A @DC_COUNT+=1
				 IF NOT "%%~D"=="" IF !@DC_COUNT! LSS 3 SET @DC_LIST=%%~D,!@DC_LIST!
			 )
			 ECHO %@DIVIDER:~-30%
			 ECHO DOMAIN CONTROLLERS FOUND: !@DC_COUNT!
			 ECHO %@DIVIDER:~-30%
			 IF EXIST "%~dp0DNSCheck.BAT" CALL "%~dp0DNSCheck.BAT" | FIND /V "**"
			 CHCP %@CODEPAGE_BWCC%
		 )

		 IF DEFINED @HAS_NLTEST (
			 SET @DC_COUNT=0
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 FOR /F "TOKENS=*" %%D IN ('NLTEST /DCLIST:%~1 2^>NUL ^| FIND "["') DO (
				 ECHO %%D
				 SET /A @DC_COUNT+=1
			 )
			 ECHO %@DIVIDER:~-30%
			 ECHO DOMAIN CONTROLLERS FOUND: !@DC_COUNT!
			 ECHO %@DIVIDER:~-30%
			 ECHO:
		 )

		 IF DEFINED @HAS_NETDOM (
			 ECHO:
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 NETDOM QUERY /DOMAIN:%~1 FSMO 2>NUL
		 )

		 IF DEFINED @HAS_NLTEST (
			 ECHO:
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 NLTEST /SERVER:!@DOMAIN-%~1! /DOMAIN_TRUSTS /ALL_TRUSTS /V 2>NUL
		 )

		 IF DEFINED @HAS_NETDOM (
			 ECHO:
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 NETDOM QUERY /DOMAIN:%~1 TRUST 2>NUL
		 )

		 IF /I "!@HAS_REPADMIN!!@RAN_REPADMIN!"=="TRUE" (
			 SET @RAN_REPADMIN=DONE
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 REPADMIN /REPLSUMMARY * /BYSRC /BYDEST /SORT:DELTA 2>NUL | FIND " "
			 IF DEFINED @VERBOSE REPADMIN /SHOWREPL             2>NUL | FIND " "
		 )

		 IF /I NOT "%@OSNAME:Server=%"=="%@OSNAME%" (
			 IF /I "!@HAS_GPOTOOL!!@RAN_GPOTOOL!"=="TRUE" (
				 SET @RAN_GPOTOOL=DONE
				 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
				 GPOTOOL /DC:!@DC_LIST!
			 )
		 )

		 IF /I "!@HAS_NETPWAGE!!@RAN_NETPWAGE!"=="TRUE" (
			 SET @RAN_NETPWAGE=DONE
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 NETPWAGE /USERS /DOMAIN:%~1 /MIN:200
			 ECHO %@MINIDIV%	!TIME: =0! on !DATE!
			 NETPWAGE /MACHINES /DOMAIN:%~1 /MIN:200
		 )
	 )
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Verify Domain Trusts (via NETDOM)
 rem === Updated On: 25 Aug 2025 / 27 May 2024 / 19 May 2020 / 24 May 2016
 rem ==========================================================================
:VerifyTrusts
 rem %1 = Current System for Which Info Will be Obtained

 rem -- Print Summary of All Systems Needing Reboot
 IF "%~1"=="----" (
	 CALL :SummarizeList @UNTRUSTED_LIST "DOMAIN TRUST ISSUES"
	 EXIT /B
 )

 rem -- Main Routine
 CALL :DisplaySysInfo %~1
 SET @VALID=

 ( rem -- Write to Log
	 ECHO !@SYSINFO!
	 FOR %%D IN (%@DOMAINS%) DO (
		 SET @TRUST=
		 CALL :PadRight @DOMAIN "%%~D " "." 20
		 IF DEFINED @HAS_NETDOM (
			 FOR /F "TOKENS=*" %%V IN ('NETDOM VERIFY !@CNAME! /DOMAIN:%%~D 2^>NUL ^| FIND /I "%@VERIFIED%"') DO SET @VALID=TRUE
			 FOR /F "TOKENS=*" %%V IN ('NETDOM VERIFY !@CNAME! /DOMAIN:%%~D 2^>NUL ^| FIND /I /V "%@SUCCESS%"') DO SET @TRUST=!@TRUST! %%V
			 IF /I "\\!@DOMAIN-%%~D!"=="%~1" (SET @VALID=TRUE& SET @TRUST= Cannot Verify Secure Channel of PDC Emulator [!@DOMAIN-%%~D!] with Itself)
			 IF /I "!@DOMAIN-%%~D!"=="DCNotFound" SET @TRUST= Cannot Reach the %%~D Domain from %~1
		 ) ELSE (
			 SET @TRUST= NETDOM is missing: Cannot Evaluate Relationship between %~1 and the %%~D Domain
		 )
		 ECHO Verifying Trust: !@DOMAIN!!@TRUST!
	 )

	 IF NOT DEFINED @VALID (
		 CALL :AddName @UNTRUSTED_LIST %~1
		 ECHO:
		 ECHO *** NO VALID DOMAIN TRUST FOUND FOR %~1 ***
	 )
	 ECHO %@DIVIDER*%
	 ECHO:
	 ECHO:
 ) >>%@LOGFILE% 2>&1
 %@TRACK_TIME% %~1 STOP
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Get Active Directory Domain Name If Provided
 rem === Updated On: 31 Jul 2024 / 05 Dec 2018
 rem ==========================================================================
:GetDomainName
 rem %1 = Domain Name Input

 SET #DOMAIN=%~1& IF "%~1"=="" SET #DOMAIN=%USERDNSDOMAIN%
 SET #DOMAIN=!#DOMAIN: =!
 SET #DOMAIN=!#DOMAIN:,=.!
 SET #DOMAIN=!#DOMAIN:dc=!
 SET @DOMAIN=& FOR %%D IN (!#DOMAIN!) DO SET @DOMAIN=!@DOMAIN!%%D
 SET #DOMAIN=
 SET @BASEDN=

 FOR /F "TOKENS=1-5 DELIMS=.= " %%D IN ('ECHO !@DOMAIN!') DO (
	 FOR %%z IN ("%%~D" "%%~E" "%%~F" "%%~G" "%%~H") DO IF NOT "%%~z"=="" SET @BASEDN=!@BASEDN!,DC=%%~z
 )

 SET @BASEDN=-b "!@BASEDN:~1!"
 SET @SEARCHDOMAIN=!@DOMAIN!
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
 rem === Updated On: 25 Aug 2025 / 09 Jul 2025 / 11 Sep 2024 / 27 Dec 2020
 rem ==========================================================================
:HelpMessage
 ECHO Generates a daily report of system uptime for multiple systems
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
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO       /S  .... Schedule the Job Only
 ECHO       /U  .... Unschedule the Job Only, Without Executing It First
 ECHO       /N  .... Execute the Job, But Do Not Schedule It
 ECHO       /Q  .... Generate Log File, But Don't Send Mail
 ECHO       /M  .... Mail Current Log File without Regenerating It First
 ECHO       /T  .... Use A Test List of Servers/Computers
 ECHO       /RC .... Use Regular Monitoring Configuration List  %@DEFAULT%
 ECHO       /LC .... Use Limited Monitoring Configuration List (for testing)
 ECHO       /L  .... Use Pre-Existing Computer List; Don't Enumerate Domain/Workgroup  %@DEFAULT%
 ECHO       /CL .... Specify Name of Server List to Use  (overrides normal and test list)
 ECHO       /CC .... Specify Name of Config List to Use  (overrides normal and test list)
 ECHO       /G  .... Generate Dynamic Domain/Workgroup List with Servers Only
 ECHO       /GW .... Generate Dynamic Domain/Workgroup List with Servers and Workstations
 ECHO       /C  .... Cleanup Old Temp Folders and Files
 ECHO       /IM+ ... Enable Individual Job Duration Timing per System
 ECHO       /IM- ... Disable Individual Job Duration Timing per System
 ECHO       /UPL ... Use Legacy Microsoft Uptime.exe from Resource Kit
 ECHO       /UP2 ... Use Newer UPTIME2.EXE for gathering system uptime  %@DEFAULT%
 ECHO       /A+ .... Show Active Directory Domain Info  %@DEFAULT%
 ECHO       /A- .... Do Not Show Active Directory Domain Info
 ECHO       /P+ .... Enable Parallelism (Concurrency) for Long Jobs  %@DEFAULT%
 ECHO       /P- .... Disable Parallelism (Concurrency) for Long Jobs
 ECHO       /HC .... Set Maximum Parallel Jobs to 199
 ECHO       /R+ .... Show Concurrency Diagnostics During Execution
 ECHO       /R- .... Hide Concurrency Diagnostics During Execution  %@DEFAULT%
 ECHO       /D  .... Enable Diagnostics Mode  (also --DIAG)
 ECHO       /QA .... Enable QA Testing Mode (includes /D /T /HC /Q /NP /A-)  (also --QATEST)
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 /S
	 ECHO  %~n0 /G /HC
	 ECHO  %~n0 /CL:"D:\MyOwnList.TXT"
	 ECHO  %~n0 /M
	 ECHO  %~n0 /Q /T
	 ECHO  %~n0 /R+
	 ECHO  %~n0 /D /P+
	 ECHO  %~n0 /QA
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
	 ECHO  * Using the /QA option will supersede all other related options.
 )
 CALL :ShowStatus "FINISHED"
                                                                                                 