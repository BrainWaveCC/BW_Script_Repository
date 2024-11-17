@REM - ASB (16 Apr 2018 // 16 Oct 2023 / 30 Nov 2020 / 17 Aug 2020 / 02 Aug 2020 / 13 Jul 2020 / 26 May 2020 / 24 Dec 2019 / 10 Nov 2019): Simultaneously Copy Large Folder Tree from A-Z and Z-A
@ECHO OFF


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v2.10.0.300

 rem -- Check for Special Modes
 FOR /F "TOKENS=2" %%T IN ('CHECKPARAMS -q -c "T TEST"    -s %* 2^>NUL') DO (SHIFT /1 & SET @ECHO=ECHO)
 FOR /F "TOKENS=2" %%T IN ('CHECKPARAMS -q -c "P PREP"    -s %* 2^>NUL') DO (SHIFT /1 & SET @PREP=TRUE)
 FOR /F "TOKENS=2" %%T IN ('CHECKPARAMS -q -c "A ARCHIVE" -s %* 2^>NUL') DO (SHIFT /1 & SET @ARCHIVE=/M)

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc --mp=2 -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Obtain Date/Time and Supporting Core Variables
 FOR /F "TOKENS=1-2 DELIMS=;" %%P IN ('DATEINFO --Script-Variables 2^>NUL') DO SET %%P=%%~Q

 rem -- Determine Cores or Threads for Copy Jobs
 IF NOT DEFINED @THREADS (
	 IF DEFINED @PHY_CORES (SET @AVAIL_CORES=%@PHY_CORES%) ELSE (SET @AVAIL_CORES=%NUMBER_OF_PROCESSORS%)
	 SET @THREADS=& IF DEFINED @AVAIL_CORES SET @THREADS=/MT:%@AVAIL_CORES%
 )
 IF %@OSBUILD% LSS 7600 SET @THREADS=

 rem -- Main Variables
 SET @SKIPTHESE=System.Volume.Information Config.Msi SymCache $GetCurrent $Recycle.Bin Found.000 Found.001 Found.002
 SET @OPTIONS="A-Z" "Z-A"
 SET @END=
 SET @SUCCESS=
 SET @RETRIES=/R:3 /W:60
 SET @PARAMS=/NJH /NJS /NDL /NS /NC /NP /XJ /XN /SEC /J %@ARCHIVE%
 SET @SOURCE=%~1& CALL :FixDirectoryPath @SOURCE
 SET @DEST=%~2&   CALL :FixDirectoryPath @DEST
 SET @LOGPATH=%TEMP%\Replication
 %@PRINT_IF_DEBUG%


 rem -- Verify Parameter Validity
:VerifyParameters
 IF NOT EXIST "%@SOURCE%" SET @END=TRUE& ECHO *** CANNOT FIND SOURCE: "%@SOURCE%"
 IF "%~1"==""             SET @END=TRUE& ECHO *** NO SOURCE FOLDER PROVIDED...
 IF "%~2"==""             SET @END=TRUE& ECHO *** NO DESTINATION FOLDER PROVIDED...
 FOR %%O IN (%@OPTIONS%) DO IF "%~3"=="%%~O" CALL :ExecuteCopy "%@SOURCE%" "%@DEST%" "%~3"
 IF DEFINED @END GOTO :ExitBatch
 %@PAUSE_IF_DEBUG%


 rem -- Generate Multiple Copy Jobs
:GenerateCopyJobs
 IF NOT EXIST "%@LOGPATH%" MD "%@LOGPATH%" >NUL
 SET @FNAME=%~n0-%@SOURCE%& CALL :SanitizeName @FNAME
 FOR %%F IN (!@OPTIONS!) DO SET @LIST_%%~F="%@LOGPATH%\%@FNAME%-%%~F.%@FILESTAMP%"

 ECHO COPYING FROM "%@SOURCE%" TO "%@DEST%" ...
 ECHO:
 ECHO *** Generating Sorted Directory Lists... Please Wait...

 IF NOT EXIST !@LIST_A-Z! (
	 DIR /B /AD /S "%@SOURCE%" 2>NUL | FINDSTR /R /I /V "%@SKIPTHESE%" >!@LIST_A-Z!
	 SORT /R !@LIST_A-Z! /O !@LIST_Z-A!
 )
 IF DEFINED @PREP %@ECHO% XCOPY "%@SOURCE%" "%@DEST%" /T /S /E /R /C /I /D /F /H /K /Y
 FOR %%P IN (%@OPTIONS%) DO START "Spawn ROBOCOPY Instance" %~df0 "%@SOURCE%" "%@DEST%" %%~P
 %@PAUSE_IF_DEBUG%


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 IF DEFINED @SUCCESS (PAUSE & EXIT)
 ENDLOCAL
 EXIT /B  


 rem -- SUBROUTINE: Execute Copy Job
:ExecuteCopy
 rem %1 = Source Folder
 rem %2 = Dest Folder
 rem %3 = Direction

 ECHO *** Generating Sorted Directory List [%~3]... Please Wait...
 ECHO:
 FOR /F "TOKENS=*" %%D IN ('TYPE !@LIST_%~3! 2^>NUL') DO (
	 SET @S_PATH=%%~D
	 SET @S_PATH=!@S_PATH::\\=:\!
	 SET @D_PATH=!@S_PATH:%@SOURCE%=%@DEST%!
	 SET @D_PATH=!@D_PATH::\\=:\!
	 ECHO:
	 ECHO Checking: "!@S_PATH!"
	 %@ECHO% ROBOCOPY "!@S_PATH!" "!@D_PATH!" *.* %@THREADS% %@RETRIES% %@PARAMS%
 )

 FOR %%R IN (END SUCCESS) DO SET @%%R=TRUE
 SET @P_RESULT=FALSE& IF DEFINED @PREP SET @P_RESULT=TRUE
 SET @T_RESULT=FALSE& IF DEFINED @ECHO SET @T_RESULT=TRUE
 ECHO:
 ECHO COMPLETED [%~3] -- PREP=%@P_RESULT%; TEST=%@T_RESULT%; SOURCE="%@SOURCE%"; DESTINATION="%@DEST%"
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem -- SUBROUTINE: Remove Trailing \ From Supplied Folder Path
:FixDirectoryPath
 rem %1 = Folder Variable

 IF NOT DEFINED %1 GOTO :EOF
 FOR /L %%X IN (1,1,9) DO IF "!%~1:~-1!"=="\" SET %~1=!%~1:~0,-1!
 IF "!%~1:~-1!"==":" SET %~1=!%~1!\
 %@PAUSE_IF_DEBUG%
 GOTO :EOF


 rem -- SUBROUTINE: Generate Safe Folder File Name
:SanitizeName
 rem %1 = Name of Variable to CleanUp

 IF NOT DEFINED %1 GOTO :EOF
 SET %~1=!%~1:(=[!
 SET %~1=!%~1:)=]!
 SET %~1=!%~1::\=_!
 SET %~1=!%~1:\=_!
 SET %~1=!%~1:__=!
 %@PAUSE_IF_DEBUG%
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
 ECHO Simultaneously Copy Large Folder Tree from A-Z and Z-A
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [/T^|/TEST] [/P^|/PREP] [/A^|/ARCHIVE] ^<source^> ^<dest^>
 ECHO  %~n0  [-h^|-?^|-h2^|-??]
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H ........ Display This Help Message  (also --HELP)
 ECHO  -??, /H2 ....... Display Extended Help Message
 ECHO  -T,  /TEST ..... Only ECHO the Output instead of performing the copies
 ECHO  -P,  /PREP ..... Pre-Create Empty destination folders using XCOPY /T
 ECHO  -A,  /ARCHIVE .. Only Copy Files with their Archive Bit Set (and reset it)
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0 C:\Source\Folder D:\Destination\Directory
	 ECHO  %~n0 "C:\Source Folder" "D:\Destination Directory"
	 ECHO  %~n0 "D:\Local Drive" \\REMOTE\SHARE\Directory
	 ECHO  %~n0 /PREP E:\Easy \\SERVER1\Repository
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
	 ECHO  * If present, /T or /TEST must be found prior to the source folder name
	 ECHO  * If present, /P or /PREP must be found prior to the source folder name
	 ECHO:
	 ECHO  * Any parameters which contain spaces should be surrounded by quotes.
	 ECHO    Shortnames *can* be surrounded by quotes if you choose, but it is not
	 ECHO    mandatory by any means.
 )
 CALL :ShowStatus "FINISHED"
                                                                