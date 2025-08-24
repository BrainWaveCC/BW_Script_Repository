@REM - ASB (25 Nov 2020 // 24 Aug 2025): Wait Until "mm/dd/yyyy XX:XX:XX" to Execute a Command
@ECHO OFF


 rem ==========================================================================
 rem  OS Required: Windows 2003 and later
 rem
 rem  Non-Native Utilities Used/Required:
 rem    BrainWave Utilities .... https://www.BrainWaveCC.com/brainwave-utilities
 rem      CHECKPARAMS .......... Process script parameters
 rem      DATEINFO ............. Calculate date and time
 rem      FINDFILES ............ Verify the existence of files in the path
 rem      NOW .................. Display output with time and date
 rem
 rem    CHOICE ................. Native in Windows 2003+ / Reskit in NT/2000
 rem    TIMEOUT ................ Native in Windows 10+   / Reskit in 2003+
 rem    Resource Kit ........... https://en.wikipedia.org/wiki/Resource_Kit
 rem ==========================================================================

 :::  This purpose of this script is to wait until a specific future time 
 :::  and/or date to run another script or command.


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v1.6.0.110

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=2 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f CHOICE.EXE CMD.EXE TIMEOUT.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"

 rem -- Main Variables
 SET "@WAITUNTIL=%~1" & IF "%~1"=="" SET "@WAITUNTIL=00:00:00"
 SET "@RUN=%*"
 SET "@RUN=!@RUN:%1=!"

 rem -- Format @WAITUNTIL to proper date/time
 FOR /F "TOKENS=*" %%D IN ('DATEINFO -S "%@WAITUNTIL%" %@DATEFMT:.zzz=% -Q 2^>NUL') DO SET "@WAITUNTIL=%%D"
 IF DEFINED @WAITUNTIL SET "@WAITUNTIL=!@WAITUNTIL:12/30/1899=%@DATE%!"

 rem -- Generate Alert if @TESTME is Defined
 IF DEFINED @TESTME NOW \s \n\**** THIS IS ONLY A TEST [@TESTME = !@TESTME!]\n\*\n


 rem -- Wait Until Appointed Time Before Proceeding
:DeliberateDelay
 ECHO Getting Ready to Run ...%@RUN%
 ECHO Starting at ............ %@WAITUNTIL%
 ECHO %@DIVIDER%
 CHOICE /C YNQEX /T 20 /D Y /N /M "Continue running this script? (Y/N/Q) "
 IF ERRORLEVEL 2 GOTO :ExitBatch

 ECHO:
 SET "@INCREMENT=0"
 IF DEFINED @TESTME GOTO :END_WaitUntil

:WaitUntil
 FOR /F "TOKENS=*" %%D IN ('DATEINFO -S %@DATEFMT:.zzz=% -Q 2^>NUL') DO SET "@CURRENT_TIME=%%D"
 IF "!@CURRENT_TIME!" GEQ "%@WAITUNTIL%" GOTO :END_WaitUntil
	 IF DEFINED @INCREMENT IF "!@INCREMENT:~-1!"=="0" ECHO [!@CURRENT_TIME!] WAITING UNTIL "%@WAITUNTIL%" (DATE @ Hr:Min:Sec)...
	 TIMEOUT /T 1 /NOBREAK >NUL 
	 SET /A "@INCREMENT+=1"
	 GOTO :WaitUntil
:END_WaitUntil


 rem -- Run This
:RunThis
 ECHO:
 ECHO !DATE! at !TIME: =0! -- Running: %@RUN%
 ECHO:
 CMD /C %@RUN%


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Set/Display Script Version and Execution Status (STARTED/FINISHED)
:ShowStatus
 rem %1 = Run Status of Script
 rem %2 = Current Application Version

 IF NOT DEFINED @DATEFMT SET "@DATEFMT=-F "mm/dd/yyyy hh:nn:ss.zzz""
 SET "@SCRIPTSTATUS=%~1" & IF "%~1"=="" SET "@SCRIPTSTATUS=RUNNING"
 IF NOT "%~2"=="" (SET "@VER=%~nx0 %~2" & SET "@VERSION=%~2")
 IF /I "%~1"=="STARTED" FOR /F "TOKENS=*" %%d IN ('DATEINFO -S %@DATEFMT% -Q 2^>NUL') DO SET "@SCRIPT_BEG#="%%~d""
 IF /I "%~1"=="FINISHED" (
	 IF DEFINED $CODEPAGE FOR /F "TOKENS=1* DELIMS=:" %%B IN ('CHCP %$CODEPAGE%') DO SET "@CHCP_STATUS= {Restoring Code Page:%%C}"
	 IF DEFINED @END_DEBUG_MODE %@END_DEBUG_MODE:"=%
	 TITLE Command Prompt [%USERDOMAIN%\%USERNAME%]   !@DEBUG_MODE!
	 DATEINFO -t %@SCRIPT_BEG#% -e "hr:min:sec.ms" -o "\n*** DURATION: " 2>NUL
 )
 NOW \n*** %@SCRIPTSTATUS%: %@VER% [\v] *** %@CHCP_STATUS%\n!@CRLF-%~1!
 EXIT /B


 rem -- SUBROUTINE: Display Syntax Help if Required/Requested
:HelpMessage
 ECHO Wait Until "mm/dd/yyyy XX:XX:XX" to Execute a Command
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<start_time^> ^<command here w/parameters^>
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
	 ECHO  %~n0 12:00:01 "Some Commands Here"
	 ECHO  %~n0 18:30 DIR /OGN D:\
	 ECHO  %~n0 "02/22/2032 18:30" IPCONFIG /ALL
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
       