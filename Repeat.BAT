@REM - ASB (20 Nov 2011 // 22 Sep 2025 / 14 Aug 2025 / 06 Mar 2025 / 10 May 2024 / 16 Oct 2023 / 30 Nov 2020 / 13 May 2020): Repeat a command XXX times, with YYY delay between iterations
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
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v2.8.0.270 c

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=3 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 (
	 ECHO Repeat a command XXX times, with YYY delay between iterations
	 ECHO:
	 ECHO    YOU TYPED: %0 %*
	 ECHO:
	 ECHO   CMD SYNTAX: %~n0  ^<# of repetitions^> ^<delay^> ^<command w/params^>
	 ECHO               %~n0  -h^|-?
	 ECHO:
	 ECHO  USAGE NOTES:
	 ECHO    * Parameters surrounded by ^<^> are mandatory.
	 ECHO    * Parameters surrounded by [] are optional.
	 ECHO    * Options are case-insensitive, and can be prefaced by "-" or "/".
	 GOTO :ExitBatch
 )

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f CHOICE.EXE CMD.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Main Variables
 SET @ITERATIONS=0
 SET @COUNT=%~1
 SET @DELAY=%~2& FOR %%V IN ("" ".") DO IF "%~2"=="%%~V" SET @DELAY=3
 SET @EXECUTE=& FOR /F "TOKENS=2*" %%C IN ('ECHO %*') DO SET @EXECUTE=%%D
 CALL :MakeCMD @EXECUTE


 rem -- Execute each command XXX times with YYY delay between each iteration
:Execute
 ECHO Executing the following command for %@COUNT% iterations [%@DELAY% seconds delay]:
 ECHO  %@EXECUTE%

 FOR /L %%V IN (1,1,%@COUNT%) DO (
	 ECHO:
	 CHOICE /C YNQEX /T %@DELAY% /D Y /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :FinalReport
	 CALL :DoThis
	 SET @ITERATIONS=%%V
 )


 rem -- Generate Final Execution Report
:FinalReport
 ECHO:
 ECHO The following command was executed %@ITERATIONS% of %@COUNT% times:
 ECHO  %@EXECUTE%


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Create Special Commands, Substituting [[ and ]] for ( and )
:MakeCMD
 rem %1 = Variable to Sanitize

 SET @CMD=!%1!
 SET @CMD=!@CMD:[[=^(!
 SET @CMD=!@CMD:]]=^)!
 SET @CMD=!@CMD:;;=^^^&!
 SET @CMD=!@CMD://=^^^|!
 SET %1=!@CMD!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem -- SUBROUTINE: Execute Each Command on the Remote System
:DoThis
 rem %1 = Command To Execute

 ECHO:
 ECHO:
 FOR %%D IN (TITLE ECHO) DO %%D - !DATE! at !TIME! - STARTING: Iteration #%%~V of %@COUNT%
 CMD /C %@EXECUTE%
 ECHO:
 FOR %%D IN (TITLE ECHO) DO %%D - !DATE! at !TIME! - FINISHED: Iteration #%%~V of %@COUNT%	 [w/%@DELAY% second delay]
 ECHO:
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
 %@PRINT_IF_DEBUG%
 EXIT /B
   