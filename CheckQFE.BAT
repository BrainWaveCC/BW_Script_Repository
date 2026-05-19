@ECHO OFF
 rem - ASB (20 Mar 2024 // 23 Oct 2025 / 20 Oct 2025 / 14 Aug 2025 / 30 Oct 2024 / 11 Aug 2024 / 27 Jun 2024): Check for Installed Windows Patches via WMIC QFE


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v2.0.0.200 a

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=0 -c "H HELP ?" -x "?? H2" -s %* >NUL
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f CCALC.EXE MAKESTRING.EXE READABLE.EXE  DISM.EXE SORT.EXE UPTIME.EXE  PSEXEC.EXE -O WMIC.EXE 
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"

 rem -- Main Variables
 SET @BUILDINFO-LATEST=%~dp0Input\[WindowsBuilds-Latest].TXT
 SET @WAIT_MSG=\nPlease Wait...\n
 SET @SYSTEM=%~1& IF "%~1"=="" (SET @SYSTEM=%COMPUTERNAME%& SET @WAIT_MSG=)
 SET @SYSTEM=%@SYSTEM:\=%
 SET @CNAME2=%@SYSTEM% %@DOTS%
 SET @CNAME2=%@CNAME2:~0,22%
 SET @DIVLEN=10

 rem -- If Running Against the Local System, Do Not Execute PSEXEC commands
 SET @LOCALSYS=TRUE
 SET @CONNECT=
 IF /I NOT "%@SYSTEM%"=="%COMPUTERNAME%" (
	  SET @LOCALSYS=FALSE
	  SET @CONNECT=PSEXEC %@PSPARAMS% \\%@SYSTEM% -n 15 
 )

 rem -- Standard Log Variables
 SET @LOGROOT=%TEMP%\%~n0
 FOR %%F IN (LIST HEAD TEMP) DO SET @QFE_%%F="%@LOGROOT%\%~n0-%@SYSTEM%-%%F.%@DIRSTAMP_R%.TXT"


 rem -- Attempt to install WMIC if not found in Windows 11+ / Server 2025+
:GetWMIC
 FINDFILES --RC -F WMIC.EXE || DISM /Online /Add-Capability /CapabilityName:WMIC


 rem -- Capture QFE Info from Local or Remote System
:QueryWMIC
 IF NOT EXIST "%@LOGROOT%" MD "%@LOGROOT%"
 NOW Querying Windows Patch Information on \\%@SYSTEM% on \v\n%@WAIT_MSG%
 WMIC /NODE:%@SYSTEM% QFE GET Caption,Description,HotFixID,InstalledBy,InstalledOn /FORMAT:TABLE >%@QFE_LIST%
 TYPE %@QFE_LIST% | FIND /I "InstalledOn" >%@QFE_HEAD%


 rem -- Get Latest Date for Windows Build
:LatestBuildInfo
 FOR /F "TOKENS=5*" %%U IN ('UPTIME \\%@SYSTEM% 2^>NUL ^| FIND /I "%@SYSTEM%"') DO SET @UPTIME=%%V
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('%@CONNECT%DATEINFO --Script-Variables --Filter^="@OS;@NEEDS" 2^>NUL') DO SET %@SYSTEM%-%%P=%%~Q
 FOR /F "TOKENS=1" %%D IN ('READABLE "%@BUILDINFO-LATEST%" -F "!%@SYSTEM%-@OSVER!" 2^>NUL') DO IF NOT DEFINED %@SYSTEM%-LATEST SET %@SYSTEM%-LATEST=%%~D
 ECHO %@CNAME2% !%@SYSTEM%-@OSEDITION!

 rem -- Process Each Line in Queried Data
:DetermineLineLength
 FOR /F "TOKENS=* DELIMS=·" %%L IN ('TYPE %@QFE_LIST% 2^>NUL') DO IF NOT DEFINED @LENGTH (
	 SET @QFE_LINE=%%L
	 CALL :GetLength
 )

:ProcessEachLine
 ( rem -- Write to Log
	 FOR /F "SKIP=1 TOKENS=* DELIMS=·" %%L IN ('TYPE !@QFE_LIST! 2^>NUL') DO (
		 SET @QFE_LINE=%%L
		 SET @QFE_INFO=!@QFE_LINE:~0,%@SHORT%!
		 SET @OLD_DATE=!@QFE_LINE:~%@SHORT%,11!
		 FOR /F %%c IN ('CCALC ^(!@OLD_DATE! + 0^) --ZERO 2^>NUL') DO IF "%%~c"=="0" SET @OLD_DATE=12/31/1999
		 FOR /F "TOKENS=1-2" %%d IN ('DATEINFO -s "!@OLD_DATE!" -f "mm/dd/yyyy yyyy-mm-dd" -q 2^>NUL') DO (
			 SET @QFE_DATE=%%d
			 SET @QFE_DATE2=%%e
		 )
		 ECHO !@QFE_INFO! !@QFE_DATE2!
		 IF NOT DEFINED @LASTPATCH (
			 SET @LASTPATCH=!@QFE_DATE!
			 SET @LASTPATCH2=!@QFE_DATE2!
		 ) ELSE (
			 IF !@QFE_DATE2! GEQ !@LASTPATCH2! (
				 SET @LASTPATCH=!@QFE_DATE!
				 SET @LASTPATCH2=!@QFE_DATE2!
			 )
		 )
	 )
 ) >!@QFE_TEMP!

 rem -- Check for Latest Patches based on Build Date
 IF "!@LASTPATCH2!" LSS "!%@SYSTEM%-LATEST!" (SET @STATUS_MSG=[MISSING PATCHES FROM: !%@SYSTEM%-LATEST!]) ELSE (SET @STATUS_MSG=)


 rem -- Change Date Format, Sort and Display Data
:ShowInstalledPatches
 SORT /R /+%@SHORT% !@QFE_TEMP! /O !@QFE_LIST!
 MAKESTRING - %@DIVLEN%
 READABLE !@QFE_HEAD! --DL 1 --LL %@DIVLEN% --LC "-"
 READABLE !@QFE_LIST! --DL 1 --LL %@DIVLEN% --LC "*"
 ECHO *** MOST RECENT PATCH INSTALLED ON %@CNAME2% !@LASTPATCH!  %@STATUS_MSG%
 MAKESTRING * %@DIVLEN%
 ECHO *** System Update: %@UPTIME%
 ECHO *** Reboot Status: !%@SYSTEM%-@NEEDS_REBOOT_MSG!
 MAKESTRING * %@DIVLEN%
 %@PRINT_IF_DEBUG%


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Determine the Line Length and Set Essential Length Variables
:GetLength
 FOR /L %%C IN (299,-1,1) DO IF NOT "!@QFE_LINE:~%%C,1!"=="" IF NOT DEFINED @LENGTH SET /A @LENGTH=%%C - 2
 FOR /F %%C IN ('CCALC !@LENGTH! - 11 2^>NUL') DO SET @SHORT=%%C
 FOR /F %%C IN ('CCALC !@LENGTH! + 3  2^>NUL') DO SET @DIVLEN=%%C
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem -- SUBROUTINE: Determine if Parameter is a Valid Integer, Or Set to Zero
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
 ECHO Check for Installed Windows Patches via WMIC (Local or Remote)
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [OPTIONS] [remote_server]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H .......... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 ......... Display Extended Help Message
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 %COMPUTERNAME%
	 ECHO  %~n0 \\some_remote_server
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
	 ECHO  * If no system is provided, the local system will be reported on.
 )
 CALL :ShowStatus "FINISHED"
                    