@REM - ASB (17 Oct 2016 // 18 Aug 2025 / 14 Aug 2025 / 14 Jul 2024 / 15 May 2024 / 13 Sep 2023 / 23 Dec 2020): Configure Bulk Services Based On Search String (List/Start/Stop/Restart/Show/Enable/Disable)
@ECHO OFF


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v3.1.0.310 a

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=2 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f CHOICE NET.EXE SC.EXE TIMEOUT.EXE PSSERVICE.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"

 rem -- Main Variables
 SET @COMMAND=LIST& FOR %%C IN (START STOP RESTART ENABLE DISABLE INFO DELETE) DO IF /I "%~1"=="%%~C" SET @COMMAND=%~1
 SET @STATUS-RESTART=STOPPING and STARTING
 SET @STATUS-STOP=STOPPING
 SET @STATUS-START=STARTING
 SET @STATUS-LIST=LISTING
 SET @STATUS-INFO=DISPLAYING
 SET @STATUS-ENABLE=ENABLING
 SET @STATUS-DISABLE=DISABLING
 SET @STATUS-DELETE=DELETING
 SET @CONFIG-ENABLE=auto
 SET @CONFIG-ENABLE-NEXT=START
 SET @CONFIG-DISABLE=disabled
 SET @CONFIG-DISABLE-NEXT=STOP
 SET @VERIFY-ENABLE=DISABLED
 SET @VERIFY-DISABLE=AUTO_START
 SET @SEARCH=%~2
 SET @SEARCH=%@SEARCH:"=%
 SET @SVCLIST=
 SET @DELAY=5

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "D DELAY" @DELAY    & IF NOT DEFINED @DELAY (SET @DELAY=5)
 CALL :GetParams "C CONFIRM"         & IF DEFINED @OK (SET @CONFIRMATION=TRUE) ELSE (SET @CONFIRMATION=)
 CALL :GetParams "A AUTO AUTOMATION" & IF DEFINED @OK (SET @AUTOMATION=TRUE)   ELSE (SET @AUTOMATION=)


 rem -- Determine if a Valid Command was Issued
:VerifyCommand
 SET @VALID_CMD=
 FOR %%E IN (LIST INFO START STOP RESTART ENABLE DISABLE DELETE) DO IF /I "%~1"=="%%~E" SET @VALID_CMD=TRUE
 IF NOT DEFINED @VALID_CMD (
	 ECHO *** INCORRECT COMMAND ISSUED: "%~1" ***
	 ECHO %@DIVIDER%
	 ECHO:
 )

 rem -- Provide Confirmation If Requested
 IF DEFINED @CONFIRMATION (
	 IF DEFINED @AUTOMATION (SET #DELAY=0 /D Y) ELSE (SET #DELAY=30 /D N)
	 CHOICE /C YNQEX /T !#DELAY! /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :ExitBatch
 )


 rem -- List/Start/Stop Services Containing Search String
:GetServices
 ECHO !@STATUS-%@COMMAND%! Services Containing: "%@SEARCH%"
 ECHO %@DIVIDER-%
 FOR /F "TOKENS=1*" %%a IN ('PSSERVICE %@PSPARAMS% QUERY ^| FIND /I "%@SEARCH%" ^| FIND /I "_NAME" ') DO (
	 FOR /F "TOKENS=1*" %%R IN ('PSSERVICE %@PSPARAMS% QUERY "%%~b" ^| FIND /I "SERVICE_NAME"') DO SET #SVC-%%S=%%S
 )

 FOR /F "TOKENS=1* DELIMS==" %%R IN ('SET "#SVC-" 2^>NUL') DO (
	 FOR %%E IN (ENABLE DISABLE) DO IF /I "%@COMMAND%"=="%%~E" (
		 ECHO  -- !@STATUS-%@COMMAND%! "%%~S"
		 FOR /F "TOKENS=3" %%v IN ('PSSERVICE %@PSPARAMS% CONFIG "%%~S" ^| FIND "START_TYPE"') DO SET @STARTUP=%%v
		 PSSERVICE %@PSPARAMS% SETCONFIG "%%~S" !@CONFIG-%@COMMAND%! | FIND "\\"
		 NET !@CONFIG-%@COMMAND%-NEXT! "%%~S"
		 ECHO:
		 ECHO:
	 )

	 FOR %%E IN (START STOP) DO IF /I "%@COMMAND%"=="%%~E" (
		 ECHO  -- !@STATUS-%@COMMAND%! "%%~S"
		 NET %@COMMAND% "%%~S"
		 ECHO:
		 ECHO:
	 )

	 FOR %%E IN (RESTART) DO IF /I "%@COMMAND%"=="%%~E" (
		 ECHO  -- !@STATUS-%@COMMAND%! "%%~S"
		 NET STOP "%%~S"
		 ECHO Waiting for %@DELAY% Seconds...
		 TIMEOUT %@DELAY%
		 ECHO:
		 NET START "%%~S"
		 ECHO:
		 ECHO:
	 )

	 FOR %%E IN (DELETE) DO IF /I "%@COMMAND%"=="%%~E" (
		 IF DEFINED @CONFIRMATION (
			 ECHO  -- !@STATUS-%@COMMAND%! "%%~S"
			 SC DELETE "%%~S"
			 ECHO:
			 ECHO:
		 ) ELSE (
			 ECHO  -- !@STATUS-%@COMMAND%! "%%~S" -- PROCESS ABORTED, NO CONFIRMATION FOUND
		 )
	 )

	 FOR %%E IN (LIST INFO) DO IF /I "%@COMMAND%"=="%%~E" ECHO  %%S
	 IF /I NOT "%@COMMAND%"=="LIST" SET @SVCLIST=!@SVCLIST! "%%~S"
 )

 IF DEFINED @SVCLIST (
	 ECHO %@DIVIDER-%
	 ECHO:
	 FOR %%S IN (%@SVCLIST%) DO (
		 PSSERVICE QUERY %%S | FIND "DISPLAY_NAME"
		 FOR %%C IN (QC QUERY) DO SC %%C "%%~S" | FIND /V "[SC]"
		 ECHO %@DIVIDER-%
		 ECHO:
	 )
 )
 ECHO %@DIVIDER*%


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Use CheckParams.exe to Capture Selected Parameters
:GetParams
 rem %1 = Parameters to Search For
 rem %2 = Variable to Set

 SET @OK=& IF "%~1"=="" EXIT /B
 FOR /F "TOKENS=2-3*" %%v IN ('CHECKPARAMS -q -a -c "%~1" -s %@ALL_PARAMS% 2^>NUL') DO IF /I "%%~v"=="TRUE" (
	 SET @OK=T
	 SET @REQ=T
	 IF NOT "%~2"=="" SET %~2=%%~x
 )
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
 ECHO Configure Bulk Services Based On Search String (List/Start/Stop/Restart/Show/Enable/Disable)
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<options^> ^<search_string^> [OPTIONS]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ....... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 ...... Display Extended Help Message
 ECHO  -D, /DELAY .... Set a delay interval between service STOP and RESTART
 ECHO  -C, /CONFIRM .. Must be set if DELETE option is selected
 ECHO  -A, /AUTO ..... Use in conjunction with /CONFIRM for automation purposes  *** USE WITH CAUTION ***
 ECHO:
 ECHO  For all services matching the search string, do the following:
 ECHO    LIST ........ List all services
 ECHO    INFO ........ Get detailed info for all services
 ECHO    START ....... Start all services
 ECHO    STOP ........ Stop all services
 ECHO    RESTART ..... Stop AND Restart all services
 ECHO    ENABLE ...... Set all services to AUTO start
 ECHO    DISABLE ..... Set all services to DISABLED
 ECHO    DELETE ...... DELETE all selected services (Must use /C parameter)
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 LIST    Microsoft
	 ECHO  %~n0 INFO    Intel
	 ECHO  %~n0 START   MSExchange
	 ECHO  %~n0 RESTART URB /D:10
	 ECHO  %~n0 DELETE  ThatService /CONFIRM
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO  * Options are case-insensitive, and can be prefaced by "-" or "/".
	 ECHO  * The default delay between STOP/START in a RESTART is 5 seconds.
 )
 CALL :ShowStatus "FINISHED"
                                