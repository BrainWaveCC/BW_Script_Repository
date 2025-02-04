@REM - ASB (21 Jan 2010 // 15 Jan 2024 / 16 Oct 2023 / 30 Nov 2020 / 22 Jan 2020 / 24 Dec 2019 / 09 Dec 2019 / 30 Sep 2019 / 26 Jul 2018 / 08 May 2018): Find Scripts or Utilities in the PATH
@ECHO OFF
 CLS


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v3.4.0.340

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Main Variables
 SET @QUERY=*%~1*
 SET @EXTENSIONS=.EXE .COM .MSI .MSC .BAT .CMD .PS .PS1 .VBS .KIX .JAV .JAVA .PL .PY
 SET @EXEMPTIONS=.DLL .OCX .SYS .PS1XML
 SET @COUNT=0


 rem -- Verify that WHERE.EXE is available
:UseWHERE
 WHERE WHERE >NUL 2>&1 && GOTO :SearchPath
 ECHO:
 ECHO *** ERROR: COULD NOT FIND WHERE.EXE ***
 GOTO :ExitBatch


 rem -- Search Through PATH Folders via WHERE
:SearchPath
 ECHO:
 ECHO Searching PATH for Scripts/Executables named "%@QUERY%"...
 ECHO:
 FOR /F "TOKENS=1-6* DELIMS=/ " %%A IN ('WHERE "%@QUERY%" /T 2^>NUL ^| FINDSTR /I /L "%@EXTENSIONS%" ^| FINDSTR /V /I /L "%@EXEMPTIONS%"') DO (
	 SET /A @COUNT+=1
	 CALL :PadLeft @INDEX "!@COUNT!"  " "  4
	 CALL :PadLeft @SIZE  " %%~A"     "." 12
	 CALL :PadLeft @DATE1 "%%~B"      "0"  2
	 CALL :PadLeft @DATE2 "%%~C"      "0"  2
	 CALL :PadLeft @TIME  "%%~E %%~F" "0" 11

	 IF NOT DEFINED @NEW_FOLDER SET @NEW_FOLDER=%%~dpG
	 IF /I NOT "%%~dpG"=="!@NEW_FOLDER!" (
		 SET @NEW_FOLDER=%%~dpG
		 ECHO:
	 )
	 ECHO  [!@INDEX!] !@SIZE! !@DATE1!/!@DATE2!/%%~D !@TIME! - %%~G
 )


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Pad Variable Content to the Left/Right for Display in Logs
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
 GOTO :EOF


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
 GOTO :EOF


 rem -- SUBROUTINE: Display Syntax Help if Required/Requested
:HelpMessage
 ECHO Find Scripts or Utilities in the PATH
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<search string^>
 ECHO  %~n0  [-h^|-?^|-h2^|-??]
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
	 ECHO  %~n0 admin
	 ECHO  %~n0 ps
	 ECHO  %~n0 open
	 ECHO  %~n0 domain
	 ECHO  %~n0 scripts
	 ECHO  %~n0 exp*r
	 ECHO  %~n0 -?
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO:
	 ECHO  * Options are case-insensitive, and can be prefaced by "-" or "/".
 )
 CALL :ShowStatus "FINISHED"
            