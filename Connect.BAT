@ECHO OFF
 rem - ASB (01 Jan 1998 // 11 May 2026 / 05 May 2026 / 22 Sep 2025 / 14 Aug 2025 / 06 Mar 2025 / 14 Jul 2024 / 19 May 2024): Initiate Remote Console Connection with Optional Commands


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET "@TTT=%* "
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v8.3.0.1031

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=1 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f CMD.EXE PING.EXE ROUTE.EXE SC.EXE TIMEOUT.EXE -o PAEXEC.EXE PSEXEC.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"

 rem -- Main Variables
 SET @CONNECT=%~1& CALL :GetSysName @CONNECT
 SET @CUSTOM_TITLE=Connect to Remote Console on %@CONNECT%
 SET @PARAMS=§§%*& SET @PARAMS=!@PARAMS:§§%1=!
 SET @CMD=CMD /K
 SET @EXIT=EXIT
 SET @PAUSE=TIMEOUT 60

 rem -- Hide Remote Console Startup Details
 SET @QUIET_RC=& IF NOT DEFINED DEBUG SET @QUIET_RC=^>NUL 2^>^&1

 rem -- Determine Location/Existence of Remote Console Utilities
 SET @REXEC_UTILS=BeyondExecV2 PAEXEC PSEXEC
 FOR /F "TOKENS=*" %%R IN ('WHERE BeyondExecV2 2^>NUL') DO SET @B_REMOTE=%%~nxR
 FOR /F "TOKENS=*" %%R IN ('WHERE PAEXEC       2^>NUL') DO SET @A_REMOTE=%%~nxR
 FOR /F "TOKENS=*" %%R IN ('WHERE PSEXEC       2^>NUL') DO SET @P_REMOTE=%%~nxR %@PSPARAMS% -s
 SET @RMTCONSOLE=&               IF DEFINED @B_REMOTE SET @RMTCONSOLE=%@B_REMOTE%
 IF /I NOT "%@NOPAEXEC%"=="TRUE" IF DEFINED @A_REMOTE SET @RMTCONSOLE=%@A_REMOTE%
 IF /I NOT "%@NOPSEXEC%"=="TRUE" IF DEFINED @P_REMOTE SET @RMTCONSOLE=%@P_REMOTE%


 rem -- Check for Error Conditions
:VerifyConditions
 SET @ERRMSG=
 IF NOT DEFINED @RMTCONSOLE SET @ERRMSG=NO REMOTE CONSOLE UTILITY AVAILABLE ON THIS SYSTEM
 IF /I "%~1"=="%COMPUTERNAME%" SET @ERRMSG=YOU MUST SELECT A REMOTE SYSTEM TO CONNECT TO
 IF DEFINED @ERRMSG (
	 ECHO *** ERROR: %@ERRMSG% ***
	 ECHO:
	 SET @DEBUG_MODE=*** ABORTED EXECUTION ***
	 SET @PAUSE=TIMEOUT 600
	 GOTO :ExitBatch
 )


 rem -- Determine if Remote System is Available
:VerifyAccess
 IF DEFINED @REMOTE_PING (
	 PING %@CONNECT% 2>&1
	 ECHO:
 )
 IF NOT DEFINED @JUST_CONNECT (
	 DIR "%@CONNECT#%\C$" >NUL 2>NUL
	 IF ERRORLEVEL 1 (
		 ECHO ### ERROR: "%@CONNECT%" IS NOT ACCESSIBLE ###
		 SET @DEBUG_MODE=*** UNREACHABLE SYSTEM ***
		 SET @PAUSE=TIMEOUT 600
		 GOTO :ExitBatch
	 )
 )


 rem -- Check Parameters for Configuring Remote Utility and CMD Console
:GetParams
 FOR %%P IN (%*) DO FOR %%Q IN (@@B @@BT @@A  @@AT @@P @@PT @@T) DO IF /I "%%~P"=="%%~Q" (
	 SET @PARAMS=!@PARAMS:%%P=!
	 FOR %%O IN (@@B  @@BT         ) DO IF /I "%%~P"=="%%~O" IF DEFINED @B_REMOTE SET @RMTCONSOLE=%@B_REMOTE%
	 FOR %%O IN (@@A  @@AT         ) DO IF /I "%%~P"=="%%~O" IF DEFINED @A_REMOTE SET @RMTCONSOLE=%@A_REMOTE%
	 FOR %%O IN (@@P  @@PT         ) DO IF /I "%%~P"=="%%~O" IF DEFINED @P_REMOTE SET @RMTCONSOLE=%@P_REMOTE%
	 FOR %%O IN (@@BT @@AT @@PT @@T) DO IF /I "%%~P"=="%%~O" SET @CMD=CMD /C
 )

 rem -- Start "Remote Registry" service on Remote System if not running
 FOR /F "TOKENS=4" %%S IN ('SC %@CONNECT#% QUERY "RemoteRegistry" ^| FIND "STATE"') DO (
	 IF NOT "%%~S"=="RUNNING" (
		 ECHO Starting Remote Registry Service on %@CONNECT%...
		 SC %@CONNECT#% CONFIG RemoteRegistry start= AUTO
		 SC %@CONNECT#% START RemoteRegistry
		 ECHO:
	 )
 ) %@QUIET_RC%

 rem -- Generate Remote Command Sequence
 SET @EXECUTE=%@CMD% %@PARAMS%& FOR %%C IN ("" " " "  ") DO IF "%@PARAMS%"=="%%~C" SET @EXECUTE=%@CMD% ROUTE -P PRINT
 SET @EXECUTE=!@EXECUTE:[[=^(!
 SET @EXECUTE=!@EXECUTE:]]=^)!
 SET @EXECUTE=!@EXECUTE:``=^^^&!
 SET @EXECUTE=!@EXECUTE://=^^^|!
 SET @EXECUTE=!@EXECUTE:__= !
 SET @EXECUTE=!@EXECUTE:''="!
 SET @EXECUTE=!@EXECUTE:""=''!
 SET @EXECUTE=!@EXECUTE:::=%%!


 rem -- Connect to Remote System via Remote Console (and optionally run commands)
:MakeConnection
 ECHO Executing: %@RMTCONSOLE% %@CONNECT#% %@EXECUTE%
 %@RMTCONSOLE% %@CONNECT#% %@EXECUTE%


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 IF DEFINED @ZZ (%@PAUSE% & %@EXIT%)
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Get System Name and UNC
:GetSysName
 rem %1 = Variable Name containing name to be parsed

 IF "!%~1!"=="" (
	 ECHO *** ERROR: No System Name Found ***
 ) ELSE (
	 FOR /F "TOKENS=1 DELIMS=\ " %%s IN ('ECHO: !%~1!') DO (
		 SET %~1=%%~s
		 SET %~1#=\\%%~s
	 )
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
 ECHO Initiate Remote Console Connection with Optional Commands...
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<server^> [OPTIONS] [Command w/parameters for remote system]
 ECHO  %~n0  -h^|-?^|-h2^|-??
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ..... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 .... Display Extended Help Message
 ECHO  @@P ......... Use PSEXEC for Remote Shell  {default option}
 ECHO  @@A ......... Use PAEXEC for Remote Shell
 ECHO  @@B ......... Use BeyondExec for Remote Shell
 ECHO  @@T ......... Use a temporary CMD console ^(CMD /C^)
 ECHO  @@PT ........ Use PSEXEC + a temporary CMD console ^(CMD /C^)
 ECHO  @@AT ........ Use PAEXEC + a temporary CMD console ^(CMD /C^)
 ECHO  @@BT ........ Use BeyondExec + a temporary CMD console ^(CMD /C^)
 ECHO:
 ECHO    The following token substitutions are available within valid commands:
 ECHO:
 ECHO        $$ .... Represents the current "\\servername" from the list (without quotes)
 ECHO        ## .... Represents the current "servername" from the list (without quotes)
 ECHO        [[ .... Represents a  "(" character
 ECHO        ]] .... Represents a  ")" character
 ECHO        `` .... Represents a  "&" character
 ECHO        // .... Represents a  "|" character
 ECHO        __ .... Represents a  " " character  (regular space)
 ECHO        '' .... Represents a   "  character  (one double quote)
 ECHO        "" .... Represents two '' characters (two single quotes)
 ECHO        :: .... Represents two %%%% characters (two percent signs)
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 SRV02
	 ECHO  %~n0 SERVER1 @@A
	 ECHO  %~n0 SYSTEM2 @@P
	 ECHO  %~n0 MACHINE2 DIR C:\ /OGD /A
	 ECHO  %~n0 COMPUTER3 @@T IPCONFIG /ALL
	 ECHO  %~n0 COMPUTER4 @@A ECHO SAY ``This is a quote.``
	 ECHO  DO . START %~n0 ## @@T PAUSE When you press ENTER, this window will go away
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO:
	 ECHO  * Long filenames which contain spaces must be surrounded by quotes.
	 ECHO  * Each instance of `` or '' will be sent to the remote system as "
	 ECHO:
	 ECHO  * Setting @JUST_CONNECT to TRUE will skip past accessibility testing
	 ECHO  * Setting @REMOTE_PING to TRUE will initiate a PING before testing access
 )
 CALL :ShowStatus "FINISHED"
                                                                                   