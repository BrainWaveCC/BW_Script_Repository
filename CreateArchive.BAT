@ECHO OFF
 rem ==========================================================================
 rem === Create Multi-Instance Backups and/or Compressed Archives of Folders
 rem ==========================================================================
 rem
 rem Created On: 18 Apr 2003
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 26 Sep 2024 / 08 Sep 2024 / 30 Aug 2024 / 28 Jul 2024
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2003 and later
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    Blat ................... http://www.blat.net/
 rem    7-Zip .................. https://www.7-zip.org/7z.html
 rem    InfoZip Utilities ...... http://sourceforge.net/projects/infozip/files/
 rem    ShadowSpawn ............ https://github.com/candera/shadowspawn/downloads
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    ArchiveInfo.TXT ........ List of source and destination folder(s)
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================

 :::  This script creates a multi-instance backup of data files found in any
 :::  user-selected folder.  By default, data will be copied from the source
 :::  to the destination once per day.  If no changes have been made in the
 :::  source tree, then no new backup will be generated.
 :::
 :::  Backups that are created contain timestamp information in the folder name
 :::  so that it is easy to determine where to look for chronological restores.
 :::  is created with a name which indicates the time of the backup attempt.
 :::  To avoid clutter, the last 7 backups are maintained in the primary
 :::  backup folder, and an additional 21 are stored in the archive folder.
 :::
 :::  These defaults can all be changed by altering the three %@KEEP_*%
 :::  variables, or by using the ReplicationInfo.TXT file.
 :::
 :::  (Sep 2011) v4.0 -- It is now possible to skip the creation of either the
 :::  daily backup or the daily zip archive using settings in the config file
 :::  (ReplicationInfo.TXT).  Additionally, if a retention value of 0 is used
 :::  for the number of files to keep (for either the backups or the zips),
 :::  then no backups of that type will be maintained.  Use the @MAKE_FILES and
 :::  @MAKE_TIMED variables to control whether or not those backup types are
 :::  generated.  If a @MAKE_ variable is FALSE, then the corresponding @KEEP_
 :::  variable will be ignored, and all backups of that type will be deleted
 :::  (or they would get out of sync).  It is now possible to enumerate all
 :::  possible backup jobs.  It has also been renamed to CreateArchive.BAT to
 :::  better align with the new CheckArchive.BAT script.
 :::
 :::  (Sep 2011) v4.6 -- The script reads the ArchiveInfo.TXT file rather than
 :::  the ReplicationInfo.TXT text.  Although these two files serve a similar
 :::  purpose, it is easy to get them mixed up and use the incorrect parameters
 :::  because they serve different types of scripts. This change should make it
 :::  easier to manage both sets of input files.
 :::
 :::  (Dec 2011) v4.8 -- Simplified the job scheduling section by way of
 :::  environment variables for verifying whether to use SCHTASKS or the AT
 :::  command.
 :::
 :::  (Dec 2011) v5.0 -- Added the ability to create daily, monthly and annual
 :::  archives, in addition to the existing folder backups and timed archive.
 :::  This functionality was previously available in the precursor to this script
 :::  (Freelancer-Archive.BAT).
 :::
 :::  (Feb 2012) v5.3 -- Enabled to option to save backup files to the root
 :::  destination folder (without jobname or computer name) by setting the
 :::  @SIMPLEDEST variable to "TRUE" in the ArchiveInfo.TXT config file. Also
 :::  added the ability to email the job logs to recipients using the variables
 :::  from the CustomVariables.TXT input file.
 :::
 :::  (Apr 2012) v5.7 -- Synchronized several subroutines across the entire
 :::  family of SQL*.BAT and *Archive*.BAT scripts, including the routines for
 :::  calculating/displaying free disk space before and after copy/delete
 :::  operations.
 :::
 :::  (Sep 2012) v5.8 -- Added the option to execute the job from the command
 :::  line without scheduling it -- even if the job has a schedule associated
 :::  with it in the config file.
 :::
 :::  (Nov 2012) v6.0 -- Added an option for a delay between scheduled job
 :::  time and actual job execution, using the @JOBDELAY variable.  Also
 :::  expanded the logging of environment variables for diagnostics, including
 :::  the indication of whether XCOPY or ROBOCOPY is being used for a particular
 :::  job.
 :::
 :::  (Nov 2012) v6.1 -- To compensate for a parsing bug in the task scheduler
 :::  of certain versions of Windows (including Windows 8), the script was
 :::  changed to eliminate the use of quotation marks in the job parameters.
 :::  For more details, see: http://support.microsoft.com/kb/951246
 :::
 :::  (Dec 2012) v6.2 -- Changed the routine for evaluating file/folder exemptions
 :::  in order to make the comparisons consistent across the execution of the
 :::  DIR, XCOPY, ROBOCOPY and ZIP commands.  This change will result in
 :::  one-time backups of folders where the data has been otherwise unchanged
 :::  (this will be true across all backup types: timed, daily, monthly, etc).
 :::
 :::  (Dec 2012) v6.3 -- Made it possible for the scheduled tasks to be stored
 :::  in their own subfolder, rather than the default root folder of the Task
 :::  Scheduler.
 :::
 :::  (Aug 2013) v6.4 -- A generated scheduled task can now be deleted by using
 :::  a command-line parameter.
 :::
 :::  (Sep 2013) v6.5 -- The TIMINGS Logfile will be reduced to the minimum
 :::  row size whenever it exceeds the maximum log row size, as defined by the
 :::  following variables:  %@MAX_LOG_ROWS% and %@MIN_LOG_ROWS%
 :::
 :::  (Oct 2013) v6.9 -- The delimiter for all parameters can be either the
 :::  "-" or the "/" character.  This includes the help parameters.
 :::
 :::  (Oct 2013) v7.0 -- There is now an option to generate large zip files
 :::  destined for remote shares locally, before copying them over. Also, the
 :::  function that copied an existing, current ZIP file rather than create a
 :::  new zip for subsequent jobs, has been fixed so that it does not look only
 :::  at the TIMED zip file.
 :::
 :::  (Nov 2013) v7.1 -- The primary mechanism for file comparison is the FCIV
 :::  tool from Microsoft, which compares the hash of the file, rather than the
 :::  directory entry of the file.  If FCIV is not found in the Utils folder,
 :::  then the older directory comparison methods will be used. FCIV makes it
 :::  possible to avoid generating a new archive if the file dates are changed
 :::  for any reason (such as changes related to Daylight Savings time).
 :::
 :::  (Nov 2013) v7.3 -- A DIR-only file comparison can be enabled by setting
 :::  the new @EXTENDED_COMP variable to FALSE.  This will ignore any of the
 :::  file integrity checkers (currently only works in CreateArchive.BAT) to
 :::  greatly improve the performance of processing very large directory trees.
 :::
 :::  (Nov 2013) v7.4 -- There are now four utilities that can be used for
 :::  extended file integrity checks: FCIV, FSUM, MD5SUM, and the new BrainWave
 :::  FileHash.EXE. FCIV is pretty much the fastest of the 4, but its exclusion
 :::  parameter does not work properly, making its implementation a little bit
 :::  harder than it should be. FSUM is faster than FCIV when executed within a
 :::  FOR loop, but it generates extra output text that must be redirected.
 :::  MD5SUM is an old staple, is very small and pretty fast, and is known on
 :::  multiple platforms. FileHash only provides basic MD5 hash generation at
 :::  this time, but it is being developed to support the ability to process a
 :::  list of files, with or without an exclusion list.
 :::
 :::  (Nov 2013) v7.5 -- The script will now display any currently scheduled
 :::  CreateArchive.BAT jobs on the current system, when the list of valid
 :::  jobs is displayed.  This requires an elevated prompt in 2008 and later
 :::  editions of Windows.
 :::
 :::  (Dec 2013) v7.8 -- It is now possible to remove the base path name from
 :::  the directory comparison text files, which will result in more readable
 :::  log files. This can be controlled from the command-line, or by the use
 :::  of the @HIDE_BASE_PATH variable.
 :::
 :::  (Jan 2014) v8.0 -- It is now possible to provide individual file and/or
 :::  directory exemptions that apply to a specific SOURCE/DESTINATION archive
 :::  pair within a larger archive job.  The associated file/folder exemption
 :::  variables (@SKIPDIR, @SKIPFILE, @EXEMPTION) must have suffixes which
 :::  match the @DEST variables that they are intended to be associated with
 :::  (e.g. @SKIPDIR1 or @EXEMPTION2A).  The ROBOCOPY command relies upon the
 :::  @SKIPDIR and @SKIPFILE variables, and the @EXEMPTION variables are used
 :::  by XCOPY, ZIP and the FIND/FINDSTR commands (for generating the folder
 :::  comparisons), so both the @SKIP* and @EXEMPTION* variables should be
 :::  used when customizations are made.
 :::
 :::  (Feb 2014) v8.1 -- Added the capability to send log data to one or more
 :::  Syslog servers using the SyslogGen or NeoLog utilities in conjunction
 :::  with the @SYSLOGx environment variables.
 :::
 :::  (Mar 2014) v8.2 -- Upgraded the DebugMode options to add another
 :::  variable (@PRINT_IF_DEBUG). Also revamped the routines for logging to
 :::  Syslog servers.
 :::
 :::  (Apr 2014) v8.3 -- Added timing subroutine to assist in tracking the
 :::  execution times of long-running archive jobs.
 :::
 :::  (Apr 2014) v8.4 -- It is now possible to remove the full path name from
 :::  the directory comparison text files, which will result in more readable
 :::  log files containing only filenames and the associated hash. This can be
 :::  controlled from the command-line, or by the use of the @HIDE_FULL_PATH
 :::  variable. The command-line options for both @HIDE_ options were updated.
 :::
 :::  (Sep 2014) v8.8 -- Corrected a long-standing issue with file/folder
 :::  exclusions by adding the /L parameter to the FINDSTR command, resulting
 :::  in reduced job execution times for archives with extensive exclusions.
 :::
 :::  (Sep 2014) v9.0 -- Added a fastmode option (@FASTMODE=TRUE) to reduce
 :::  post-processing of the comparison files. This option can only be used
 :::  with the FCIV (extended mode) or basic DIR (basic mode) comparisons.
 :::  When FastMode is enabled, the /SF, /HB and /HF (show/hide path) options
 :::  have no effect (only filenames will be shown in DIR comparison mode,
 :::  and full paths will be automatically shown in FCIV comparison mode).
 :::
 :::  (Oct 2014) v9.1 -- Fastmode can be set for individual jobs, using the
 :::  same method as with the custom file/folder exemptions (e.g. @FASTMODE1B
 :::  or @FASTMODE2A).
 :::
 :::  (Oct 2014) v9.3 -- FSUM is now the preferred utility for all hash
 :::  generation functions, and the script can now make use of it in Fastmode.
 :::
 :::  (Oct 2014) v9.4 -- Added error checking for destination paths,
 :::  differentiating between UNC and mapped drives.
 :::
 :::  (Dec 2014) v9.5 -- Added the ability to select from a list of possible
 :::  source folders for a single job.  The last valid folder in the list is
 :::  selected for the job.  The letters A through K are valid variables for
 :::  the list elements. (e.g. @SOURCE1A to @SOURCE1K)
 :::
 :::  (Jan 2015) v9.6 -- Updated to use the new logfile maintenance routine.
 :::
 :::  (Mar 2015) v9.7 -- Migrated more variables to SetDrive.BAT
 :::
 :::  (Mar 2015) v9.8 -- Track total elapsed time of backup job using a new
 :::  version of DATEINFO
 :::
 :::  (Nov 2015) v9.10 -- Removed DNS error output from the Syslog routines.
 :::
 :::  (Mar 2017) v10.0 -- Added the ability to generate SHA1 and SHA2_256
 :::  hashes; The default hash is still MD5 for the sake of interoperability;
 :::  BrainWave FileHash now supports SHA1 and SHA2 hashes, along with MD5;
 :::  Added a @SORT_LIST variable to regulate pre-comparison file processing
 :::
 :::  (Oct 2017) v10.1 -- Added destination info to console output
 :::
 :::  (Nov 2017) v10.2 -- Added --silent parameter to FNR text replacement
 :::
 :::  (Dec 2017) v11.0 -- Multiple source and destination folders are checked
 :::  for validity, and then the FIRST valid folder from the list is selected
 :::  for each category;  The entire source folders need to actually exist at
 :::  run-time, but for the destination folders, only the drive letter or UNC
 :::  path is checked, as the folder can legitimately be created during the
 :::  archive job.  This used to be the intended method of operation, but it
 :::  was inadvertently broken in a previous release.  To see all potential
 :::  folders for a job, run the -c option, which calls CheckArchive.BAT.
 :::  CheckArchive.BAT v5.0 was synchronized with CreateArchive.BAT v11.0
 :::
 :::  (Jan 2018) v11.2 -- Fixed a new issue with using FINDSTR /R /C when
 :::  checking for scheduled jobs.
 :::  -- Migrated :SaveJobHistory to a subroutine, for additional flexibility.
 :::  -- Invalid job attempts are now recorded in the .RECORDING.TXT file.
 :::  -- Changed the HELP routine to use FINDSTR.
 :::
 :::  (Feb 2018) v11.3 -- Added filtered CMD Title Routine;
 :::  -- Added @LIVEJOBS counter to the .RECORDING.TXT status file.
 :::
 :::  (Mar 2018) v12.0 -- The SYNTAX HELP routine has been updated;
 :::  -- The release of FILEHASH v2.x provides the following functionality:
 :::  traverse folders natively; display full path, filenames only, or hide
 :::  base path; perform file exclusions inline; display the size of hashed
 :::  files; provide an FSUM-compatible display mode;
 :::  -- FILEHASH is now the preferred hash utility for the entire script
 :::  repository, and routines which use it have been upgraded accordingly;
 :::  -- Support for both MD5SUM and FCIV have been eliminated from this script;
 :::  -- Support for NeoLogger has been eliminated from this script.
 :::
 :::  (Apr 2018) v12.1 -- FILEHASH can now write directly to a text file;
 :::  -- Removed support for FSUM, which has greatly simplified the script;
 :::  -- With FSUM gone, the need for FNR has been eliminated as well.
 :::
 :::  (Apr 2018) v12.2 -- Improved the performance of reading variables from
 :::  the ArchiveInfo.*.TXT INPUT files, using FINDSTR;
 :::  -- Changed Script Documentation to www.BrainWaveCC.com
 :::
 :::  (Jul 2018) v12.3 -- The new BrainWave CheckParams utility is now used to
 :::  check for the /H and /? parameters, replacing the use of FIND/FINDSTR;
 :::
 :::  (Aug 2018) v13.0 -- Removed AT command support;
 :::  -- Files larger than @MAX_FILE_SIZE bytes will not be hashed;
 :::  -- FileHash64.exe will be called in place of FileHash.exe on Windows x64;
 :::
 :::  (Oct 2018) v13.1 -- Corrected and expanded the DEBUG logging routine;
 :::
 :::  (Mar 2019) v14.0 -- On 64-bit Windows, the x64 utilities folder is placed
 :::  ahead of the 32-bit only utilities in the PATH, favoring the execution of
 :::  the 64-bit edition of FileHash.exe over the 32-bit edition;
 :::  -- Extended use of CHECKPARAMS to check for separate parameter besides /? /H;
 :::  -- Added support for the somewhat slow SHA3_384 as a hashing algorithm;
 :::  -- Removed support for selecting separate hash utilities (/E:xxxx);
 :::  -- Record additional attributes in the Job History log;
 :::  -- Enabled Code Page 1252 Support;
 :::
 :::  (Jun 2019) v15.0 -- Replaced Info-Zip utilities with 7-Zip;
 :::  -- The new @FILESPEC variable enables more granularity on backup jobs;
 :::  -- Added ShadowSpawn and @USE_VSS to enable VSS copies of locked files;
 :::  -- Refactored the :GetParams routine using the CheckParams.exe utility;
 :::  -- The new @FORCE_BACKUP variable enables TIMED backups to be performed,
 :::  even if no file changes are detected;
 :::
 :::  (Jul 2019) v16.0 -- Brought back support for the Info-Zip utilities;
 :::  -- The @USE_7Z variable can be used to use 7z over the default Zip.exe;
 :::  -- The @ITEMIZED_INC variable creates an itemized include list where
 :::  each individual file to be archived is enumerated on its own line;
 :::  -- The @SAMESOURCE variable allows the jobs to run faster by making use
 :::  use of previously generated zip files;
 :::  -- Using + instead of * for Include/Exclude lists is now optional;
 :::  -- Debut of SubString.exe to more easily manage string substitutions;
 :::  -- Removed some earlier change log updates prior to v4.0;
 :::
 :::  (Oct 2019) v16.1 -- Simplified the /C Parameter Validation;
 ::: -- Updated :ShowStatus routine to reset TITLE/CodePage;
 :::
 :::  (Oct 2019) v16.2 -- Update :PadLeft and :PadRight routines;
 :::
 :::  (Dec 2019) v16.3 -- New method to determine if 64-bit FILEHASH is running;
 :::
 :::  (Dec 2019) v16.4 -- Updated :ShowStatus routine to use BrainWave NOW.exe;
 :::
 :::  (Jan 2020) v16.5 -- Refactored the :Prepare4Syslog routine;
 :::  -- Consolidate :PadLeft and :PadRight routines;
 :::  -- Corrected the :GetParams routine to deal with quoted custom values;
 :::  -- Added a routine for validating integer parameters;
 :::
 :::  (May 2020) v17.0 -- Migrated :DebugMode routine to SetDrive.BAT;
 :::  -- Replaced FINDSTR with BrainWave ReadConfig.exe for reading config file;
 :::  -- Added support for more hash algorithms including BLAKE3 and XXHash64;
 :::  -- Changed fallback hash, if none supplied, from MD5 to XXHASH64;
 :::  -- Streamlined Completion Status via NOW.EXE;
 :::  -- Added support for a MINI edition of the ARCHIVE-INFO config file;
 :::
 :::  (Jul 2020) v17.1 -- Support for FILEHASH's NOHASH mode is available via
 :::  /$:NOHASH or /NH -- both of which are more flexible than DIR mode;
 :::
 :::  (Nov 2020) v17.2 -- Provided extended HELP options (--?? / --H2);
 :::  -- New CHECKPARAMS syntax for processing extended help options;
 :::
 :::  (Jan 2022) v17.3 -- Modify the @NAMECHK verification to include \ prefix;
 :::  -- Use DATEINFO to generate dynamic random numbers for Local ZIP archives;
 :::  -- Perform additional checks to ensure that multi-config jobs are identical
 :::  before using existing ZIP archives from the current backup session;
 :::
 :::  (Oct 2023) v17.4 -- Change the way the @SCRIPT_BEG# variable is
 :::  calculated in various subroutines by using DATEINFO instead of %DATE%;
 :::
 :::  (Apr 2024) v17.5 -- Check for essential utilities with FINDFILES;
 :::  -- Add logging when (un)scheduling jobs;
 :::
 :::  (May 2024) v17.6 -- Provide option to add file date/time stamps to
 :::  comparison logs for hash jobs;
 :::
 :::  (Jul 2024) v17.7 -- Replaced the :RunCMD routine with just a CALL command;
 :::
 :::  (Sep 2024) v17.8 -- Call SetDrive.BAT with option for 1252 as code page;
 :::  -- Extended :ForwardToSyslog to update any locally running syslog service;
 :::  -- Created :LogCriticalFailure routine for early job failures;
 :::
 :::
 :::  ADDITIONAL SCRIPTING TOOLS/INFO:
 :::  -------------------------------------------------------------------------
 :::  https://www.BrainWaveCC.com/knowledge-base/scripting-and-automation-options-for-windows/
 :::  https://www.BrainWaveCC.com/knowledge-base/must-have-utilities-for-windows-usersadmins/
 :::  -------------------------------------------------------------------------


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 21 Jul 2020 / 25 Feb 2018
 rem ==========================================================================
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 26 Sep 2024 / 08 Sep 2024 / 30 Aug 2024 / 28 Jul 2024
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v17.8.0.2081 b

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage
 CHECKPARAMS --rc -c "C CHECK" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :CheckJobConfig

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT" "%~dp0CheckArchive.BAT" CHANGECASE.EXE FILEHASH.EXE SUBSTRING.EXE
 SET #MSUTILS=ATTRIB.EXE CHOICE.EXE FC.EXE FINDSTR.EXE ROBOCOPY.EXE SCHTASKS.EXE SORT.EXE TIMEOUT.EXE XCOPY.EXE
 SET #O_UTILS=BLAT.EXE SHADOWSPAWN.EXE SYNC.EXE SYSLOGGEN.EXE TAIL.EXE ZIP.EXE 7Z.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% %#O_UTILS%
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES& GOTO :ExitBatch)

 rem -- Set Initial Duration Values
 SET @CYCLE=FILES TIMED DAILY MONTHLY YEARLY
 FOR %%T IN (%@CYCLE%) DO (
	 SET @MAKE_%%T=FALSE
	 SET @KEEP_%%T=FALSE
 )

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @SORT_LIST=TRUE
 SET @MAIL=FALSE
 SET @MAILPORT=25
 SET @FILESPEC=*.*
 SET @FORCE_BACKUP=
 SET @ITEMIZED_INC=
 SET @USE_7Z=
 SET @USE_VSS=
 SET @VSS_VERBOSITY=/VERBOSITY=2
 SET @MAX_FILE_SIZE=500,000,000

 rem -- Default Hash Values
 SET @HASHUTIL=FILEHASH
 SET @THISHASH=MD5
 SET @FALLBACK_HASH=XXHASH64
 SET @HASH_MATRIX="NOHASH:21:NONE"  "MD5:32:"":+"  "SHA1:40"  "SHA2 SHA2_256:64:SHA256"  "SHA2_384:96:SHA384"  "SHA2_512:128:SHA512"  "SHA3:64:SHA3_256"  "SHA3_384:96"  "SHA3_512 BLAKE2B:128"  "BLAKE2S BLAKE3:64"  "XX64:16:XXHASH64"

 rem -- Job Scheduling Variables
 SET @JOBNAME=Backup Data - %~1
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=DAILY
 SET @JOBTIME=01:00:00
 SET @JOBDATE=
 SET @JOBPATH="%~f0" %~1
 SET @JOBVRFY=%~1
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0" 1252

 rem -- Grab Appropriate Custom Variables from ArchiveInfo.*.TXT
 SET @INFO=INVALID JOB {%~1}
 FOR %%C IN ("%@ARCHIVE-INFO%" "%@ARCH-INFO-MINI%") DO IF EXIST "%%~C" (
	 FOR /F "TOKENS=*" %%R IN ('READCONFIG "%%~C" -F "%~1" 2^>NUL') DO CALL %%R
	 FOR /F "TOKENS=1 DELIMS=;" %%J IN ('READCONFIG "%%~C" -N -S "#CREATEARCHIVES" -P 2^>NUL') DO SET @VALIDJOB-%%~J=%%~J& SET @JOBLIST=TRUE
 )
 FOR %%N IN (JOBNAME INFO) DO CALL :ReplaceParentheses @%%N

 rem -- Main Variables
 SET @CHANGES=FALSE
 SET @RUNMODE=
 SET @JOBCOUNT=0
 SET @LIVEJOBS=0
 SET @TOTAL_PRUNED=0
 SET @TOTAL_BACKUPS=0
 SET @JOBFOLDER=%~1.%COMPUTERNAME%
 SET @FC=FC /C /L /N /LB7

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Backups
 SET @LFORMAT=%@LOGPATH%\%~n0-%~1
 SET @TIMINGS=%@LFORMAT%.RECORDING.TXT
 SET @ZIP_INC=%@LFORMAT%.Z_Include.TXT
 SET @ZIP_EXC=%@LFORMAT%.Z_Exclude.TXT
 SET @NO_COPY=%@LFORMAT%.C_Exclude.TXT
 SET @LOGFILE=%@LFORMAT%.%@FILESTAMP%
 FOR %%L IN (SUMMARY TEMPLOG ERRORS TEMP1 TEMP2) DO SET @%%L=%@LFORMAT%.%%L.%@FILESTAMP%
 FOR %%L IN (Current Timed Daily Monthly Yearly) DO SET @%%L_LOG=%@LFORMAT%.%%L.Comp
 SET @RUNTHIS=%@LFORMAT%.ExecuteZip#%@RANDOM%.BAT
 SET @LOGLIST="%@LOGFILE%" "%@ERRORS%"
 SET @CLEANUP="%@TEMPLOG%" "%@ERRORS%" "%@SUMMARY%" "%@ZIP_INC%" "%@ZIP_EXC%" "%@NO_COPY%" "%@TEMP1%" "%@TEMP2%" "%@RUNTHIS%"

 rem -- Standard Processing Variables
 SET @EXTENDED_COMP=TRUE
 SET @FASTMODE=TRUE
 SET @XCOMPARE=TRUE
 SET @VS=-

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Validate Legitimate File Size Exemptions for FILEHASH processing
 CALL :GetInteger @MAX_SIZE "%@MAX_FILE_SIZE%" 500000000 5000 9999999999

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "$" @THISHASH & IF DEFINED @OK IF NOT DEFINED @THISHASH (GOTO :HelpMessage) ELSE (SET @EXTENDED_COMP=TRUE)
 CALL :GetParams "F" @FILESPEC & IF DEFINED @OK IF NOT DEFINED @FILESPEC (GOTO :HelpMessage)
 CALL :GetParams "T" @MINROWS  & IF DEFINED @OK (
	 SET @MAXROWS=1
	 CALL :GetInteger @MINROWS "%@MINROWS%" 1 1 10
 )
 CALL :GetParams "N"   & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "S"   & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE)
 CALL :GetParams "U"   & IF DEFINED @OK (SET @NOSCHED=FALSE& SET @UNSCHED=TRUE)
 CALL :GetParams "B"   & IF DEFINED @OK (SET @FORCE_BACKUP=TRUE)
 CALL :GetParams "VSS" & IF DEFINED @OK (SET @USE_VSS=TRUE)
 CALL :GetParams "VS-" & IF DEFINED @OK (SET @USE_VSS=)
 CALL :GetParams "ZIP" & IF DEFINED @OK (SET @USE_7z=)
 CALL :GetParams "IZ"  & IF DEFINED @OK (SET @USE_7z=)
 CALL :GetParams "7z-" & IF DEFINED @OK (SET @USE_7z=)
 CALL :GetParams "7z"  & IF DEFINED @OK (SET @USE_7z=TRUE)
 CALL :GetParams "BL"  & IF DEFINED @OK (SET @ITEMIZED_INC=)
 CALL :GetParams "IL"  & IF DEFINED @OK (SET @ITEMIZED_INC=TRUE)
 CALL :GetParams "SS"  & IF DEFINED @OK (SET @SAMESOURCE=TRUE)
 CALL :GetParams "SS-" & IF DEFINED @OK (SET @SAMESOURCE=)
 CALL :GetParams "HB"  & IF DEFINED @OK (SET @HIDE_BASE_PATH=TRUE)
 CALL :GetParams "HF"  & IF DEFINED @OK (SET @HIDE_FULL_PATH=TRUE)
 CALL :GetParams "SF"  & IF DEFINED @OK (SET @HIDE_BASE_PATH=FALSE& SET @HIDE_FULL_PATH=FALSE)
 CALL :GetParams "SD"  & IF DEFINED @OK (SET @SHOW_FILE_DATE=TRUE)
 CALL :GetParams "FE"  & IF DEFINED @OK (SET @FASTMODE=TRUE)
 CALL :GetParams "FD"  & IF DEFINED @OK (SET @FASTMODE=FALSE)
 CALL :GetParams "R"   & IF DEFINED @OK (SET @USE_ROBOCOPY=TRUE)
 CALL :GetParams "X"   & IF DEFINED @OK (SET @USE_ROBOCOPY=FALSE)
 CALL :GetParams "D"   & IF DEFINED @OK (SET @EXTENDED_COMP=FALSE& SET @HASHUTIL=)
 CALL :GetParams "E"   & IF DEFINED @OK (SET @EXTENDED_COMP=TRUE&  SET @HASHUTIL=FILEHASH)
 CALL :GetParams "NH"  & IF DEFINED @OK (SET @EXTENDED_COMP=TRUE&  SET @HASHUTIL=FILEHASH& SET @THISHASH=NOHASH)
 CALL :GetParams "O"   & IF DEFINED @OK (SET @USE_SYSLOGS=TRUE)
 CALL :GetParams "Q"   & IF DEFINED @OK (SET @USE_SYSLOGS=FALSE)
 CALL :GetParams "SO"  & IF DEFINED @OK (SET @SORT_LIST=TRUE)
 CALL :GetParams "NS"  & IF DEFINED @OK (SET @SORT_LIST=)
 CALL :GetParams "Z"   & IF DEFINED @OK (SET @TESTMODE=TRUE)
 CALL :GetParams "L"   & IF DEFINED @OK (SET @DIAGMODE=TRUE)
 CALL :GetParams "V"   & IF DEFINED @OK (SET @SHOWALL=TRUE& GOTO :HelpMessage)

 rem -- Obtain Free Drive for Use with VSS
 SET @VSS=& FOR %%F IN ("%@UTILS64%" "%@UTILS%") DO IF EXIST "%%~F\ShadowSpawn.exe" SET @VSS=ShadowSpawn
 CALL :FindFreeDrive @DRV
 FOR %%V IN (DRV VSS) DO IF NOT DEFINED @%%V SET @USE_VSS=

 rem -- Determine Valid Hash and Set Associated Variables
 CALL :ValidateHash @THISHASH @SORTLEN

 rem -- Determine if Running in x64 Mode
 FOR /F "TOKENS=3" %%X IN ('FILEHASH --Version-Only 2^>^&1') DO IF /I "%%~X"=="x64" (
	 SET @x64_MSG=64-bit Mode
	 SET @x64_MODE= // !@x64_MSG!
 )

 rem -- Set Comparison Info Variables
 SET @HASHOPT=--%@THISHASH%
 SET @COMPMODE=%@THISHASH% HASH& IF /I "%@THISHASH%"=="NONE" SET @COMPMODE=NO HASH
 SET @COMPTYPE=NORM& IF /I "%@FASTMODE%"=="TRUE" SET @COMPTYPE=FAST
 SET @COPYUTIL=XCOPY& IF DEFINED @ROBOCOPY IF /I "%@USE_ROBOCOPY%"=="TRUE" SET @COPYUTIL=ROBOCOPY

 IF "%@FILEHASH64%%@FILEHASH%"=="" SET @HASHUTIL=
 IF NOT DEFINED @HASHUTIL (
	 SET @XCOMPARE=FALSE
	 SET @COMPMODE=DIR Time/Date Stamp
	 SET @HASHUTIL=DIR
	 SET @THISHASH=NONE
	 SET @SORTLEN=45
 )

 rem -- Set Zip Compression Variables
 SET @ZIPUTIL=ZIP& IF DEFINED @USE_7z SET @ZIPUTIL=7z

 rem -- Set Variables for Test Configurations
 IF /I "%@DIAGMODE%"=="TRUE" SET @RUNMODE= // VERBOSE
 IF /I "%@TESTMODE%"=="TRUE" (
	 CALL :GetInteger @MINROWS "%@T_MIN_LOG_ROWS%" 003 001 010
	 CALL :GetInteger @MAXROWS "%@T_MAX_LOG_ROWS%" 030 010 049
	 SET @MAILSENDER=LogAdmin-Test%@ORGFQDN%
	 SET @RCPT-TO=%@TEST-RCPTS%
	 SET @ALERT-TO=%@TEST-RCPTS%
	 SET @RUNMODE=!@RUNMODE! // TESTMODE
 )

 rem -- Set Variables for Special Modes
 SET @NOSCHED_MSG=Don't Schedule
 SET @UNSCHED_MSG=Unschedule
 SET @UPDATESCHED_MSG=Update Schedule
 SET @SCHEDULEONLY_MSG=Schedule ONLY
 SET @DIAGMODE_MSG=Diagnostics Logs
 SET @TESTMODE_MSG=Testing Mode
 SET @HIDE_BASE_PATH_MSG=Hide Base Path
 SET @HIDE_FULL_PATH_MSG=Filenames Only
 SET @XCOMPARE_MSG=Extended File Comparison
 SET @USE_SYSLOGS_MSG=Forward to Syslog
 SET @USE_LOCAL_ZIP_MSG=Local Zip Mode
 SET @FASTMODE_MSG=Fast Compare Mode
 SET @FORCE_BACKUP_MSG=Forced Backup Mode
 SET @SORT_LIST_MSG=File List Sorted
 SET @USE_VSS_MSG=Shadow Copy Mode
 SET @ITEMIZED_INC_MSG=Itemized Include List
 SET @SAMESOURCE_MSG=Jobs Share Same Source
 SET @MODES=& FOR %%M IN (DIAGMODE TESTMODE HIDE_BASE_PATH HIDE_FULL_PATH USE_LOCAL_ZIP XCOMPARE USE_SYSLOGS FASTMODE x64 SORT_LIST USE_VSS ITEMIZED_INC SAMESOURCE FORCE_BACKUP NOSCHED UNSCHED UPDATESCHED SCHEDULEONLY) DO IF /I "!@%%~M!"=="TRUE" SET @MODES=!@%%~M_MSG! * !@MODES!
 IF "%@MODES%"=="" SET @MODES=NONE *

 rem -- Key Variable Verification
 SET @SOURCEDEST=
 FOR %%V IN ("%@UNSCHED%" "%@SCHEDULEONLY%") DO IF /I "%%~V"=="TRUE" GOTO :ScheduleJobs
 FOR %%V IN (HASHUTIL THISHASH HASHOPT COMPTYPE COPYMODE) DO CALL :UpperCase @%%V
 FOR %%C IN ("" %@BASE10%) DO FOR %%X IN ("" %@ALPHA11%) DO IF DEFINED @SOURCE%%~C%%~X (
	 FOR %%L IN ("" %@ALPHA11%) DO IF DEFINED @DEST%%~C%%~L SET @SOURCEDEST=PRESENT
 )
 FOR %%V IN (ALL_PARAMS THISHASH HASHOPT COMPMODE COMPTYPE COPYMODE SOURCEDEST INFO MAKE_FILES KEEP_FILES MAKE_TIMED KEEP_TIMED ALPHA11 BASE10) DO IF NOT DEFINED @%%~V (
	 ECHO:
	 ECHO *** WARNING: The @%%~V variable is undefined.
	 ECHO:
	 ECHO  Please ensure that all configuration info is provided correctly
	 ECHO  within the file: "%@ARCHIVE-INFO%"
	 ECHO:
	 ECHO  Alternatively, this information can be entered directly into this script,
	 ECHO  although this is not recommended because it undermines portability.
	 ECHO %@DIVIDER*%
	 ECHO:
	 CALL :SaveJobHistory ABORTED - UNDEFINED VARIABLE
	 GOTO :HelpMessage
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Validate Values Used for Keeping Zip and Backup History (0 = Skip)
 rem === Updated On: 03 Feb 2020 / 23 Jul 2019
 rem ==========================================================================
:ValidateHistory
 FOR %%V IN (%@CYCLE%) DO (
	 FOR %%Y IN ("" "FALSE") DO IF /I "!@MAKE_%%V!"=="%%~Y" SET @KEEP_%%V=0
	 SET /A @CHECK_%%V=@KEEP_%%V

	 IF "!@CHECK_%%V!"=="0" (
		 SET @SKIP_%%V=
		 SET @MAKE_%%V=FALSE
	 ) ELSE (
		 SET @SKIP_%%V=SKIP=!@KEEP_%%V!
		 SET @MAKE_%%V=TRUE
	 )
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Select Valid Source and Destination for each Job from the Job Config
 rem === Updated On: 25 Mar 2018 / 01 Jan 2018
 rem ==========================================================================
:GetValidJobFolders
 ECHO === Obtaining Source/Destination Info from "%@ARCHIVE-INFO%" ===
 ECHO:
 FOR %%C IN ("" %@BASE10%) DO (
	 SET @JOBID%%~C=SOURCE%%~C!@SPACES!
	 FOR %%X IN ("" %@ALPHA11%) DO (
		 IF DEFINED @SOURCE%%~C%%~X IF NOT DEFINED #SOURCE%%~C (
			 SET @JOBNUM=!@JOBID%%~C!
			 SET @SOURCE%%~C=!@SOURCE%%~C%%~X!
			 IF EXIST "!@SOURCE%%~C%%~X!" (
				 CALL :FixDirectoryPath @SOURCE%%~C%%~X
				 SET #SOURCE%%~C=TRUE
				 SET @SOURCE%%~C=!@SOURCE%%~C%%~X!
				 SET /A @LIVEJOBS+=1
			 )
		 )

		 IF DEFINED @DEST%%~C%%~X IF NOT DEFINED #DEST%%~C (
			 SET @JOBNUM=!@JOBID%%~C!
			 CALL :VerifyDestination "!@DEST%%~C%%~X!"
			 IF "!@DESTEXISTS!"=="TRUE" (
				 CALL :FixDirectoryPath @DEST%%~C%%~X
				 SET @DEST%%~C=!@DEST%%~C%%~X!
				 SET #DEST%%~C=TRUE
			 )
		 )
	 )
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Header and Allow User To Abort Operation
 rem === Updated On: 10 May 2024 / 14 Jul 2020 / 28 Jul 2019
 rem ==========================================================================
:ShowHeader
 TITLE %@JOBNAME% [%@INFO%]
 FOR %%V IN ("%@LOGPATH%" "%TEMP%") DO IF NOT EXIST "%%~V" MD "%%~V" >NUL

 ECHO === Prepare to Execute the Following Backup Job ===

 ( rem -- Write to Log
	 ECHO:
	 ECHO %@DIVIDER*%
	 ECHO *** %COMPUTERNAME% - [%DATE% at %TIME%] - %@VER%
	 ECHO *** Job Name .......... %@JOBNAME% [%@INFO%]
	 ECHO *** Job Schedule ...... %@JOBFREQ% at %@JOBTIME%  %@JOBDATE%
	 ECHO *** Job User .......... %@JOBUSER%
	 ECHO *** File Comparison ... %@COMPMODE%
	 ECHO *** Backup Utilities .. %@COPYUTIL% and %@ZIPUTIL%
	 ECHO *** Global Modes ...... %@MODES:~0,-2%
	 IF DEFINED @JOBDELAY ECHO *** Initial Delay ..... %@JOBDELAY% Seconds
	 ECHO %@DIVIDER*%
	 ECHO:
	 FOR %%C IN ("" %@BASE10%) DO IF DEFINED @SOURCE%%~C (
		 IF DEFINED @DEST%%~C (
			 SET /A @JOBCOUNT+=1
			 CALL :FixDirectoryPath @SOURCE%%~C
			 CALL :FixDirectoryPath @DEST%%~C
			 CALL :CreateExceptionLists %%~C
			 CALL :DisplayCopy @SOURCE%%~C @DEST%%~C
		 )
	 )
	 ECHO EXPECTED JOBS .. !@LIVEJOBS! OF !@JOBCOUNT! ARE VIABLE
	 ECHO:
	 ECHO  Make Folder Backup: %@MAKE_FILES% 	[Retain %@KEEP_FILES% Copies]
	 ECHO  Make Timed Archive: %@MAKE_TIMED% 	[Retain %@KEEP_TIMED% Archives]
	 ECHO  Make DAILY Archive: %@MAKE_DAILY% 	[Retain %@KEEP_DAILY% Archives]
	 ECHO   " MONTHLY Archive: %@MAKE_MONTHLY% 	[Retain %@KEEP_MONTHLY% Archives]
	 ECHO   "  YEARLY Archive: %@MAKE_YEARLY% 	[Retain %@KEEP_YEARLY% Archives]
	 ECHO %@DIVIDER-%
	 ECHO:
 ) >"%@SUMMARY%" 2>&1

 TYPE "%@SUMMARY%"
 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 CHOICE /C YNQEX /T 20 /D Y /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :ExitBatch
 )
 COPY "%@SUMMARY%" "%@LOGFILE%" /Y
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 12 Apr 2024 / 22 Jan 2022 / 09 Mar 2019
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
 IF /I "%@UPDATESCHED%"=="TRUE" (!@SET_SCHED!) ELSE (CALL :CheckSched "%~f0" " %@JOBVRFY%$")
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
 rem === Optional Waiting Period Before Starting Archival Job
 rem === Updated On: 12 Jan 2015 / 20 Nov 2012
 rem ==========================================================================
:OptionalDelay
 rem -- Optional waiting period before starting archival job
 IF DEFINED @JOBDELAY (
	 CALL :EchoALL *** !DATE! at !TIME! -- Pausing Script for %@JOBDELAY% Seconds ***
	 TIMEOUT %@JOBDELAY% >NUL
	 CALL :EchoALL *** !DATE! at !TIME! -- Resuming Script Operation ***
	 ECHO:
 ) >>"%@LOGFILE%" 2>&1


 rem ==========================================================================
 rem === Cycle Through All Possible Source/Destination Combinations
 rem === Updated On: 26 Jan 2022 / 29 Jul 2019
 rem ==========================================================================
:EnumerateAll
 CALL :EchoSOME ##### ARCHIVE JOB: %@INFO% #####

 FOR %%C IN ("" %@BASE10%) DO IF DEFINED @SOURCE%%~C (
	 SET @SUCCESS=
	 SET @JOBNUM=!@JOBID%%~C!
	 IF DEFINED @DEST%%~C (
		 SET @SOURCENAME=!@SOURCE%%~C:\\=!
		 SET @SOURCENAME=!@SOURCENAME::\=_!
		 SET @SOURCENAME=!@SOURCENAME::=_!
		 SET @SOURCENAME=!@SOURCENAME:\=_!
		 SET @SOURCENAME=!@SOURCENAME:__=_!& IF "!@SOURCENAME:~-1!"=="_" SET @SOURCENAME=!@SOURCENAME:~0,-1!
		 SET @BACKUP_ROOT=!@DEST%%~C!\%@JOBFOLDER%& IF /I "%@SIMPLEDEST%"=="TRUE" SET @BACKUP_ROOT=!@DEST%%~C!
		 SET @FILES_FORMAT=!@BACKUP_ROOT!\!@SOURCENAME!.????-??-?? [??.??.??]
		 SET @FILES_BACKUP=!@BACKUP_ROOT!\!@SOURCENAME!.%@TODAY_EXP% [%@NOW_EXP%]
		 SET @TIMED_FORMAT=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.????????-??????.ZIP&  SET @TIMED_FORMAT=!@TIMED_FORMAT:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!
		 SET @TIMED_ARCHIVE=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.%@TODAY%-%@NOW%.ZIP& SET @TIMED_ARCHIVE=!@TIMED_ARCHIVE:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!
		 SET @DAILY_FORMAT=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.????-??-??.ZIP&       SET @DAILY_FORMAT=!@DAILY_FORMAT:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!
		 SET @DAILY_ARCHIVE=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.%@TODAY_EXP%.ZIP&    SET @DAILY_ARCHIVE=!@DAILY_ARCHIVE:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!
		 SET @MONTHLY_FORMAT=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.????-??.ZIP&        SET @MONTHLY_FORMAT=!@MONTHLY_FORMAT:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!
		 SET @MONTHLY_ARCHIVE=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.%@YYYY%-%@MM%.ZIP& SET @MONTHLY_ARCHIVE=!@MONTHLY_ARCHIVE:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!
		 SET @YEARLY_FORMAT=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.????.ZIP&            SET @YEARLY_FORMAT=!@YEARLY_FORMAT:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!
		 SET @YEARLY_ARCHIVE=!@BACKUP_ROOT!\%COMPUTERNAME%_!@SOURCENAME!.%@YYYY%.ZIP&        SET @YEARLY_ARCHIVE=!@YEARLY_ARCHIVE:%COMPUTERNAME%_%COMPUTERNAME%_=%COMPUTERNAME%_!

		 CALL :CreateExceptionLists %%~C
		 CALL :EchoSOME2 CURRENT SOURCE FOLDER: "!@SOURCE%%~C!"
		 CALL :EchoSOME0 CURRENT  DEST  FOLDER: "!@BACKUP_ROOT!"
		 CALL :EchoSOME0 CURRENT  FILE SPEC[S]:  !@CURRENT_IN!

		 ( rem -- Write to Log
			 IF NOT EXIST "!@SOURCE%%~C!" (
				 CALL :DisplayCopy @SOURCE%%~C @BACKUP_ROOT SHORT
				 CALL :ThisTime CALL :EchoAll  §§§ *** COULD NOT ACCESS THE SOURCE FOLDER ***
				 ECHO:
			 ) ELSE (
				 CALL :DisplayCopy @SOURCE%%~C @BACKUP_ROOT SHORT
				 CALL :VerifyDestination "!@DEST%%~C!"
				 IF "!@DESTEXISTS!"=="TRUE" (
					 SET @CONFIG_OLD=!@CONFIG_NEW!
					 SET @CONFIG_NEW=!@CURRENT_VS!/!@CURRENT_SD!/!@CURRENT_SF!/!@CURRENT_IN!/!@CURRENT_EX!/!@CURRENT_FM!

					 rem -- Check for differences in ZIP archive configuration requirement
					 IF /I "!@SAMESOURCE!/!@CONFIG_NEW!"=="TRUE/!@CONFIG_OLD!" (
						 IF DEFINED @FIRST_ZIP SET @CHECK-SOURCE%%~C=TRUE
					 ) ELSE (
						 IF EXIST "!@LOCAL_ZIP!" DEL "!@LOCAL_ZIP!"
						 FOR %%Z IN (FIRST LOCAL) DO SET @%%~Z_ZIP=
					 )
					 IF /I "!@CHECK-SOURCE%%~C!"=="TRUE" (
						 CALL :EchoAll %@DIVIDER-:~0,75%
						 CALL :ThisTime CALL :EchoAll  §§§ SKIPPING Source Folder Evaluation...
					 ) ELSE (
						 CALL :CompareFolders "!@SOURCE%%~C!" "%%~C"
						 SET @CHECK-SOURCE%%~C=TRUE
					 )
					 CALL :MakeBackups   "!@SOURCE%%~C!" "!@FILES_BACKUP!" "%%~C"
					 CALL :PruneArchives "!@BACKUP_ROOT!"
				 )
			 )

			 ECHO %@DIVIDER#%
			 ECHO:
		 ) >>"%@LOGFILE%" 2>&1
	 )
 )
 IF EXIST "!@LOCAL_ZIP!" DEL "!@LOCAL_ZIP!"
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Display Execution Footer
 rem === Updated On: 14 Jul 2020 / 13 May 2020 / 19 Jan 2015
 rem ==========================================================================
:ShowFooter
 CALL :SaveJobHistory

 ( rem -- Create Standard and Diagnostic Footer
	 NOW \n\*%~n0 Job Completed - [\v] - %@VER%\n\*\n
	 IF /I "!@DIAGMODE!"=="TRUE" (
		 ECHO:
		 ECHO %@DIVIDER*%
		 SET
		 ECHO %@DIVIDER*%
		 ECHO:
	 )
	 ECHO %@DIVIDER~%
	 ECHO  Total Backups Made ........!@TB!
	 ECHO  Total Backups Pruned ......!@TP!
	 ECHO  Total Files Archived ..!@FA!
	 ECHO %@DIVIDER~%
	 ECHO:
 ) >"%@TEMPLOG%" 2>&1

 rem -- Display Execution Logs
 FOR %%O IN (CON "%@SUMMARY%" "%@LOGFILE%") DO TYPE "%@TEMPLOG%" >>%%O 2>&1
 FOR %%O IN ("%@LOGFILE%" "%@SUMMARY%") DO TYPE %%O

 ( rem -- Create Special Summary Log Footer
	 FOR %%V IN (1 2 3 4 5) DO IF "%%~V"=="3" (ECHO ### End of Summary Log) ELSE (ECHO %@DIVIDER#%)
	 ECHO:
	 ECHO:
 ) >>"%@SUMMARY%" 2>&1
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Mail Log File To Appropriate Group
 rem === Updated On: 30 Apr 2015 / 20 Jan 2015
 rem ==========================================================================
:SendLog
 IF /I "%@MAIL%/%@CHANGES%"=="TRUE/TRUE" IF DEFINED @RCPT-TO (
	 ( rem -- Write to Log
		 ECHO Sending Logs to: %@RCPT-TO:-to =%
		 ECHO              on: !DATE! at !TIME!
		 ECHO:
		 BLAT -install %@MAILSERVER% %@MAILSENDER% 2 %@MAILPORT%
		 ECHO %@DIVIDER#%
		 ECHO:
		 ECHO:
	 ) >"%@TEMPLOG%" 2>&1
	 FOR %%O IN (CON "%@LOGFILE%") DO TYPE "%@TEMPLOG%" >>%%O 2>&1

	 ECHO:
	 BLAT "%@SUMMARY%" -f %@MAILSENDER% %@RCPT-TO% -s "%~n0 Job on %COMPUTERNAME%: %@INFO%" -attach "%@LOGFILE%","%@TIMINGS%"
	 CALL :ForwardToSyslog "6" Mailed %~n0 Job Report on %COMPUTERNAME%: %@INFO% -- "%@LOGFILE%" >NUL
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Log Management/Maintenance (Or Copy Them for Debug Purposes)
 rem === Updated On: 16 Mar 2015 / 12 Jan 2015
 rem ==========================================================================
:LogMaint
 ECHO PERFORMING FINAL LOG MAINTENANCE...
 COPY "%@LOGFILE%" "%@TEMPLOG%" /Y
 COPY "%@SUMMARY%" + "%@TEMPLOG%" "%@LOGFILE%" /Y

 IF /I "%DEBUG%"=="COPY" FOR %%L IN (%@LOGLIST% %@CLEANUP%) DO IF EXIST %%L COPY %%L "%TEMP%" /Y

 FOR %%L IN (%@LOGLIST%) DO IF EXIST %%L (
	 SET @THISLOG=%%L
	 COPY %%L !@THISLOG:%@FILESTAMP%=TXT! /Y
	 IF %%L=="%@LOGFILE%" (ECHO: & DIR %%L)
 )
 FOR %%L IN (%@CLEANUP%) DO IF EXIST %%L DEL %%L >NUL
 ECHO %@DIVIDER~%
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 03 Oct 2019 / 28 Feb 2019
 rem ==========================================================================
:ExitBatch
 ECHO:
 ECHO To See All Jobs, type: %~n0 -v
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Echo Output to Multiple Destinations
 rem === Updated On: 20 Oct 2017 / 16 Mar 2015
 rem ==========================================================================
:EchoAll
:EchoAll0
:EchoAll2
 rem %* = Message to Display

 SET @OUT=%*
 SET @OUT=!@OUT: = !
 SET @CHK=%~1
 IF DEFINED @CHK SET @CHK=!@CHK:"=!
 FOR %%A IN (ALL ALL2 ALL2) DO IF "%~0"==":Echo%%A" ECHO:
 IF "!@CHK!"=="" (ECHO:) ELSE (ECHO !@OUT!)

:EchoSome
:EchoSome0
:EchoSome2
 SET @OUT=%*
 SET @OUT=!@OUT: = !
 IF /I "%@DIAGMODE%"=="TRUE" SET @OUT=!TIME: =0!: %@OUT%
 FOR %%B IN (CON "%@SUMMARY%") DO (
	 FOR %%A IN (SOME SOME2 SOME2 ALL ALL2 ALL2) DO IF "%~0"==":Echo%%A" ECHO: >>%%B
	 IF "%~1"=="" (ECHO: >>%%B) ELSE (ECHO !@OUT! >>%%B)
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine current time and insert into status messages
 rem === Updated On: 01 Jan 2018 / 12 Jan 2015
 rem ==========================================================================
:ThisTime
 rem %* = Command to Execute [using token substitution to display current time]

 SET @RUN=%*
 SET @RUN=!@RUN:ECHO  =ECHO  !
 SET @CTIME=[!TIME:~0,5!]
 SET @CTIME=!@CTIME: =0!
 SET @THISJOB=!@CTIME: =0!  ID#=!@JOBNUM:~0,7!:
 %@RUN:§§§=!@THISJOB!%
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine if Comparison File Should be Sorted
 rem === Updated On: 07 Mar 2017 / 23 Oct 2014
 rem ==========================================================================
:SortFile
 rem %1 = Source File
 rem %2 = Output File
 rem %3 = Sort Position (Default = 49)

 IF "%~3"=="" (SET @POS=49) ELSE (SET @POS=%~3)

 IF EXIST "%~1" (
	 IF DEFINED @SORT_LIST (
		 CALL :ThisTime ECHO  §§§ Sorting the Current Comparison File...
		 SORT /+%@POS% "%~1" /O "%~2"
	 ) ELSE (
		 CALL :ThisTime ECHO  §§§ Copying Comparison File Without Sorting...
		 COPY "%~1" "%~2" /Y /V
	 )
 ) ELSE (
	 CALL :ThisTime ECHO  §§§ No File Found for Sorting...
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Display All The Jobs In The Copy Stream
 rem === Updated On: 28 Jul 2019 / 12 Oct 2014
 rem ==========================================================================
:DisplayCopy
 rem %1 = Source Location variable for ROBOCOPY/XCOPY Command
 rem %2 = Destination Location variable for ROBOCOPY/XCOPY Command
 rem %3 = Boolean value to determine format of output (LONG or SHORT)

 CALL SET @CURRENT_SOURCE=%%%~1%%
 CALL SET @CURRENT_DEST=%%%~2%%
 CALL :GetFreeDiskSpace "%@CURRENT_SOURCE%" @FREESPACE_S
 CALL :GetFreeDiskSpace "%@CURRENT_DEST%"   @FREESPACE_D TRUE

 IF "%~3"=="" ( rem -- Default to Long View
	 ECHO SOURCE ......... %@CURRENT_SOURCE% [!@FREESPACE_S!]
	 ECHO DESTINATION .... %@CURRENT_DEST% [!@FREESPACE_D!]
	 ECHO FILE SPEC[S] ... %@CURRENT_IN%
	 IF /I "%@CURRENT_FM%"=="TRUE" ECHO FASTMODE INFO .. Fastmode is enabled for this job...
	 IF DEFINED @EXEMPT-DIRS       ECHO IGNORE DIRS .... !@EXEMPT-DIRS!
	 IF DEFINED @EXEMPT-FILES      ECHO IGNORE FILES ... !@EXEMPT-FILES!
 ) ELSE (
	 ECHO:
	 ECHO **** !DATE! at !TIME: =0! ****
	 ECHO S: %@CURRENT_SOURCE% [!@FREESPACE_S!]
	 ECHO D: %@CURRENT_DEST% [!@FREESPACE_D!]
	 ECHO F: %@CURRENT_IN%
	 IF /I "%@CURRENT_FM%"=="TRUE"              ECHO f: Fastmode is enabled for this job...
	 IF NOT "!@EXEMPT-DIRS!!@EXEMPT-FILES!"=="" ECHO -: !@EXEMPT-DIRS! !@EXEMPT-FILES!
 )
 ECHO:
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine If Data Contents Have Changed Since Last Backup
 rem === Updated On: 30 Aug 2024 / 21 May 2024 / 23 Jun 2019
 rem ==========================================================================
:CompareFolders
 rem %1 = Current Source Location for Data to be Backed Up
 rem %2 = Index # for Source/Destination Jobs

 SET @C_LOG=!@CURRENT_LOG!%~2
 SET @T_LOG=!@TIMED_LOG!%~2
 SET @D_LOG=!@DAILY_LOG!%~2
 SET @M_LOG=!@MONTHLY_LOG!%~2
 SET @Y_LOG=!@YEARLY_LOG!%~2
 SET @TIMED_NEEDED=TRUE
 SET @DAILY_NEEDED=TRUE
 SET @MONTHLY_NEEDED=TRUE
 SET @YEARLY_NEEDED=TRUE

 rem -- Check for Existence of Comparison Files
 IF NOT EXIST "%@BACKUP_ROOT%" MD "%@BACKUP_ROOT%" >NUL
 FOR %%F IN ("!@T_LOG!" "!@D_LOG!" "!@M_LOG!" "!@Y_LOG!") DO TYPE NUL >>"%%~F"
 FOR %%F IN ("" ".TEMP" ".SORT") DO TYPE NUL >"!@C_LOG!%%~F"

 CALL :EchoAll %@DIVIDER-:~0,75%
 CALL :ThisTime CALL :EchoAll  §§§ Evaluating Source Folder for changes...
 CALL :ThisTime ECHO  §§§ Checking "%~1"...
 PUSHD %TEMP%

 rem -- Generate Hash Database of All Files based on Selected Comparison Method
 CALL :ThisTime ECHO  §§§ Adding %@THISHASH% File Hashes to Comparison File...

 IF /I "%@XCOMPARE%"=="TRUE" ( rem -- Use BrainWave FileHash
	 SET @SORT_LIST=TRUE
	 SET @FH_OPT=-s
	 IF /I "%@HIDE_BASE_PATH%"=="TRUE" SET @FH_OPT=-f -s
	 IF /I "%@HIDE_FULL_PATH%"=="TRUE" SET @FH_OPT=-i
	 IF /I "%@SHOW_FILE_DATE%"=="TRUE" SET @FH_OPT=!@FH_OPT! -#

	 IF DEFINED @CURRENT_EX (SET @FH_EXC=-e "%@NO_COPY%") ELSE (SET @FH_EXC=)
	 IF DEFINED @CURRENT_VS (
		 %@VSS% %@VSS_VERBOSITY% "%~1" !@DRV! %@FILEHASH% %@HASHOPT% -m "%@MAX_SIZE%" !@FH_OPT! -z -o "!@C_LOG!.SORT" !@FH_EXC! -r -d "!@DRV!" %@CURRENT_IN%
	 ) ELSE (
		 %@FILEHASH% %@HASHOPT% -m "%@MAX_SIZE%" !@FH_OPT! -z -o "!@C_LOG!.SORT" !@FH_EXC! -r -d "%~1" %@CURRENT_IN%
	 )

 ) ELSE ( rem -- Get Directory Listing and Basic DIR Comparison

	 IF /I "%@CURRENT_FM%"=="TRUE" (
		 CALL :ThisTime ECHO  §§§ FastMode DIR Comparison Enabled...

		 ( IF DEFINED @CURRENT_EX (
				 DIR /OGN /S /A-D "%~1\%@CURRENT_IN%" | FIND "/" | FINDSTR /V /I /L /G:"%@NO_COPY%"
			 ) ELSE (
				 DIR /OGN /S /A-D "%~1\%@CURRENT_IN%" | FIND "/"
		 ) ) >"!@C_LOG!.SORT"

		 SET @SORTLEN=999

	 ) ELSE (

		 CALL :ThisTime ECHO  §§§ Obtaining Directory Listing for File Comparison Purposes...

		 ( IF DEFINED @CURRENT_EX (
				 DIR /OGN /S /A-D /B "%~1\%@CURRENT_IN%" | FINDSTR /V /I /L /G:"%@NO_COPY%"
			 ) ELSE (
				 DIR /OGN /S /A-D /B "%~1\%@CURRENT_IN%"
		 ) ) >"!@C_LOG!.TEMP"

		 CALL :ThisTime ECHO  §§§ Adding File Size/Date Information to Comparison File...

		 FOR /F "USEBACKQ TOKENS=*" %%F IN ("!@C_LOG!.TEMP") DO (
			 SET @FILENAME=%%~fF
			 IF /I "%@HIDE_BASE_PATH%"=="TRUE" SET @FILENAME=!@FILENAME:%~1\=!
			 IF /I "%@HIDE_FULL_PATH%"=="TRUE" SET @FILENAME=%%~nxF
			 CALL :PadLeft @FS "%%~zF" " " 12
			 CALL :PadLeft @FT "%%~tF      " " " 32
			 ECHO {!@FS!} !@FT! !@FILENAME!
		 ) >>"!@C_LOG!.SORT"
	 )
 )

 rem -- Sort/Copy Intermediary Logfile
 CALL :SortFile "!@C_LOG!.SORT" "!@C_LOG!" !@SORTLEN!

 rem -- Evaluate Comparison Files for Data Changes
 IF /I "%@MAKE_TIMED%"=="TRUE"   CALL :CompareOneEntry "EVALUATING TIMED BACKUPS"   "!@T_LOG!" @TIMED_NEEDED
 IF /I "%@MAKE_DAILY%"=="TRUE"   CALL :CompareOneEntry "EVALUATING DAILY BACKUPS"   "!@D_LOG!" @DAILY_NEEDED
 IF /I "%@MAKE_MONTHLY%"=="TRUE" CALL :CompareOneEntry "EVALUATING MONTHLY BACKUPS" "!@M_LOG!" @MONTHLY_NEEDED
 IF /I "%@MAKE_YEARLY%"=="TRUE"  CALL :CompareOneEntry "EVALUATING YEARLY BACKUPS"  "!@Y_LOG!" @YEARLY_NEEDED

 IF /I "%@TIMED_NEEDED%/%@DAILY_NEEDED%/%@MONTHLY_NEEDED%/%@YEARLY_NEEDED%"=="FALSE/FALSE/FALSE/FALSE" (
	 ECHO:
	 CALL :ThisTime CALL :EchoAll  §§§ No Changes Since Last Scan -- No Backup Needed
 )

 rem -- Cleanup Temp Logs (Or Copy Them for Debug Purposes)
 FOR %%F IN ("" TEMP TEMP2 SORT HASH) DO IF EXIST "!@C_LOG!.%%~F" (
	 IF /I "%DEBUG%"=="COPY" COPY "!@C_LOG!.%%~F" "%TEMP%" /Y /V
	 IF NOT "%%~F"=="" DEL "!@C_LOG!.%%~F"
 )
 POPD
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Compare One Backup Entry (Timed, Daily, Monthly, Yearly)
 rem === Updated On: 27 Jun 2019 / 12 Jan 2015
 rem ==========================================================================
:CompareOneEntry
 rem %1 = Section Message to Display
 rem %2 = File/Folder Comparison File
 rem %3 = Variable to Store Result

 ECHO:
 CALL :ThisTime ECHO  §§§ ==== %~1 ====
 FOR %%d IN ("!@C_LOG!" "%~2") DO DIR /A "%%~d" | FIND /I "%%~nd"
 ECHO:
 %@FC% "!@C_LOG!" "%~2"
 IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 SET %~3=FALSE
 IF DEFINED @FORCE_BACKUP SET %~3=TRUE
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Create Folder/Zip Archives if Contents Have Changed
 rem === Updated On: 28 Jul 2024 / 26 Jan 2022 / 29 Jun 2019
 rem ==========================================================================
:MakeBackups
 rem %1 = Current Source Location for Data to be Archived/Zipped
 rem %2 = Current Destination Location for Data to Archived/Zipped
 rem %3 = Index # for Source/Destination Jobs

 rem -- Generate Random Number
 SET @RND=%RANDOM%& FOR /F "TOKENS=*" %%R IN ('DATEINFO -R 99999 -Q 2^>NUL') DO SET @RND=%%R

 rem -- Don't Reset Zip Variables if @SAMESOURCE is TRUE
 IF /I "%@SAMESOURCE%"=="TRUE" (
	 IF NOT DEFINED @FIRST_ZIP (
		 SET @FIRST_ZIP=
		 SET @LOCAL_ZIP=%TEMP%\%@JOBFOLDER%.!@RND!.ZIP
	 )
 ) ELSE (
	 SET @FIRST_ZIP=
	 SET @LOCAL_ZIP=%TEMP%\%@JOBFOLDER%.!@RND!.ZIP
 )
 SET @SUCCESS=TRUE
 SET @BACKUPS_TOTAL=0
 SET @BACKUPS_COUNT=0
 SET @C_LOG=!@CURRENT_LOG!%~3
 SET @T_LOG=!@TIMED_LOG!%~3

 IF /I "%@MAKE_FILES%"=="TRUE" SET /A @BACKUPS_TOTAL+=1
 IF /I "%@TIMED_NEEDED%/%@MAKE_FILES%"=="TRUE/TRUE" (
	 SET /A @BACKUPS_COUNT+=1
	 SET /A @TOTAL_BACKUPS+=1
	 SET @CHANGES=TRUE
	 ECHO:
	 CALL :ThisTime CALL :EchoAll  §§§ Creating Time-stamped Backup Folder...

	 XCOPY "%~1" "%~2" %@XCOPY_PARAMS% /T
	 IF /I "%@COPYUTIL%"=="ROBOCOPY" (
		 IF DEFINED @CURRENT_VS (
			 %@VSS% %@VSS_VERBOSITY% "%~1" !@DRV! %@ROBOCOPY% !@DRV! "%~2" %@CURRENT_IN% %@THREADS% %@RETRIES% /S /XO /NP /XJ %@SKIP-FILE% %@SKIP-DIR%
		 ) ELSE (
			 %@ROBOCOPY% "%~1" "%~2" %@CURRENT_IN% %@THREADS% %@RETRIES% /S /XO /NP /XJ %@SKIP-FILE% %@SKIP-DIR%
		 )
		 IF ERRORLEVEL 1 SET @SUCCESS=
	 ) ELSE (
		 IF DEFINED @CURRENT_VS (
			 %@VSS% %@VSS_VERBOSITY% "%~1" !@DRV! XCOPY "!@DRV!\%@CURRENT_IN%" "%~2" %@XCOPY_PARAMS%
		 ) ELSE (
			 XCOPY "%~1\%@CURRENT_IN%" "%~2" %@XCOPY_PARAMS%
		 )
		 IF ERRORLEVEL 1 SET @SUCCESS=
	 )

	 FOR /F "TOKENS=*" %%d IN ('DIR /AD /B "%~2\.." ^| FIND "%~nx2"') DO CALL :EchoAll  	 ------ {DIR}  %%d
	 ECHO:
	 CALL :ThisTime ECHO  §§§ Synching Comparison Logs for File Backup...
	 COPY "!@C_LOG!" "!@T_LOG!" /Y

	 rem -- Delete Empty Folders from Backup
	 CALL :ThisTime CALL :EchoAll  §§§ Deleting Empty Folders from Backup...
	 SYNC %@PSPARAMS%
	 DIR /B /AD /S "%~2" 2>NUL | SORT /R >%@TEMP1%
	:DeleteEmpty
	 FOR /F "TOKENS=*" %%r IN ('TYPE %@TEMP1%') DO (
		 ATTRIB -R -S -H "%%~r"
		 RD "%%~r" >NUL 2>NUL
	 )
	 SYNC %@PSPARAMS%
	 DIR /B /AD /S "%~2" 2>NUL | SORT /R >%@TEMP2%
	 %@FC% %@TEMP1% %@TEMP2%
	 IF ERRORLEVEL 1 (
		 COPY %@TEMP2% %@TEMP1% /Y
		 GOTO :DeleteEmpty
	 )
 ) ELSE (
	 ECHO:
	 IF /I "%@TIMED_NEEDED%/%@MAKE_FILES%"=="TRUE/FALSE" (
		 CALL :ThisTime CALL :EchoAll  §§§ SKIPPING Folder Backup...			[via Config File]
	 )
 )

 rem -- Create Zipped Archives, If Necessary/Requested (Timed, Daily, Monthly, Yearly)
 FOR %%A IN (TIMED DAILY MONTHLY YEARLY) DO (
	 CALL SET @WHICHLOG=%%@%%A_LOG%%%~3

	 IF /I "!@MAKE_%%A!"=="TRUE" SET /A @BACKUPS_TOTAL+=1
	 IF /I "!@%%A_NEEDED!/!@MAKE_%%A!"=="TRUE/TRUE" (
		 IF NOT EXIST "!@%%A_ARCHIVE!" (
			 SET /A @BACKUPS_COUNT+=1
			 SET /A @TOTAL_BACKUPS+=1
			 ECHO:
			 CALL :ThisTime ECHO  §§§ Creating %%A Zip Archive of Source Data [Keep the last !@KEEP_%%A! copies only]

			 IF EXIST "!@FIRST_ZIP!" (
				 CALL :ThisTime CALL :EchoAll  §§§ Copying %%A Archive from !@FIRST_ZIP_NAME! Archive...
				 COPY "!@FIRST_ZIP!" "!@%%A_ARCHIVE!" /Y
				 IF ERRORLEVEL 1 SET @SUCCESS=
			 ) ELSE (
				 SET @FIRST_ZIP_NAME=%%A
				 SET @FIRST_ZIP=!@%%A_ARCHIVE!
				 PUSHD "%~1"
				 ECHO:
				 CALL :ThisTime CALL :EchoAll  §§§ Creating %%A Zip Archive...

				 rem -- Adjust for Info-Zip vs 7-Zip AND +/- VSS
				 SET @FILESOURCE=%@CURRENT_IN%
				 IF DEFINED @USE_7z SET @FILESOURCE=

				 rem -- Define VSS and Standard Zip Commands
				 SET @ZIPJOB=%@ZIPCMD% "§§§§" !@FILESOURCE!
				 SET @VSSJOB=%@VSS% %@VSS_VERBOSITY% "%~1" !@DRV! !@ZIPJOB!

				 rem -- Create Zip Locally If @USE_LOCAL_ZIP is TRUE
				 IF /I "%@USE_LOCAL_ZIP%"=="TRUE" (
					 SET @FIRST_ZIP=!@LOCAL_ZIP!
					 IF /I NOT "%@SAMESOURCE%"=="TRUE" IF EXIST "!@LOCAL_ZIP!" DEL "!@LOCAL_ZIP!"
					 CALL :ThisTime CALL :EchoAll  §§§ Creating Local Zip Archive -- "!@LOCAL_ZIP:%TEMP%\=!"

					 IF DEFINED @CURRENT_VS (
						 CALL :ChangeJobName @VSSJOB @LOCAL_ZIP @NEWNAME
						 ECHO  --- !@NEWNAME!
						 ECHO:
						 ECHO:
						 !@NEWNAME!
					 ) ELSE (
						 CALL :ChangeJobName @ZIPJOB @LOCAL_ZIP @NEWNAME
						 ECHO  --- !@NEWNAME!
						 ECHO:
						 ECHO:
						 !@NEWNAME!
					 )
					 CALL :ThisTime CALL :EchoAll  §§§ Copying Local %%A Zip Archive to Remote Destination...
					 COPY "!@LOCAL_ZIP!" "!@%%A_ARCHIVE!" /Y
					 IF ERRORLEVEL 1 SET @SUCCESS=
				 ) ELSE (
					 IF DEFINED @CURRENT_VS (
						 CALL :ChangeJobName @VSSJOB "@%%A_ARCHIVE" @NEWNAME
						 ECHO  --- !@NEWNAME!
						 ECHO:
						 !@NEWNAME!
					 ) ELSE (
						 CALL :ChangeJobName @ZIPJOB "@%%A_ARCHIVE" @NEWNAME
						 ECHO  --- !@NEWNAME!
						 ECHO:
						 !@NEWNAME!
					 )
					 IF ERRORLEVEL 1 SET @SUCCESS=
				 )
				 POPD
			 )
			 ECHO:
			 FOR /F "TOKENS=3*" %%m IN ('DIR /A "!@%%A_ARCHIVE!" ^| FIND /I ".ZIP"') DO CALL :EchoAll  	 ------ %%n
			 ECHO %@DIVIDER-%
			 ECHO:
			 CALL :ThisTime ECHO  §§§ Synching Comparison Logs for %%A Zip Archive...
			 COPY "!@C_LOG!" "!@WHICHLOG!" /Y
		 ) ELSE (
			 ECHO:
			 IF /I "!@%%A_NEEDED!/!@MAKE_%%A!"=="TRUE/FALSE" (
				 CALL :ThisTime CALL :EchoAll  §§§ SKIPPING %%A Zip Archive...    		[via Config File]
			 ) ELSE (
				 CALL :ThisTime CALL :EchoAll  §§§ SKIPPING %%A Zip Archive...    		[already exists]
			 )
		 )
	 )
	 %@PAUSE_IF_DEBUG%
 )
 CALL :EchoAll %@DIVIDER-:~0,75%
 CALL :ThisTime CALL :EchoAll  §§§ BACKUP JOBS COMPLETED: !@BACKUPS_COUNT! OF !@BACKUPS_TOTAL!
 CALL :EchoAll %@DIVIDER-:~0,75%
 ECHO:
 IF /I NOT "%@SAMESOURCE%"=="TRUE" IF EXIST "!@LOCAL_ZIP!" DEL "!@LOCAL_ZIP!"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Delete Old Folder OR Zip Archives from Main Folder
 rem === Updated On: 10 Apr 2014 / 13 Jan 2014
 rem ==========================================================================
:PruneArchives
 rem %1 = Current Location for Pruning of Backups

 ECHO Pruning Old Folder Backups	[Keep the last %@KEEP_FILES% copies only]
 FOR /F "%@SKIP_FILES% TOKENS=*" %%v IN ('DIR "%@FILES_FORMAT%" /AD /O-N /B 2^>NUL') DO (
	 CALL :ThisTime CALL :EchoAll  §§§ Deleting "%%~v" from Main Folder
	 RD /S /Q "%~1\%%~v"
	 SET /A @TOTAL_PRUNED+=1
 )
 FOR %%v IN (TIMED DAILY MONTHLY YEARLY) DO CALL :PruneOneGroup "%~1" "%%v"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Determine Free Disk Space
 rem === Updated On: 28 Oct 2013 / 13 Oct 2013
 rem ==========================================================================
:GetFreeDiskSpace
 rem %1 = Disk Path to Evaluate
 rem %2 = Variable to Set with Free Space Info
 rem %3 = If Parameter Exists, Create Desired Folder

 IF /I "%~3"=="TRUE" MD "%~1" >NUL 2>&1
 SET @ACCESSIBLE=& IF NOT EXIST "%~1" SET @ACCESSIBLE=*** Path Not Found ***
 SET @BYTES_FREE=0

 IF NOT DEFINED @ACCESSIBLE (
	 FOR /F "TOKENS=2 DELIMS=)" %%f IN ('DIR /A "%~1" ^| FIND /I "bytes free"') DO SET @BYTES_FREE=%%f
	 CALL :ConvertFreeSpace "!@BYTES_FREE!"
	 IF "%~2"=="" (SET @FREESPACE=!@FREEDISK!) ELSE (SET %~2=!@FREEDISK!)
 ) ELSE (
	 IF "%~2"=="" (SET @FREESPACE=!@ACCESSIBLE!) ELSE (SET %~2=!@ACCESSIBLE!)
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Convert Large Number to KB, MB, GB, TB or PB
 rem === Updated On: 23 Feb 2015 / 22 Apr 2012
 rem ==========================================================================
:ConvertFreeSpace
 rem %1 = Number to convert to KB, MB, GB, TB or PB

 SET @BYTES=%~1
 SET @BYTES=%@BYTES:bytes free=%
 SET @COUNT=0& FOR %%z IN (%@BYTES%) DO (SET /A @COUNT+=1& SET @S!@COUNT!=%%z)

 IF %@COUNT% EQU 1 (SET @UNIT=Bytes& SET @VALUE=%@S1%)

 IF %@COUNT% EQU 2 IF %@S1% GEQ 10 (
	 SET @UNIT=KB& SET @VALUE=%@S1%
 ) ELSE (
	 SET @UNIT=Bytes& SET @VALUE=%@S1%,%@S2%
 )

 IF %@COUNT% EQU 3 IF %@S1% GEQ 10 (
	 SET @UNIT=MB& SET /A @VALUE=%@S1%%@S2% / 1049
 ) ELSE (
	 SET @UNIT=KB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1024
 )

 IF %@COUNT% EQU 4 IF %@S1% GEQ 10 (
	 SET @UNIT=GB& SET /A @VALUE=%@S1%%@S2% / 1074
 ) ELSE (
	 SET @UNIT=MB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1049
 )

 IF %@COUNT% EQU 5 IF %@S1% GEQ 10 (
	 SET @UNIT=TB& SET /A @VALUE=%@S1%%@S2% / 1098
 ) ELSE (
	 SET @UNIT=GB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1074
 )

 IF %@COUNT% EQU 6 IF %@S1% GEQ 10 (
	 SET @UNIT=PB& SET /A @VALUE=%@S1%%@S2% / 1168
 ) ELSE (
	 SET @UNIT=TB& SET /A @VALUE=%@S1%%@S2%%@S3% / 1098
 )

 SET @FREEDISK=%@VALUE% %@UNIT% free
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Delete One Set of Zip Archives from Main Folder
 rem === Updated On: 20 Jun 2019 / 10 Apr 2014
 rem ==========================================================================
:PruneOneGroup
 rem %1 = Current Location for Pruning of Backups
 rem %2 = Current Type of Zip Archives to Prune

 SET @SKIP_THIS=!@SKIP_%~2!
 ECHO:
 ECHO Pruning Old %~2 Archives	[Keep only the last !@KEEP_%~2! copies]
 FOR /F "%@SKIP_THIS% TOKENS=*" %%p IN ('DIR "!@%~2_FORMAT!" /A /O-N /B 2^>NUL') DO (
	 CALL :ThisTime CALL :EchoAll  §§§ Deleting "%%~p" from Zips Folder
	 DEL "%~1\%%~p"
	 SET /A @TOTAL_PRUNED+=1
 )
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Create Exception List for ROBOCOPY, XCOPY and ZIP/7z commands
 rem === Updated On: 30 Jul 2019 / 21 Jun 2019 / 19 Jan 2015
 rem ==========================================================================
:CreateExceptionLists
 rem %1 = Current Configuration Suffix to Evaluate

 SET @EXEMPT-DIRS=
 SET @EXEMPT-FILES=
 SET @CURRENT_VS=%@USE_VSS%&   IF DEFINED @USE_VSS%~1    SET @CURRENT_VS=!@USE_VSS%~1!
 SET @CURRENT_SD=%@SKIPDIR%&   IF DEFINED @SKIPDIR%~1    SET @CURRENT_SD=!@SKIPDIR%~1!
 SET @CURRENT_SF=%@SKIPFILE%&  IF DEFINED @SKIPFILE%~1   SET @CURRENT_SF=!@SKIPFILE%~1!
 SET @CURRENT_IN=%@FILESPEC%&  IF DEFINED @FILESPEC%~1   SET @CURRENT_IN=!@FILESPEC%~1!
 SET @CURRENT_EX=%@EXEMPTION%& IF DEFINED @EXEMPTION%~1  SET @CURRENT_EX=!@EXEMPTION%~1!
 SET @CURRENT_FM=%@FASTMODE%&  IF DEFINED @FASTMODE%~1  (SET @CURRENT_FM=!@FASTMODE%~1!& IF NOT "%~1"=="" SET @COMPTYPE=CSTM)
 SET @SKIP-DIR=&  IF NOT "%@CURRENT_SD%"=="" SET @SKIP-DIR=/XD %@CURRENT_SD%
 SET @SKIP-FILE=& IF NOT "%@CURRENT_SF%"=="" SET @SKIP-FILE=/XF %@CURRENT_SF%

 CALL :ChangeChars1 @CURRENT_IN ""
 CALL :ChangeChars1 @CURRENT_EX ""

 ( FOR %%e IN (!@CURRENT_EX!) DO (
	 SET @THISONE=%%~e
	 SET @THISONE=!@THISONE:+=!
	 SET @THISONE=!@THISONE:•=!
	 FOR /F %%f IN ('ECHO %%~e ^| FIND "\"') DO SET @EXEMPT-DIRS=%%~f !@EXEMPT-DIRS!
	 FOR /F %%f IN ('ECHO %%~e ^| FIND /V "\"') DO SET @EXEMPT-FILES=%%~f !@EXEMPT-FILES!
	 ECHO !@THISONE!
 ) ) >"%@NO_COPY%"
 SET @XCOPY_PARAMS=/S /C /I /D /F /H /K /Y /EXCLUDE:%@NO_COPY%

 IF DEFINED @EXEMPT-FILES SET @EXEMPT-FILES=!@EXEMPT-FILES:•=*!
 IF DEFINED @EXEMPT-DIRS (
	 SET @EXEMPT-DIRS=!@EXEMPT-DIRS:\•=!
	 SET @EXEMPT-DIRS=!@EXEMPT-DIRS:\=!
	 SET @EXEMPT-DIRS=!@EXEMPT-DIRS:•=!
 )

 IF DEFINED @CURRENT_IN (
	 SET @INCLUDE=-i
	 FOR %%I IN (!@CURRENT_IN!) DO SET @INCLUDE=!@INCLUDE! "*%%~I"
	 CALL :ChangeChars2 @INCLUDE ""
 ) ELSE (
	 SET @INCLUDE=-i *.*
 )

 IF DEFINED @CURRENT_EX (
	 SET @EXCLUDE=-x
	 FOR %%E IN (!@CURRENT_EX!) DO SET @EXCLUDE=!@EXCLUDE! "%%~E"
	 CALL :ChangeChars2 @EXCLUDE ""
 ) ELSE (
	 SET @EXCLUDE=
 )

 CALL :ChangeChars2 @CURRENT_IN ""
 CALL :ChangeChars2 @CURRENT_EX ""

 CALL :MakeFileList1 %@CURRENT_IN% >"%@ZIP_INC%"
 CALL :MakeFileList2 %@CURRENT_EX% >"%@ZIP_EXC%"

 IF DEFINED @USE_7Z (
	 SET @SPF=
	 IF DEFINED @ITEMIZED_INC (
		 SET @SPF=-spf
		 CALL :MakeItemizedList @SOURCE%~1 @ZIP_INC
	 )
	 SET @ZIPCMD=7z a -bb1 -mmt2 -mx9 -w !@SPF! -ir@%@ZIP_INC% -xr@%@ZIP_EXC%
 ) ELSE (
	 SET @ZIPCMD=ZIP !@EXCLUDE! -9 -v -dgds 1m -T -S -R -dt -b "%TEMP%"
	 IF DEFINED @CURRENT_VS (
		 ( ECHO @PUSHD "!@DRV!"
 		   ECHO @ECHO !@ZIPCMD! %%*
 		   ECHO @!@ZIPCMD! %%*
		   ECHO @POPD
		 ) >%@RUNTHIS%
		 SET @ZIPCMD=%@RUNTHIS%
	 )
 )

 IF DEFINED @CURRENT_VS SET @VS=+
 %@PRINT_IF_DEBUG%
 GOTO :EOF


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
 rem === SUBROUTINE: Replace Parentheses with Brackets in Variables
 rem === Updated On: 19 Jan 2015
 rem ==========================================================================
:ReplaceParentheses
 rem %1 = Variable Name

 IF NOT DEFINED %1 GOTO :EOF
 SET %~1=!%~1:(=[!
 SET %~1=!%~1:)=]!
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Remove Trailing \ From Supplied Folder Path
 rem === Updated On: 25 Feb 2019 / 19 Jan 2015
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
 rem === SUBROUTINE: Find Free Drive Letter
 rem === Updated On: 20 Jun 2019
 rem ==========================================================================
:FindFreeDrive
 rem %1 = Drive Variable

 PUSHD \\%COMPUTERNAME%\ADMIN$
 IF %ERRORLEVEL% EQU 0 (
	 IF "%~1"=="" (SET @DRV=%CD%) ELSE (SET %~1=%CD%)
 ) ELSE (
	 ECHO *** ERROR SETTING DRIVE ***
	 IF "%~1"=="" (SET @DRV=) ELSE (SET %~1=)
 )
 POPD
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Use SubString to Manage "*" Characters in Inc/Exc Lists
 rem === Updated On: 30 Jul 2019 / 26 Jul 2019
 rem ==========================================================================
:ChangeChars1
:ChangeChars2
 rem %1 = Name of Resulting Variable
 rem %2 = Content to Perform Substring Operation

 IF "%~1"=="" GOTO :EOF

 SET @DATA=%~2& IF "%~2"=="" SET @DATA=!%~1!
 SET @SS_P=+

 IF /I "%~0"==":ChangeChars1" (
	 SET @SS_F=*
	 SET @SS_R=•
 ) ELSE (
	 SET @SS_F=•
	 SET @SS_R=*
 )

 FOR /F "TOKENS=*" %%s IN ('SUBSTRING "!@DATA!" "!@SS_P!" "!@SS_R!" 2^>NUL') DO SET @DATA=%%s
 FOR /F "TOKENS=*" %%s IN ('SUBSTRING "!@DATA!" "!@SS_F!" "!@SS_R!" 2^>NUL') DO SET @DATA=%%s
 SET %~1=!@DATA!
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Change Compression Job Names
 rem === Updated On: 29 Jul 2019
 rem ==========================================================================
:ChangeJobName
 rem %1 = Name of Content Variable
 rem %2 = Name of Substitution Variable
 rem %3 = Name of Resulting Variable

 IF "%~3"=="" GOTO :EOF

 SET @IN=!%~1!
 SET @IN=!@IN:"=¶!
 FOR /F "TOKENS=*" %%s IN ('SUBSTRING "!@IN!" "§§§§" "!%~2!" 2^>NUL') DO SET @OUT=%%s
 SET %~3=!@OUT:¶="!
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Convert a Row of Specs into a File List
 rem === Updated On: 28 Jul 2019 / 21 Jun 2019
 rem ==========================================================================
:MakeFileList1
:MakeFileList2
 rem %* = Row of File/Dir Specs to Convert to a List

 SET @ZZZ=
 IF "%~0"==":MakeFileList1" IF DEFINED @CURRENT_VS SET @ZZZ=!@DRV!

:ListLoop
 IF "%~1"=="" GOTO :EOF
 SET @THISONE=%~1
 SET @THISONE=!@THISONE:•.•=*!
 SET @THISONE=!@THISONE:•.=*.!
 SET @THISONE=!@THISONE:•\=*!
 SET @THISONE=!@THISONE:\•=!
 SET @THISONE=!@THISONE:•=*!

 ECHO !@ZZZ!!@THISONE!
 SHIFT
 %@PAUSE_IF_DEBUG%
 GOTO :ListLoop


 rem ==========================================================================
 rem === SUBROUTINE: Make Expanded Include/Exclude List
 rem === Updated On: 28 Jul 2019
 rem ==========================================================================
:MakeItemizedList
 rem %1 = Current Source Folder Variable
 rem %2 = Variable Name of Source File

 IF "%~2"=="" GOTO :EOF
 IF NOT EXIST "!%~1!" GOTO :EOF

 IF EXIST %@TEMP1% DEL %@TEMP1% >NUL 2>NUL
 FOR /F "TOKENS=*" %%F IN ('TYPE "!%~2!" 2^>NUL') DO (
	 IF DEFINED @CURRENT_VS (
		 FOR /F "TOKENS=*" %%S IN ('SUBSTRING "%%~F" "!@DRV!" "!%~1!\" 2^>NUL') DO SET @ONEDIR=%%~S
	 ) ELSE (
		 SET @ONEDIR=%%~F
	 )

	 DIR /A /S /B "!@ONEDIR!" >>%@TEMP1% 2>NUL
 )

 rem -- Update Original Source File
 ( FOR /F "TOKENS=*" %%F IN ('TYPE %@TEMP1% 2^>NUL') DO (
		 IF DEFINED @CURRENT_VS (
			 FOR /F "TOKENS=*" %%S IN ('SUBSTRING "%%~F" "!%~1!\" "!@DRV!" 2^>NUL') DO ECHO "%%~S"
		 ) ELSE (
			 ECHO "%%~F"
		 )
 )) >"!%~2!"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Verify That Destination Folders Exist
 rem === Updated On: 09 May 2020 / 29 Oct 2014
 rem ==========================================================================
:VerifyDestination
 rem %1 = Destination to Check

 SET @FOLDER=%~1
 SET @LOCATION=
 SET @DESTEXISTS=TRUE

 IF "%@FOLDER:~1,2%"==":\" SET @LOCATION=%@FOLDER:~0,2%
 IF "%@FOLDER:~0,2%"=="\\" FOR /F "TOKENS=1-2 DELIMS=\" %%f IN ('ECHO %@FOLDER%') DO SET @LOCATION=\\%%~f\%%~g

 IF NOT EXIST "!@LOCATION!" (
	 SET @DESTEXISTS=FALSE
	 CALL :ThisTime CALL :EchoAll  §§§ *** COULD NOT ACCESS THE DESTINATION FOLDER: "!@LOCATION!" ***
	 ECHO:
 )
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Change Variable Contents to Uppercase
 rem === Updated On: 07 Mar 2017
 rem ==========================================================================
:UpperCase
 rem %1 = Variable to Impact

 IF NOT "%~1"=="" FOR /F "TOKENS=*" %%v IN ('CHANGECASE -u "!%~1!"') DO SET %~1=%%v
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Validate Hash and Obtain Associated Settings
 rem === Updated On: 06 May 2020
 rem ==========================================================================
:ValidateHash
 rem %1 = Variable of Hash to Verify
 rem %2 = Variable to store Sort Length
 rem %3 = Variable to store Marker (Optional)

 SET @VALID=
 FOR %%H IN (%@HASH_MATRIX%) DO (
	 FOR /F "TOKENS=1-3* DELIMS=:" %%L IN ('ECHO %%~H') DO (
		 FOR %%A IN (%%~L %%~N) DO (
			 IF /I "!%~1!"=="%%~A" (
				 SET @VALID=TRUE
				 SET /A %~2=%%~M + 17
				 IF "%%~N"=="" (
					SET %~1=%%~A
					IF NOT "%~3"=="" SET %~3=?%%~A*
				 ) ELSE (
					SET %~1=%%~N
					IF NOT "%~3"=="" SET %~3=?%%~N*
				 )
				 IF "%%~O"=="+" (SET %~3=*)
			 )
		 )
	 )
 )

 rem -- If No Match Is Found, Retry with Default Hash
 IF NOT DEFINED @VALID (
	 SET @VALID=DEFAULT
	 SET %~1=%@FALLBACK_HASH%
	 CALL :ValidateHash %~1 %~2 %~3
 )
 %@PRINT_IF_DEBUG%
 GOTO :EOF


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
 rem === Updated On: 21 Jan 2020 / 24 Sep 2019
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
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


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
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Update Job Execution Stats
 rem === Updated On: 12 Apr 2024 / 07 Apr 2024 / 27 Apr 2020 / 15 Oct 2019
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 SET @FILES_ARCHIVED=0
 IF /I "%@USE_7z%"=="TRUE" (
	 FOR /F "TOKENS=5" %%A IN ('TYPE "%@LOGFILE%" ^| FIND "Files read from disk: "') DO SET /A @FILES_ARCHIVED+=%%~A
 ) ELSE (
	 FOR /F "TOKENS=1" %%A IN ('TYPE "%@LOGFILE%" ^| FIND /C "  testing: "') DO SET /A @FILES_ARCHIVED+=%%~A
 )

 CALL :GetTime @SCRIPT_END
 CALL :PadLeft @LJ "!@LIVEJOBS!" "0" 2
 CALL :PadLeft @JC "!@JOBCOUNT!" "0" 2
 CALL :PadLeft @TP "!@TOTAL_PRUNED!" "." 2
 CALL :PadLeft @TB "!@TOTAL_BACKUPS!" "." 2
 CALL :PadLeft @FA "!@FILES_ARCHIVED!" "." 6

 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 IF "%~1"=="" IF "!@JOBCOUNT!"=="0" SET @SPECIAL=!@SPECIAL! // ABORTED - SOURCE FOLDERS NOT FOUND
 SET @JOBHISTORY=%@INFO% // JOBS:%@LJ%/%@JC% [MADE.%@TB% PRUNED.%@TP% ZIPPED.%@FA%] // DURATION: %@ELAPSED% // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %@VS%%@COMPTYPE%-%@THISHASH%-%@COPYUTIL%-%@ZIPUTIL% // %~n0 %@VERSION%%@x64_MODE%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('TYPE "%@TIMINGS%" ^| FIND /C "/"') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY "%@TIMINGS%" "!@OLDTIME!" /V /Y >CON
	 TAIL -%@MINROWS% "!@OLDTIME!" >"%@TIMINGS%"
	 ECHO:
	 CALL :ForwardToSyslog "5" %@INFO%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>"%@LOGFILE%" 2>>"%@ERRORS%"

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@RUNMODE!!@TRUNCATED! >>"%@TIMINGS%" 2>>"%@ERRORS%"
 %@VERBOSE_ON%
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Forward Output to Available Syslog Server(s) as LOCAL3
 rem === Updated On: 25 Sep 2024 / 05 Jul 2019 / 07 Mar 2019
 rem ==========================================================================
:ForwardToSyslog
 rem %1 = Syslog Severity Level (RFC 3164)
 rem %* = Message to Send to Display and Send to Syslog Server

 SET @S_MSG=%*& IF "%~2"=="" SET @S_MSG=%1 - This is a Syslog Test Message from %@VER%
 SET @SEV=6
 FOR %%a IN (0 EMERGENCY) DO IF /I "%~1"=="%%~a" SET @SEV=0
 FOR %%a IN (1 ALERT) DO IF /I "%~1"=="%%~a" SET @SEV=1
 FOR %%a IN (2 CRITICAL) DO IF /I "%~1"=="%%~a" SET @SEV=2
 FOR %%a IN (3 ERROR) DO IF /I "%~1"=="%%~a" SET @SEV=3
 FOR %%a IN (4 WARNING) DO IF /I "%~1"=="%%~a" SET @SEV=4
 FOR %%a IN (5 NOTICE) DO IF /I "%~1"=="%%~a" SET @SEV=5
 FOR %%a IN (6 INFORMATION) DO IF /I "%~1"=="%%~a" SET @SEV=6
 FOR %%a IN (7 DEBUG) DO IF /I "%~1"=="%%~a" SET @SEV=7

 %@VERBOSE_OFF%
 CALL :Prepare4Syslog %@S_MSG%

 ECHO !@S_MSG!
 IF DEFINED @SYSLOG_UTIL (
	 IF /I "%@USE_SYSLOGS%"=="TRUE" (
		 FOR %%s IN ("" 0 1 2 3 4) DO IF DEFINED @SYSLOG%%~s (
			 SET @S_PORT=514& IF DEFINED @SYSLOG%%s_PORT SET @S_PORT=!@SYSLOG%%~s_PORT!
			 "%@SYSLOGGEN%" -t:!@SYSLOG%%~s! -p:!@S_PORT! -f:19 -s:!@SEV! -tg:"%~n0" -m:"!@S_MSG2!" -q -hn:%@LOCALHOST% | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )

	 IF /I "%@SCRIPT_METRICS%"=="TRUE" (
		 FOR %%P IN (%@MY_SYSLOG_PORTS%) DO (
			 "%@SYSLOGGEN%" -t:127.0.0.1 -p:%%~P -f:19 -s:6 -tg:"%~n0+" -m:"!@S_MSG2!" -q -hn:localhost 2>NUL | FIND /V "%@NO_SYSLOGGEN%"
		 )
	 )
 )
 %@VERBOSE_ON%
 %@PRINT_IF_DEBUG%
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Prepare Messages for SyslogGen Syslog Utility
 rem === Updated On: 23 Jun 2024 / 14 Jan 2020 / 02 Apr 2018
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
 GOTO :EOF


 rem ==========================================================================
 rem === SUBROUTINE: Check if Scheduled Job is Already Running
 rem === Updated On: 03 Sep 2024 / 15 May 2018 / 05 Feb 2015
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
 rem === Updated On: 30 Aug 2024 / 16 Oct 2023 / 24 Dec 2019
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
 rem === SUBROUTINE: Check the Configuration of the Archive Job
 rem === Updated On: 25 Sep 2019 / 30 Jul 2019
 rem ==========================================================================
:CheckJobConfig
 SET @NEXT=%*
 FOR %%A IN (-- - /) DO FOR %%B IN (CHECK C) DO IF DEFINED @NEXT SET @NEXT=!@NEXT:%%A%%B=!
 IF DEFINED @NEXT IF EXIST "%~dp0CheckArchive.BAT" "%~dp0CheckArchive.BAT" !@NEXT!


 rem ==========================================================================
 rem === SUBROUTINE: Display Syntax Help if Required/Requested
 rem === Updated On: 21 May 2024 / 30 Nov 2020
 rem ==========================================================================
:HelpMessage
 ECHO Create Multi-Instance Backups and/or Compressed Archives of Data Folders...
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<name_of_archive_job^>  [OPTIONS]
 ECHO  %~n0  ^<name_of_archive_job^>  [-c]
 ECHO  %~n0  ^<name_of_archive_job^>  [-t^|-t:#]
 ECHO  %~n0  [-h^|-?^|-h2^|-??^|-v]
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO        /S  ... Schedule the Job Only
 ECHO        /U  ... Unschedule the Job Only, Without Executing It First
 ECHO        /N  ... Execute the Job, But Do Not Schedule It
 ECHO        /C  ... Check the Status of a Single Backup/Archive Job
 ECHO        /D  ... Use Standard File Comparison (Using DIR Only)
 ECHO        /E  ... Enable Enhanced File Verification Comparison  ***DEFAULT***
 ECHO        /B  ... Force Timed Backup, Even if No Changes Found
 ECHO      /VSS  ... Enable Volume Shadow Copy Service for this backup (uses virtual disk)
 ECHO      /VS-  ... Disable Volume Shadow Copy Service for this backup
 ECHO    /F:x.y  ... Set custom Filespec   {DEFAULT ... *.*}
 ECHO   /$:hash  ... Specify Valid Encryption Algorithm from below   {DEFAULT ... MD5}
 ECHO       /NH  ... Identical to using /$:NOHASH and more flexible than using DIR mode
 ECHO      /ZIP  ... Use Info-Zip utilities instead of 7-Zip  ***DEFAULT***
 ECHO       /7z  ... Use 7-Zip instead of Info-Zip utilities
 ECHO  /BL, /IL- ... Use Basic Include List for 7-Zip Archives  ***DEFAULT***
 ECHO       /IL  ... Generate Itemized Include List for 7-Zip Archives
 ECHO       /SS  ... Identify All Zip Jobs as Having the Same Source Folders
 ECHO       /SS- ... Identify that Each Zip Job has a Unique Source Folder  ***DEFAULT***
 ECHO       /SF  ... Show Full Path in File Comparison Logs  ***DEFAULT***
 ECHO       /HB  ... Hide Base Path in File Comparison Logs
 ECHO       /HF  ... Hide Full Path in File Comparison Logs
 ECHO       /SD  ... Show File Date/Time Stamp in File Comparison Logs
 ECHO       /FD  ... Fast Comparison Mode disabled
 ECHO       /FE  ... Fast Comparison Mode enabled   ***DEFAULT***
 ECHO       /SO  ... Sorting Enabled (for interoperability between hashing options)  ***DEFAULT***
 ECHO       /NS  ... Sorting Disabled (for slightly faster performance)
 ECHO        /R  ... Use ROBOCOPY instead of XCOPY  ***DEFAULT***
 ECHO        /X  ... Use XCOPY instead of ROBOCOPY
 ECHO        /O  ... Forward to Syslog Servers, If Available  ***DEFAULT***
 ECHO        /Q  ... Do NOT Forward to Syslog Servers
 ECHO        /T  ... Truncate Job History Logfile {or /T:# where # is from 1-10}
 ECHO        /V  ... Display All Possible Backup Jobs Which are Valid for This Computer
 ECHO        /Z  ... Test/Diagnostics Mode {execute test configuration}
 ECHO        /L  ... Enable Verbose Logging for Diagnostics
 ECHO:
 ECHO ----------------------
 ECHO VALID HASH ALGORITHMS:
 ECHO ----------------------
 ECHO  * No Hashing -- Like DIR output ....... NOHASH
 ECHO  * Secure Cryptographic Algorithms ..... SHA256, SHA384, SHA512, SHA3, BLAKE2B, BLAKE2S, BLAKE3
 ECHO  * InSecure Cryptographic Algorithms ... SHA1, MD5
 ECHO  * Non-Cryptographic Algorithms ........ XXHash64, MurmurHash3_X64_128, MurmurHash3_X86_128
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 DailyData
	 ECHO  %~n0 Main-Files /S
	 ECHO  %~n0 My_Stuff /N
	 ECHO  %~n0 SomeStuff /T
	 ECHO  %~n0 ThatStuff /T:3
	 ECHO  %~n0 MoreStuff /F:*.DAT
	 ECHO  %~n0 OtherStuff /F:"*.TXT *.BAT *.CMD"
	 ECHO  %~n0 ThisFolder /C
	 ECHO  %~n0 ThatFolder /R /$:BLAKE3
	 ECHO  %~n0 CriticalStuff /X /Q
	 ECHO  %~n0 WeeklyData /Z /HB
	 ECHO  %~n0 ThisData /E
	 ECHO  %~n0 OtherData /7z
	 ECHO  %~n0 -v
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
	 ECHO  * The name of the archive job cannot contain ANY spaces. Spaces are
	 ECHO    permissable in the job description, however. Shortnames *can* be
	 ECHO    surrounded by quotes if you choose, but it is not mandatory.
	 ECHO:
	 ECHO  * An elevated CMD promt is required in Windows 2008+ in order to
	 ECHO    display the list of scheduled archive tasks.
	 ECHO:
	 ECHO  * If an incorrect, but non-blank, HASH option is selected, then the
	 ECHO    script will continue with the default of XXHASH64.
	 ECHO    Supported hash algorithms include: MD5, SHA1, SHA256, SHA384, SHA512,
	 ECHO    SHA3, BLAKE2B, BLAKE2S, BLAKE3, XXHASH64, MURMURHASH3_128, and NOHASH.
	 ECHO:
	 ECHO  * Unlike the SHA2, SHA3 and BLAKE3 hashes, XXHash64 and MURMURHASH3 are
	 ECHO    generic, non-cryptographic hashes built primarily for performance, not
	 ECHO    security.  They are sufficient for environments which are not subject
	 ECHO    to specific industry or government security or compliance regulations.
	 ECHO:
	 ECHO  * Fastmode ^(/FE^) is now enabled by default for both FILEHASH and DIR, and
	 ECHO    must be overridden at the command-line ^(rather than ArchiveInfo.TXT^).
	 ECHO    - DIR in FastMode will result in only filenames being shown ^(/HF^)
	 ECHO    - FILEHASH always operates in FastMode, and supports /HB and /HF and /SF
	 ECHO    - NOHASH mode gives you the speed of DIR mode, with all the flexibility
	 ECHO      of the other FILEHASH options.
	 ECHO:
	 ECHO  * A syntax error will occur if /F is not accompanied by a custom filespec
	 ECHO    ^(e.g. /F:*.EXE^). This will override any @FILESPEC values set in the config.
	 ECHO:
	 ECHO  * Using @ITEMIZED_INC generates a precise list of files to include in the
	 ECHO    Zip archives.  It is very helpful for files that have the Hidden or System
	 ECHO    attributes set.
	 ECHO:
	 ECHO  * Itemized Include Lists ^(@ITEMIZED_INC and /IL^) only work with 7-Zip, and
	 ECHO    are ignored by Info-Zip.
	 ECHO:
	 ECHO  * Do not use ^(^) in the values of @INFO, @JOBNAME or MSGx variables, as
	 ECHO    these characters will likely prevent the successful completion of this
	 ECHO    script. Please use {} or [] characters instead.
 )

 IF DEFINED @SHOWALL IF DEFINED @JOBLIST (
	 ECHO:
	 ECHO:
	 ECHO The following are valid potential jobs for this system [%COMPUTERNAME%]:
	 ECHO %@DIVIDER%
	 FOR /F "TOKENS=1* DELIMS==" %%B IN ('SET @VALIDJOB-') DO ECHO  %~n0  %%~C -n
	 ECHO:
	 ECHO:
	 ECHO The following archive jobs are scheduled on this system [%COMPUTERNAME%]:
	 ECHO %@DIVIDER%
	 FOR /F "TOKENS=3*" %%B IN ('SCHTASKS ^| FIND /I "Backup Data -"') DO ECHO   %%C
 )
 CALL :ShowStatus "FINISHED"
                