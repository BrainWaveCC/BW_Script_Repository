@REM - ASB (05 Apr 2006 // 14 Aug 2025 / 14 Jul 2024 / 29 May 2024 / 10 May 2024 / 02 May 2024 / 28 Apr 2024 / 15 Feb 2024): Execute One Command Against Selected Systems via PSEXEC or PAEXEC or BeyondExec
@ECHO OFF


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET "@TTT=%1 %2 %3 %4"
 SET "@TTT=%@TTT:/?={HELP}%"
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET "@TTT="
 SET "@CRLF=@CRLF-FINISHED"
 SET "%@CRLF%=\#\n\n"


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
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v7.7.0.970 d

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=2 -c "H- HELP- ?-" -x "??- H2-" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f CHOICE.EXE SC.EXE TIMEOUT.EXE ADFIND.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET "%%P=%%~Q"

 rem -- Standard Log Variables
 SET @LOGROOT=%TEMP%\%~n0.%@DIRSTAMP_R%
 SET @DYNAMIC=%@LOGROOT%\SourceList.TXT

 rem -- Main Variables
 SET @TOTAL=0
 SET @COUNT=0
 SET @GROUP=Custom List
 SET @INPUT=%~d0\Scripts\BAT\Input

 rem -- AD Search Variables (using ADFind)
 SET @xPARAMS=-nodn -s SUB -maxe 2000 -list attr name -excldn "OBSOLETE;RETIRED;DECOMMISSIONED"
 SET @ADQUERY_C=ADFind -f "(&(objectcategory=computer)(operatingSystem=Windows*))" %@xPARAMS%
 SET @ADQUERY_D=ADFind -f "(&(objectCategory=computer)(|(primaryGroupId=516)(primaryGroupId=521)))" %@xPARAMS%
 SET @ADQUERY_N=ADFind -f "(&(objectcategory=computer)(operatingSystem=Windows*)($$$(primaryGroupID=516)))" %@xPARAMS%
 SET @ADQUERY_S=ADFind -f "(&(objectcategory=computer)(|(operatingSystem=Windows*Server*)(operatingSystem=Windows*Storage*)))" %@xPARAMS%
 SET @ADQUERY_O=ADFind -f "(&(objectcategory=computer)(|(operatingSystem=Windows*Server*)(operatingSystem=Windows*Storage*))($$$(primaryGroupID=516)))" %@xPARAMS%
 SET @ADQUERY_W=ADFind -f "(&(&(objectcategory=computer)(operatingSystem=Windows*))($$$(|(operatingSystem=Windows*Server*)(operatingSystem=Windows*Storage*))))" %@xPARAMS%

 rem -- Determine Which Console Session is Active for this Script
 SET @VALID_SESSIONS="Console" "RDP-TCP"
 SET @SERVICE_ACCTS="SYSTEM" "NTAUTHORITY" "%COMPUTERNAME%$"
 SET @SESSION_USER=%USERNAME%
 SET @SESSION_NAME=-& FOR /F "DELIMS=># " %%s IN ('QUERY SESSION 2^>NUL ^| FIND ">"') DO SET @SESSION_NAME=%%s
 SET @CONSOLE_SESSION=FALSE
	 IF NOT DEFINED USERNAME SET @CONSOLE_SESSION=FALSE
	 IF "%USERNAME:~-1%"=="$" SET @CONSOLE_SESSION=FALSE
	 IF "%@SESSION_NAME%"=="-" SET @CONSOLE_SESSION=FALSE
	 FOR %%s IN (%@VALID_SESSIONS%) DO IF /I "%@SESSION_NAME%"=="%%~s" SET @CONSOLE_SESSION=TRUE
	 FOR %%u IN (%@SERVICE_ACCTS%)  DO IF /I "%@SESSION_USER%"=="%%~u" SET @CONSOLE_SESSION=FALSE
	 IF DEFINED @NOPROMPT SET @CONSOLE_SESSION=FALSE

 rem -- Hide Remote Console Startup Details
 SET @QUIET_RC=& IF NOT DEFINED DEBUG SET @QUIET_RC=^>NUL 2^>^&1

 rem -- Isolate the command string that is to be executed
 FOR /F "TOKENS=1*" %%C IN ('ECHO "%*"') DO SET @CMD=%%D& SET @CMD=!@CMD:~0,-1!
 CALL :ReplaceTokens @CMD @EXECUTE
 CALL :ReplaceTokens @CMD @EXECUTE# SHOW

 rem -- Determine Which Source File to Use for Input
 IF NOT EXIST "%@LOGROOT%" MD "%@LOGROOT%"
 SET @SOURCE=*%~1*
	 IF "%~1"=="***" SET @SOURCE=%@DYNAMIC%& SET @GROUP=All Systems via NET VIEW& NET VIEW | FIND "\\" >"%@DYNAMIC%"
	 IF "%~1"=="**"  SET @SOURCE=%@DYNAMIC%& SET @GROUP=All Systems via ADFIND&   %@ADQUERY_C:$$$=^!%  >"%@DYNAMIC%"
	 IF "%~1"=="*"   SET @SOURCE=%@DYNAMIC%& SET @GROUP=All Systems [Minus DCs]&  %@ADQUERY_N:$$$=^!%  >"%@DYNAMIC%"
	 IF "%~1"=="+"   SET @SOURCE=%@DYNAMIC%& SET @GROUP=All NON-Server Systems&   %@ADQUERY_W:$$$=^!%  >"%@DYNAMIC%"
	 IF "%~1"=="$"   SET @SOURCE=%@DYNAMIC%& SET @GROUP=All Servers [with DCs]&   %@ADQUERY_S:$$$=^!%  >"%@DYNAMIC%"
	 IF "%~1"=="#"   SET @SOURCE=%@DYNAMIC%& SET @GROUP=All Servers [Minus DCs]&  %@ADQUERY_O:$$$=^!%  >"%@DYNAMIC%"
	 IF "%~1"=="@"   SET @SOURCE=%@DYNAMIC%& SET @GROUP=Domain Controllers Only&  %@ADQUERY_D:$$$=^!%  >"%@DYNAMIC%"
	 IF "%~1"=="."   SET @SOURCE=%@INPUT%\ServerList
	 SET @FINDLIST="%@SOURCE%" "%~1" "%~1*" "%~dp0%@SOURCE%" "%~dp0Input\%@SOURCE%" "%@INPUT%\%@SOURCE%" "%@INPUT%\ServerList"
	 FOR %%F IN (%@FINDLIST%) DO FOR %%E IN ("" ".%COMPUTERNAME%.TXT" ".TXT") DO IF EXIST "%%~F%%~E" IF NOT DEFINED #ASKED_%%~F%%~E (
		 SET @SOURCE=%%~F%%~E
		 SET #ASKED_%%~F%%~E=TRUE
		 IF /I "!@SOURCE:~-4!"==".TXT" (
			 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
				 CHOICE /C YNQEX /T 10 /D Y /N /M "Use the following system list? - '!@SOURCE!' "
			 ) ELSE (
				 CHOICE /C Y /T 0 /D Y /N
			 )
		 )
		 IF ERRORLEVEL 3 GOTO :ExitBatch
		 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 2 (
			 FOR /F %%S IN ('TYPE "!@SOURCE!"') DO (
				 SET /A @TOTAL+=1
				 SET @SYS=%%~S
				 IF "!@SYS!"=="!@SYS:;=!" (
					 CALL :MakeHostList %%~S
					 SET /A @COUNT+=1
				 )
			 )
			 GOTO :SetRemoteControl
		 )
	 )


 rem -- Abort script if no system list has been provided/accepted
:AbortExecution
 ECHO:
 ECHO ERROR: No Valid System List Was Provided -- Script Execution Aborted...
 ECHO:
 GOTO :HelpMessage


 rem -- Set Preference for Remote Console Tool: PSEXEC -OR- PAEXEC -OR- BEYONDEXEC
:SetRemoteControl
 SET @REXEC_UTILS=BeyondExecV2 PAEXEC PSEXEC
 FOR /F "TOKENS=*" %%R IN ('FINDFILES -F BeyondExecV2 2^>NUL') DO SET @B_REMOTE=%%~nxR
 FOR /F "TOKENS=*" %%R IN ('FINDFILES -F PAEXEC       2^>NUL') DO SET @A_REMOTE=%%~nxR
 FOR /F "TOKENS=*" %%R IN ('FINDFILES -F PSEXEC       2^>NUL') DO SET @P_REMOTE=%%~nxR %@PSPARAMS% -s
 SET @RMTCONSOLE=&               IF DEFINED @B_REMOTE SET @RMTCONSOLE=%@B_REMOTE%
 IF /I NOT "%@NOPAEXEC%"=="TRUE" IF DEFINED @A_REMOTE SET @RMTCONSOLE=%@A_REMOTE%
 IF /I NOT "%@NOPSEXEC%"=="TRUE" IF DEFINED @P_REMOTE SET @RMTCONSOLE=%@P_REMOTE%


 rem -- Execute a Command Against Selected Systems via PSEXEC or BeyondExec
:ProcessJob
 ECHO Preparing to Execute a Command Job Against Selected Systems via Remote Console...
 ECHO %@DIVIDER-%
 ECHO  List of Systems .......: "!@SOURCE:%TEMP%=%%TEMP%%!"
 ECHO  Type of Systems .......: %@GROUP%
 ECHO  Target System Count ...: %@COUNT% of %@TOTAL%
 ECHO  Target System Names ...:%@HOSTLIST%
 ECHO  Remote Console Util ...: %@RMTCONSOLE%
 ECHO  Command to Execute ....: %@EXECUTE#%
 ECHO %@DIVIDER-%
 ECHO:
 IF /I "%@CONSOLE_SESSION%"=="TRUE" (
	 CHOICE /C YNQEX /T 20 /D Y /N /M "Continue running this script? (Y/N/Q) "
	 IF ERRORLEVEL 2 GOTO :ExitBatch
 )

 rem -- Loop Through Systems
 FOR %%V IN (%@HOSTLIST%) DO (
	 SET @MACHINE=%%~V
	 SET @MACHINE=\\!@MACHINE:\=!
	 SET @ACCESSIBLE=TRUE

	 IF /I "!@MACHINE!"=="\\%COMPUTERNAME%" (
		 SET @LOCATION=Local
		 SET @EXECUTE=CALL %@CMD%
		 SET @EXECUTE=!@EXECUTE:CALL CALL =CALL !
	 ) ELSE (
		 SET @LOCATION=Remote
		 SET @EXECUTE=%@RMTCONSOLE% !@MACHINE! CMD /C %@CMD%

		 rem -- Determine if Remote System is Available, then Connect
		 ECHO:
		 ECHO:
		 ECHO Trying to access .... "!@MACHINE:\=!" [!TIME: =0!]
		 ECHO %@DIVIDER-%
		 DIR "!@MACHINE!\C$" >NUL 2>NUL
		 IF ERRORLEVEL 1 (
			 SET @ACCESSIBLE=
			 ECHO ### NETWORK ERROR ... "!@MACHINE:\=!" IS NOT ACCESSIBLE ###
			 ECHO:
		 ) ELSE (
			 rem -- Start "Remote Registry" service on !@MACHINE! if not running
			 FOR /F "TOKENS=4" %%S IN ('SC !@MACHINE! QUERY "RemoteRegistry" ^| FIND "STATE"') DO (
				 IF NOT "%%~S"=="RUNNING" (
					 ECHO Starting Remote Registry Service on !@MACHINE!...
					 SC !@MACHINE! CONFIG RemoteRegistry start= AUTO
					 SC !@MACHINE! START RemoteRegistry
					 ECHO:
				 )
			 ) %@QUIET_RC%
		 )

	 )

	 rem -- Execute Command locally or via PSEXEC/PAEXEC/BeyondExecV2 as appropriate
	 IF DEFINED @ACCESSIBLE (
		 CALL :MakeCMD %%~V
		 ECHO:
		 ECHO Executing !@LOCATION! Commands on !@MACHINE!...
		 IF DEFINED @SANITIZED (SET @MSG=Some commands on !@MACHINE!) ELSE (SET @MSG=!@EXECUTE!)
		 ECHO [!TIME:~0,8!]: !@MSG!
		 !@EXECUTE!
	 )
 )


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 SET %@CRLF%=
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 SET %@CRLF%=
 EXIT /B


 rem -- SUBROUTINE: Generate Concatenated List of UNC or non-UNC Hosts
:MakeHostList
 rem %1 = System to Execute the Command on

 SET @UNAME=%~1
 SET @HNAME=%@UNAME:\=%
 SET @UNAME=\\%@HNAME%

 IF /I "%@UNC%"=="TRUE" (SET @CNAME=!@UNAME!) ELSE (SET @CNAME=!@HNAME!)
 SET @HOSTLIST=!@HOSTLIST! !@CNAME!
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem -- SUBROUTINE: Expand Command with Token Substitutions, including $$ for each UNC Name and ## for Host Name
:MakeCMD
 rem %1 = System to Execute the Command on

 SET @UNAME=%~1
 SET @HNAME=%@UNAME:\=%
 SET @UNAME=\\%@HNAME%
 SET @CURRENTCMD=!@EXECUTE:$$=%@UNAME%!
 SET @CURRENTCMD=!@CURRENTCMD:##=%@HNAME%!
 CALL :ReplaceTokens @CURRENTCMD @EXECUTE
 %@PRINT_IF_DEBUG%
 EXIT /B


 rem -- SUBROUTINE: Make Token Substitutions, Except ## and $$
:ReplaceTokens
 rem %1 = Source Variable
 rem %2 = Destination Variable
 rem %3 = Optional Value for processing "|" and "&" differently

 SET @ZZ=!%~1!
 SET @ZZ=!@ZZ:[[=^(!
 SET @ZZ=!@ZZ:]]=^)!

 IF "%~3"=="" (SET @ZZ=!@ZZ:``=^&!) ELSE (SET @ZZ=!@ZZ:``=^^^&!)
 IF "%~3"=="" (SET @ZZ=!@ZZ://=^|!) ELSE (SET @ZZ=!@ZZ://=^^^|!)

 SET @ZZ=!@ZZ:__= !
 SET @ZZ=!@ZZ:''="!
 SET @ZZ=!@ZZ:""=''!
 SET @ZZ=!@ZZ:++=//!
 SET @ZZ=!@ZZ:::=%%!
 SET %~2=!@ZZ!
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
 ECHO Execute a Command Against Selected Systems via PSEXEC or PAEXEC or BeyondExec
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  ^<OPTION ^| list_of_systems^> ^<command with token substitution^>
 ECHO  %~n0  -h-^|-?-^|--help-^|-??-^|-h2-
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO   -?-, /H- ... Display This Help Message  (also --HELP-)
 ECHO  -??-, /H2- .. Display Extended Help Message
 ECHO      .  ...... Use the default systems list  **DEFAULT**
 ECHO      @  ...... Generate a dynamic list of ALL domain controllers using the ADFIND command
 ECHO      #  ...... Generate a dynamic list of domain servers (minus DCs) using the ADFIND command
 ECHO      $  ...... Generate a dynamic list of ALL domain servers using the ADFIND command
 ECHO      +  ...... Generate a dynamic list of domain computers (minus ALL servers) using the ADFIND command
 ECHO      *  ...... Generate a dynamic list of domain computers (minus DCs) using the ADFIND command
 ECHO     **  ...... Generate a dynamic list of ALL domain computers (everything) using the ADFIND command
 ECHO    ***  ...... Generate a dynamic list of domain/workgroup computers using the NET VIEW command
 ECHO:
 ECHO    The following token substitutions are available within valid commands:
 ECHO:
 ECHO        $$ .... Represents the current "\\servername" from the list (without quotes)
 ECHO        ## .... Represents the current "servername" from the list (without quotes)
 ECHO        [[ .... Represents a  "("  character
 ECHO        ]] .... Represents a  ")"  character
 ECHO        `` .... Represents a  "&"  character
 ECHO        // .... Represents a  "|"  character
 ECHO        __ .... Represents a  " "  character  (regular space)
 ECHO        '' .... Represents a   "   character  (one double quote)
 ECHO        "" .... Represents two ''  characters (two single quotes)
 ECHO        ++ .... Represents two "/" characters (two forward slashes)
 ECHO        :: .... Represents two %%%% characters (two percent signs)
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 . DIR "%SystemDrive%\Windows\System32"
	 ECHO  %~n0 $ PING ##
	 ECHO  %~n0 @ DIR C:\ `` DIR D:\
	 ECHO  %~n0 . IPCONFIG /ALL // FIND /I "DNS"
	 ECHO  %~n0 $ for %v in [[1 2 3]] do @ECHO $$ - %v
	 ECHO  %~n0 * XCOPY D:\Folder \\%COMPUTERNAME%\Share$\Stuff
	 ECHO  %~n0 ** E:\Scripts\MyScript.BAT Some_Parameter
	 ECHO  %~n0 MyList NET TIME $$
	 ECHO  %~n0 E:\ThisList.TXT CMD /C TIME 19:00
	 ECHO  %~n0 %~dp0Input\ServerList.TXT DEL "%SystemDrive%\BadFile.DAT" /S
	 ECHO  %~n0 -?-
	 ECHO:
	 ECHO ------------
	 ECHO USAGE NOTES:
	 ECHO ------------
	 ECHO  * Parameters surrounded by ^<^> are mandatory.
	 ECHO  * Parameters surrounded by [] are optional.
	 ECHO:
	 ECHO  * Long filenames which contain spaces must be surrounded by quotes.
	 ECHO:
	 ECHO  * The filename of the list used for processing must be a short name.
	 ECHO:
	 ECHO  * This script uses -?-, -H-, and --HELP- as help syntax parameters to
	 ECHO    avoid conflicting with the normal -?, -H, and --HELP parameters that
	 ECHO    could be used by commands it is trying to process.
	 ECHO:
	 ECHO  * Commands executed on remote systems must include their full paths
	 ECHO    ^(as the default PATH for the remote session might be incomplete^)
	 ECHO:
	 ECHO  * The NET VIEW option [***] rarely works on modern Windows networks.
	 ECHO    Please use the other options instead.
	 ECHO:
	 ECHO  * Using the \\ and `` substitition parameters ^(among others^) with
	 ECHO    this command can be tricky. Be sure to test diligently...
	 ECHO:
	 ECHO  * Alternate ServerList files can be specified using their full path.
	 ECHO    For files which reside in the default INPUT folder, you can use the
	 ECHO    filename or filename.ext only.  ^(The default INPUT folder is typically
	 ECHO    %SystemDrive%\Scripts\Bat\Input^)
 )
 CALL :ShowStatus "FINISHED"
 