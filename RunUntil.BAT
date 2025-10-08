@REM - ASB (27 Aug 2019 // 14 Aug 2025 / 16 Oct 2023 / 08 Dec 2021 / 30 Nov 2021 / 30 Nov 2020 / 13 May 2020 / 24 Dec 2019): Suspend and Unsuspend Specific Processses at Specific Times
@ECHO OFF


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem -- Enable Debug Mode If 'Debug' Variable is Set to TRUE/LOG/STEP/VERBOSE
:DebugMode
 SET #DEBUG=& FOR %%d IN (LOG STEP TRUE VERBOSE) DO IF /I "%Debug%"=="%%~d" SET #DEBUG=TRUE
 IF DEFINED #DEBUG (
	 SET @DIAGMODE=TRUE
	 SET @DEBUG_MODE=[DEBUG MODE ON]
	 SET @PAUSE_IF_DEBUG=TIMEOUT 5
	 SET @PRINT_IF_DEBUG=ECHO:^& SET @^& ECHO:^& TIMEOUT 5
	 SET @END_DEBUG_MODE=ECHO:^& ECHO *** DEBUG MODE FINISHED ***^& ECHO:^& SET @^& TIMEOUT 30
	 IF /I "%Debug%"=="LOG" (SET @PAUSE_IF_DEBUG=& SET @PRINT_IF_DEBUG=ECHO:^& SET @^& ECHO:)
	 IF /I "%Debug%"=="STEP" (SET @PAUSE_IF_DEBUG=ECHO ##PAUSE##& SET @PRINT_IF_DEBUG=ECHO ##PRINT##)
	 IF /I "%Debug%"=="VERBOSE" (SET @VERBOSE_OFF=ECHO ON) ELSE (FOR %%t IN (ON OFF) DO SET @VERBOSE_%%t=ECHO %%t)
	 ECHO *** DEBUG MODE = ON ***
	 ECHO ON
 ) ELSE ( FOR %%d IN (DEBUG_MODE PAUSE_IF_DEBUG PRINT_IF_DEBUG END_DEBUG_MODE VERBOSE_ON VERBOSE_OFF) DO SET @%%d=)


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v1.8.0.140 b

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=3 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"

 rem -- Main Variables
 SET @NOTFOUND=
 SET @EXECUTE=
 SET @COUNT=0
 SET @INCREMENT=0
 SET @PROCESS=%~1
 SET @RUN_UNTIL=%~2
 SET @STOP_UNTIL=%~3
 SET @ITERATIONS=%~4& IF "%~4"=="" SET @ITERATIONS=1
 CALL :GetDateTime @RUN_UNTIL
 CALL :GetDateTime @STOP_UNTIL

 rem -- Generate Alert if @TESTME is Defined
 IF DEFINED @TESTME NOW \s \n\**** THIS IS ONLY A TEST [@TESTME = !@TESTME!]\n\*\n
 %@PRINT_IF_DEBUG%


 rem -- Determine that Process is Actually Running
:VerifyProcess
 ECHO Checking for Process: %@PROCESS%
 ECHO %@DIVIDER-%
 FOR /F "TOKENS=*" %%P IN ('PSLIST %@PSPARAMS% -E "%@PROCESS%" ^| FIND /I "process %@PROCESS% was not found" 2^>NUL') DO SET @NOTFOUND=TRUE
 IF DEFINED @NOTFOUND (
	 ECHO ERROR: COULD NOT FIND PROCESS: "%@PROCESS%"
	 GOTO :ExitBatch
 )


 rem -- Show Start/Stop Times and Verify Operation
:VerifyOperation
 ECHO  - PROCESS NAME ...... %@PROCESS%
 IF "%@RUN_UNTIL%" GEQ "%@STOP_UNTIL%" (
	 SET @EXECUTE=GOTO :SuspendProcess
	 ECHO  - SUSPENSION TIME ... from "%@CURRENT_TIME%" until "%@STOP_UNTIL%"
	 ECHO  - EXECUTION TIME .... from "%@STOP_UNTIL%" until "%@RUN_UNTIL%"
 ) ELSE (
	 SET @EXECUTE=PSSUSPEND %@PSPARAMS% "%@PROCESS%" /R
	 ECHO  - EXECUTION TIME .... from "%@CURRENT_TIME%" until "%@RUN_UNTIL%"
	 ECHO  - SUSPENSION TIME ... from "%@RUN_UNTIL%" until "%@STOP_UNTIL%"
 )
 ECHO  - ITERATIONS ........ %@ITERATIONS%
 ECHO %@DIVIDER-%
 CHOICE /C YNQEX /T 20 /D Y /N /M "Continue running this script? (Y/N/Q) "
 IF ERRORLEVEL 2 GOTO :ExitBatch


 rem -- Start Management of Selected Process
:ManageProcess
 ECHO %@DIVIDER-%
 ECHO:
 %@EXECUTE%


 rem -- Wait Until Appointed Time Before Suspending Process
:Wait2Pause
 CALL :GetCurrentTime
 IF "!@CURRENT_TIME!" GEQ "%@RUN_UNTIL%" GOTO :END_Wait2Pause
	 IF DEFINED @INCREMENT IF "!@INCREMENT:~-1!"=="0" ECHO [!@CURRENT_TIME!] "%@PROCESS%" will be EXECUTED UNTIL "%@RUN_UNTIL%" ...
	 SLEEP 2
	 SET /A @INCREMENT+=1
	 GOTO :Wait2Pause
:END_Wait2Pause
 ECHO %@DIVIDER-%


 rem -- Suspend the Process
:SuspendProcess
 CALL :GetDateTime @STOP_UNTIL
 ECHO:
 ECHO  - %@PROCESS% will be SUSPENDED from "%@RUN_UNTIL%" until "%@STOP_UNTIL%"
 ECHO:
 PSSUSPEND %@PSPARAMS% "%@PROCESS%"
 IF "!@ERRORLEVEL!"=="-1" GOTO ExitBatch
 IF DEFINED @TESTME GOTO :END_Wait2Run


 rem -- Wait Until Appointed Time Before Unsuspending Process
:Wait2Run
 CALL :GetCurrentTime
 IF "!@CURRENT_TIME!" GEQ "%@STOP_UNTIL%" GOTO :END_Wait2Run
	 IF DEFINED @INCREMENT IF "!@INCREMENT:~-1!"=="0" ECHO [!@CURRENT_TIME!] "%@PROCESS%" will be SUSPENDED UNTIL "%@STOP_UNTIL%" ...
	 SLEEP 2
	 SET /A @INCREMENT+=1
	 GOTO :Wait2Run
:END_Wait2Run
 ECHO %@DIVIDER-%


 rem -- UNsuspend the Process
:UnsuspendProcess
 CALL :GetDateTime @RUN_UNTIL
 ECHO:
 ECHO  - %@PROCESS% will be EXECUTED from "%@CURRENT_TIME%" until "%@RUN_UNTIL%"
 ECHO:
 PSSUSPEND %@PSPARAMS% "%@PROCESS%" /R
 IF "!@ERRORLEVEL!"=="-1" GOTO ExitBatch
 SET /A @COUNT+=1
 IF /I %@COUNT% LSS %@ITERATIONS% GOTO :Wait2Pause
 %@PAUSE_IF_DEBUG%


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Get Formatted Date/Time
:GetDateTime
:GetCurrentTime
 rem %1 = Optional Variable to Assign to Date/Time

 FOR /F "TOKENS=*" %%D IN ('DATEINFO -S -F "mm/dd/yyyy hh:nn:ss" -Q 2^>NUL') DO SET @CURRENT_TIME=%%D
 IF /I "%~0"==":GetCurrentTime" EXIT /B

 FOR /F "TOKENS=*" %%D IN ('DATEINFO -S "!%~1!" -F "mm/dd/yyyy hh:nn:ss" -Q 2^>NUL') DO SET @UNTIL=%%D
 IF "%@CURRENT_TIME%" GTR "%@UNTIL%" FOR /F "TOKENS=*" %%D IN ('DATEINFO -S "%@UNTIL%" -F "mm/dd/yyyy hh:nn:ss" -A 1 -Q 2^>NUL') DO SET @UNTIL=%%D
 IF NOT "%~1"=="" SET %~1=!@UNTIL!
 SET @INCREMENT=0
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem -- SUBROUTINE: Set/Display Script Version and Execution Status (STARTED/FINISHED)
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


 rem -- SUBROUTINE: Display Syntax Help if Required/Requested
:HelpMessage
 ECHO Suspend and Unsuspend Specific Processses at Specific Times
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<"process name"^> ^<"Run Until Time"^> ^<"Suspend Until Time"^> [Number of Iterations]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0  MyProc       "22:00:00" "08:30:00"
	 ECHO  %~n0  "My Process" "18:00:00" "04:00:00" 2
	 ECHO  %~n0  Chrome       "05:00:00" "05:30:00" 5
	 ECHO  %~n0  Robocopy     "08:00:00" "19:00:00" 10
	 ECHO  %~n0 /?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO  * Options are case-insensitive, and can be prefaced by "-" or "/".
 )
 CALL :ShowStatus "FINISHED"
            