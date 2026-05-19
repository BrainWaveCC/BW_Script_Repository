@ECHO OFF
 rem ==========================================================================
 rem === Record Basic CPU Benchmark Results (using GetPrimeNumbers)
 rem ==========================================================================
 rem
 rem Created On: 13 Jan 2020
 rem         By: Andrew S. Baker
 rem
 rem Updated On: 13 Jan 2026 / 01 Jan 2026 / 29 Sep 2025 / 30 Aug 2025
 rem         By: Andrew S. Baker
 rem


 rem ==========================================================================
 rem  OS Required: Windows 2008 or later (previously Windows 2003+)
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem
 rem    SysLogGen .............. http://www.snmpsoft.com/freetools/sysloggen.html
 rem
 rem  Input Files Used By Script (stored in %SystemDrive%\Scripts\Bat\Input):
 rem    CustomVariables.TXT .... Centralized Configuration Settings for Scripts
 rem
 rem  Required Scripts:
 rem    SetDrive.BAT ........... Set Global Variables for this Environment
 rem ==========================================================================


 rem ==========================================================================
 rem === Generate Filtered CMD Title
 rem === Updated On: 14 Aug 2025 / 20 Nov 2020 / 13 Jan 2020
 rem ==========================================================================
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem ==========================================================================
 rem === Initialize Environment Variables
 rem === Updated On: 29 Sep 2025 / 30 Aug 2025 / 26 Sep 2024 / 10 May 2024 / 01 May 2021
 rem ==========================================================================
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v3.3.0.330

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 SET #BWUTILS="%~dp0SetDrive.BAT" CCALC.EXE PRIMEPLUS.EXE READABLE.EXE
 SET #MSUTILS=FINDSTR.EXE SCHTASKS.EXE SLEEP.EXE SYSTEMINFO.EXE
 SET #O_UTILS=SYSLOGGEN.EXE
 FINDFILES --bw -w -m -f %#BWUTILS% %#MSUTILS% -o %#O_UTILS% WMIC.EXE
 IF ERRORLEVEL 64 (CALL :LogCriticalFailure ABORTED - MISSING CRITICAL FILES & GOTO :ExitBatch)

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @PRIME_LIMIT=1,000,000,000

 rem -- Job Scheduling Variables
 SET @JOBNAME=Daily CPU Benchmark
 SET @JOBUSER=SYSTEM
 SET @JOBFREQ=HOURLY /MO 12
 SET @JOBTIME=00:03:00
 SET @JOBDATE=
 SET @JOBPATH="%~f0" %~1
 SET @JOBTYPE=

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Set Contingency Hardware Values
 IF NOT DEFINED @TOTAL_RAM SET @TOTAL_RAM=0KB
 IF NOT DEFINED @CPU_NAME_ONLY SET @CPU_NAME_ONLY=%@CPU_NAME%

 rem -- Standard Log Variables
 SET @LOGPATH=%@STORAGE%\Logs\Maint
 SET @LOGFILE=%@LOGPATH%\%~n0.%@FILESTAMP%
 SET @TIMINGS=%@LOGPATH%\%~n0.RECORDING.TXT

 rem -- Ensure Valid Log Processing Values
 CALL :GetInteger @MINROWS "%@MIN_LOG_ROWS%" 005 001 010
 CALL :GetInteger @MAXROWS "%@MAX_LOG_ROWS%" 199 030 399

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "S ." & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @SCHEDULEONLY=TRUE)
 CALL :GetParams "U -" & IF DEFINED @OK (SET @UPDATESCHED=TRUE& SET @UNSCHED=TRUE)
 CALL :GetParams "N @" & IF DEFINED @OK (SET @NOSCHED=TRUE)
 CALL :GetParams "Z *" & IF DEFINED @OK (SET @UPDATESCHED=FALSE& SET @NODELAY=TRUE) ELSE (SET @NODELAY=)

 rem -- Verify Legitimate Limit for Prime Number Calculation
 SET @VAR=%~1& IF DEFINED @VAR SET @PRIME_LIMIT=!@VAR:"=!
 CALL :GetInteger @PRIME_LIMIT "%@PRIME_LIMIT%" "5,000,000" "250,000,000" "50,000,000,000"

 rem -- Key Variable Verification
 FOR %%V IN (PRIME_LIMIT MINROWS MAXROWS) DO IF NOT DEFINED @%%~V (
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
	 CALL :SaveJobHistory ABORTED - UNDEFINED VARIABLE
	 GOTO :HelpMessage
 )
 %@PRINT_IF_DEBUG%


 rem ==========================================================================
 rem === Create Scheduled Job using SCHTASKS (XP/2003/Vista/+)
 rem === Updated On: 10 May 2024 / 22 Jan 2022 / 13 Jan 2020
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
 rem === Get System Type (Physical vs Virtual)
 rem === Updated On: 01 May 2021 / 14 Feb 2021
 rem ==========================================================================
:PhysicalVsVirtual
 ECHO Determining Physical vs Virtual Status
 SET @SYSTYPE=P& FOR /F "TOKENS=2*" %%I IN ('SYSTEMINFO 2^>NUL ^| FIND "Virtual Machine"') DO SET @SYSTYPE=V

 rem -- Add a Short, Random Delay (60-180 seconds) if Running on a Virtual Machine
 IF "%@SYSTYPE%"=="V" IF NOT DEFINED @NODELAY (
	 FOR /F %%r IN ('DATEINFO -Q -R 120') DO SET /A @DELAY=%%r + 60
	 ECHO  - Virtual Machine will sleep for !@DELAY! seconds...
	 SLEEP !@DELAY!
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Perform Calculation of RAM via WMIC if Previous Value is 0
 rem === Updated On: 23 Nov 2020
 rem ==========================================================================
:GetRAM
 IF /I "%@TOTAL_RAM%"=="0KB" (
	 ECHO Getting Accurate System Memory Info
	 FOR /F "TOKENS=2 DELIMS==" %%R IN ('WMIC COMPUTERSYSTEM GET * /FORMAT:LIST ^| FIND /I "TotalPhysicalMemory"') DO (
		 FOR /F %%M IN ('CCALC Round^(%%R / 1024**3^)') DO SET @TOTAL_RAM=%%MGB
	 )
 )
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Generate Prime Numbers and Record Performance
 rem === Updated On: 12 Feb 2021 / 17 Feb 2020
 rem ==========================================================================
:GetPrime
 FOR %%O IN (CON %@LOGFILE%) DO ECHO Running Basic CPU Benchmark by calculating Prime Numbers up to %@PRIME_LIMIT% >%%O 2>&1
 FOR /F "SKIP=1 TOKENS=1-2* DELIMS=/" %%P IN ('PrimePlus %@PRIME_LIMIT% --BenchMark') DO (
	 SET @BENCHMARK=%%P//%%Q
	 ECHO %%Q//%%R      >>%@LOGFILE%
	 ECHO %@DIVIDER~%   >>%@LOGFILE%
 )
 CALL :SaveJobHistory
 %@PAUSE_IF_DEBUG%


 rem ==========================================================================
 rem === Reset Environment Variables and Exit Batch File
 rem === Updated On: 03 Jul 2024 / 13 Jan 2020
 rem ==========================================================================
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem ==========================================================================
 rem === SUBROUTINE: Store Current Date and Time in Variable
 rem === Updated On: 16 Oct 2023 / 13 Jan 2020
 rem ==========================================================================
:GetTime
 rem %1 = Variable to Store Date/Time

 SET %~1=!DATE! at !TIME: =0!
 FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET %~1#="%%~d"
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
 rem === Updated On: 21 Jan 2020
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
 rem === SUBROUTINE: Pad Variable Content to the Left/Right for Display in Logs
 rem === Updated On: 22 Jan 2020 / 13 Jan 2020
 rem ==========================================================================
:PadLeft
:PadRight
 rem %1 = Variable to Store New Content
 rem %2 = Existing Value to Pad
 rem %3 = Character to use as padding [typically "." or " "]
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
 rem === Updated On: 29 Sep 2025 / 04 Apr 2025 / 18 Jun 2024 / 14 Feb 2021
 rem ==========================================================================
:SaveJobHistory
 rem %* = Optional Message to include in Job History

 CALL :GetTime  @SCRIPT_END
 CALL :PadLeft  @DL "%@DELAY%"         "0"  3
 CALL :PadLeft  @RM "%@TOTAL_RAM%"     "."  6
 CALL :PadLeft  @CS "%@CPU_SOCKETS%"   "-"  1
 CALL :PadLeft  @PC "%@PHY_CORES%"     "-"  2
 CALL :PadLeft  @LC "%@LOG_CORES%"     "-"  3
 CALL :PadLeft  @MH "%@CPU_SPEED% Mhz" "-"  8
 CALL :PadRight @CM "%@CPU_NAME_ONLY%" "."  55

 SET @ROWCOUNT=0
 SET @TRUNCATED=
 SET @ELAPSED=%@NO_TIME%& FOR /F "DELIMS=" %%d IN ('DATEINFO -t !@SCRIPT_BEG#! -n !@SCRIPT_END#! -e "hr:min:sec.ms" -q 2^>NUL') DO SET @ELAPSED=%%d
 SET @SPECIAL=%@JOBTYPE%& IF NOT "%~1"=="" SET @SPECIAL= // %*
 SET @JOBHISTORY=%@BENCHMARK%// {%@SYSTYPE%} RAM.%@RM%  CPU-%@CS%-%@PC%-%@LC%-%@MH% // %@CM% // DURATION: %@ELAPSED% [%@DL%] // START: %@SCRIPT_BEG% // END: !@SCRIPT_END! // %~n0 %@VERSION%%@SPECIAL%

 %@VERBOSE_OFF%
 TYPE NUL >>"%@TIMINGS%"
 FOR /F %%c IN ('READABLE "%@TIMINGS%" -F "/" --TO -Q 2^>NUL') DO SET @ROWCOUNT=%%c
 IF !@ROWCOUNT! GTR %@MAXROWS% (
	 SET @TRUNCATED= // TRUNCATED
	 SET @OLDTIME=!@TIMINGS:TXT=%@FILESTAMP%!
	 COPY "%@TIMINGS%" "!@OLDTIME!" /V /Y >CON
	 READABLE "!@OLDTIME!" --ST -%@MINROWS% -O "%@TIMINGS%"
	 ECHO:
	 CALL :ForwardToSyslog "5" %@JOBNAME%: Job History Logfile Truncated -- [!DATE! at !TIME!]
 ) >>"%@LOGFILE%" 2>&1

 CALL :ForwardToSyslog "6" %@JOBHISTORY%!@TRUNCATED! >>"%@TIMINGS%" 2>>"%@LOGFILE%"
 %@VERBOSE_ON%
 %@PAUSE_IF_DEBUG%
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
 rem === Updated On: 23 Jun 2024 / 14 Jan 2020
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
 rem === SUBROUTINE: Check if Scheduled Job is Already Running
 rem === Updated On: 03 Sep 2024 / 13 Jan 2020
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
 rem === Updated On: 22 Sep 2025 / 16 Oct 2023 / 13 Jan 2020
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
 rem === Updated On: 01 May 2021 / 30 Nov 2020
 rem ==========================================================================
:HelpMessage
 ECHO Record Basic CPU Benchmark Results (using GetPrimeNumbers)...
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [max_possible_prime] [options]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO  /S,  .  ..... Schedule the Job, But Don't Execute It
 ECHO  /U,  -  ..... Unschedule the Job Only, Without Executing It First
 ECHO  /N,  @  ..... Execute the Job without Scheduling It
 ECHO  /Z,  *  ..... Do Not Wait for a Delay When Executed on a VM
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 -u
	 ECHO  %~n0 1000000000
	 ECHO  %~n0 "200,000,000" /s
	 ECHO  %~n0 "2,000,000,000" -N
	 ECHO  %~n0 -?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO  * Options are case-insensitive, and can be prefaced by "-" or "/".
	 ECHO  * If no number is provided, a default of 500,000 will be used.
	 ECHO  * If the provided number is ^(^< 2 or ^> 5,000,000^) then the default will be used.
	 ECHO  * Quotation marks are optional
 )
 CALL :ShowStatus "FINISHED"
                        