@ECHO OFF
 rem - ASB (16 Feb 2011 // 28 May 2026 / 14 Aug 2025 / 16 Oct 2023 / 07 Mar 2022 / 30 Nov 2020 / 24 Dec 2019): Copy Multiple Folders of a Directory Tree


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v1.9.0.200 d

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=3 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 (
	 ECHO Copy Multiple Folders of a Directory Tree
	 ECHO:
	 ECHO    YOU TYPED: %0 %*
	 ECHO:
	 ECHO   CMD SYNTAX: %~n0  ^<source^> ^<dest^> ^<folder1^>
	 ECHO               %~n0  -h^|-?
	 ECHO:
	 ECHO  USAGE NOTES:
	 ECHO    * Parameters surrounded by ^<^> are mandatory.
	 ECHO    * Parameters surrounded by [] are optional.
	 ECHO    * Options are case-insensitive, and can be prefaced by "-" or "/".
	 GOTO :ExitBatch
 )

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"

 rem -- Main Variables
 SET @SOURCE=%~1
 SET @DEST=%~2
 SET @FOLDERS=%*
 SET @FOLDERS=!@FOLDERS:%1=!
 SET @FOLDERS=!@FOLDERS:%2=!
 FOR %%V IN (SOURCE DEST) DO CALL :FixDirectoryPath @%%V


 rem -- Execute Commands Against Selected Systems
:Main
 ECHO Copying Multiple Folders: %@FOLDERS%
 FOR %%V IN (%@FOLDERS%) DO (
	 ECHO:
	 ECHO **** PREPARING TO COPY FILES ****
	 ECHO %@DIVIDER-%
	 ECHO  FROM: "%@SOURCE%\%%~V"
	 ECHO    TO: "%@DEST%\%%~V"
	 ECHO %@DIVIDER-%
	 CALL ACOPY "%@SOURCE%\%%~V" "%@DEST%\%%~V"
 )


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Remove Trailing \ From Supplied Folder Path
:FixDirectoryPath
 rem %1 = Folder Variable

 IF NOT DEFINED %1 EXIT /B
 IF "!%~1:~-1!"=="\" (
	 SET %~1=!%~1:~0,-1!
	 GOTO :FixDirectoryPath
 )
 EXIT /B


 rem -- SUBROUTINE: Set/Display Script Version and Execution Status (STARTED/FINISHED)
:ShowStatus
 rem %1 = Run Status of Script
 rem %2 = Current Application Version

 IF NOT DEFINED @CUSTOM_TITLE SET @CUSTOM_TITLE=Command Prompt
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
                                        