@REM - ASB (18 Nov 2010 // 03 Oct 2024 / 28 Jul 2024 / 14 Jul 2024 / 10 May 2024 / 02 May 2024 / 04 Apr 2024 / 12 Jan 2024): Configure Network Settings via CustomVariables.TXT and IPConfig.TXT
@ECHO OFF


 rem -- Generate Filtered CMD Title
:DisplayTitle
 SET @TTT= %*
 SET @TTT=%@TTT:/?={HELP}%
 TITLE [%USERDOMAIN%\%USERNAME%] - %~f0 %@TTT% >NUL 2>NUL
 SET @TTT=


 rem -- Initialize Environment Variables
:Variables
 SETLOCAL ENABLEDELAYEDEXPANSION & CALL :ShowStatus "STARTED" v5.4.0.540

 rem -- Display Syntax Help if Required/Requested
 CHECKPARAMS --rc -c "H HELP ?" -x "?? H2" -s %*
 IF ERRORLEVEL 1 IF NOT ERRORLEVEL 16 GOTO :HelpMessage

 rem -- Check for Essential Utilities and/or Scripts
 FINDFILES --bw -w -m -f "%~dp0SetDrive.BAT" IPCONFIG.EXE NETSH.EXE TZUTIL.EXE
 IF ERRORLEVEL 64 GOTO :ExitBatch

 rem -- Default Variables (Override via CustomVariables.*.TXT)
 SET @IPv6=
 SET @DHCPv6=TRUE

 rem -- Set Global Variables from Centralized Script
 CALL "%~dp0SetDrive.BAT" "%~n0"

 rem -- Process Special Command-line Parameters
 SET @ALL_PARAMS=%*
 CALL :GetParams "S SET CHANGE"              & IF DEFINED @OK (SET @ECHO=) ELSE (SET @ECHO=@ECHO)
 CALL :GetParams "T TEST"                    & IF DEFINED @OK (SET @ECHO=@ECHO)
 CALL :GetParams "6 IPV6 V6"                 & IF DEFINED @OK (SET @IPv6=TRUE& SET @DHCPv6=)
 CALL :GetParams "D CLEARDNS NODNS"          & IF DEFINED @OK (SET @CLEARDNS=TRUE)
 CALL :GetParams "W CLEARWINS NOWINS"        & IF DEFINED @OK (SET @CLEARWINS=TRUE)
 CALL :GetParams "I IP IPADDR"       @IPADDR & IF DEFINED @OK IF NOT DEFINED @IPADDR GOTO :HelpMessage
 CALL :GetParams "N NIC INT"          @MYNIC & IF DEFINED @OK IF NOT DEFINED @MYNIC  GOTO :HelpMessage
 CALL :GetParams "M MATCH"           @SYSTEM & IF DEFINED @OK IF NOT DEFINED @SYSTEM GOTO :HelpMessage
 CALL :GetParams "T TZ TIMEZONE"      @TZONE & IF DEFINED @OK IF NOT DEFINED @TZONE  GOTO :HelpMessage
 CALL :GetParams "F FILE"        @CUSTOMFILE & IF DEFINED @CUSTOMFILE (SET @CUSTOM-NETWORK=!@CUSTOMFILE!)
 IF NOT DEFINED @SYSTEM SET @SYSTEM=%COMPUTERNAME%

 rem -- Verify Input File Existence
 IF NOT EXIST "%@CUSTOM-NETWORK%" (
	 NOW \s \#### MISSING CONFIGURATION FILE: "%@CUSTOM-NETWORK%" \n\#\n
	 GOTO :HelpMessage
 )

 rem -- Grab Appropriate IP Variables from IPConfig.*.TXT -- Use ReadConfig.exe
 FOR /F "TOKENS=2" %%A IN ('READCONFIG "%@CUSTOM-NETWORK%" -K "%COMPUTERNAME%" -X 2^>NUL') DO (
	 IF NOT "%%~A"=="" CALL :SetVar @OLDNIC     "%%~A"
 )

 rem -- Grab Appropriate IP Variables from IPConfig.*.TXT -- Use ReadConfig.exe
 FOR /F "TOKENS=2-15" %%A IN ('READCONFIG "%@CUSTOM-NETWORK%" -K "%@SYSTEM%" -X 2^>NUL') DO (
	 IF NOT "%%~A"=="" CALL :SetVar @NIC        "%%~A"
	 IF NOT "%%~B"=="" CALL :SetVar @SUBNET     "%%~B"
	 IF NOT "%%~C"=="" CALL :SetVar @SUBMASK    "%%~C"
	 IF NOT "%%~D"=="" CALL :SetVar @MY_GATEWAY "%%~D"
	 IF NOT "%%~E"=="" CALL :SetVar @MY_DNS1    "%%~E"
	 IF NOT "%%~F"=="" CALL :SetVar @MY_DNS2    "%%~F"
	 IF NOT "%%~G"=="" CALL :SetVar @MY_DNS3    "%%~G"
	 IF NOT "%%~H"=="" CALL :SetVar @MY_WINS1   "%%~H"
	 IF NOT "%%~I"=="" CALL :SetVar @MY_WINS2   "%%~I"
	 IF NOT "%%~J"=="" CALL :SetVar @MY_WINS3   "%%~J"
	 IF NOT "%%~K"=="" CALL :SetVar @TIMEZONE   "%%~K"
	 IF NOT "%%~L"=="" CALL :SetVar @MY_DNSv6_1 "%%~L"
	 IF NOT "%%~M"=="" CALL :SetVar @MY_DNSv6_2 "%%~M"
	 IF NOT "%%~N"=="" CALL :SetVar @MY_DNSv6_3 "%%~N"
 )

 rem -- Grab Appropriate Custom Variables from CustomVariables.*.TXT -- Use ReadConfig.exe
 FOR /F "TOKENS=*" %%P IN ('READCONFIG "%@CUST-VARS-MINI%" -F "%~n0" 2^>NUL') DO CALL %%P
 IF /I NOT "!@SYSTEM!"=="%COMPUTERNAME%" SET @NIC="!@OLDNIC!"
 IF DEFINED @MYNIC    SET @NIC=!@MYNIC!
 IF DEFINED @NIC      SET @NIC="!@NIC:"=!"
 IF DEFINED @TZONE    SET @TIMEZONE=!@TZONE!
 IF DEFINED @TIMEZONE SET @TIMEZONE="!@TIMEZONE:"=!"


 rem -- Display Found and Selected Adapters
:ShowAdapterNames
 NOW \z \s \- --- Network Adapter Information for %COMPUTERNAME% \n \- \n Targeted Network Adapter: \n  -- %@NIC% \n \n Installed Network Adapter(s):
 SET @VALID_NIC=
 FOR /F "TOKENS=2*" %%A IN ('IPCONFIG /ALL ^| FIND "Ethernet adapter" 2^>NUL') DO CALL :ProcessAdapterNames %%~B
 ECHO:


 rem -- Set Custom IP Configuration
:ConfigureNetwork
 CALL :ShowTestMessage "WILL BE"
 NOW \s \---- Applying Network Settings of "%@SYSTEM%" on %COMPUTERNAME% \n\-\n

 IF DEFINED @TIMEZONE (
	 %@ECHO%:
	 ECHO Setting TimeZone to: %@TIMEZONE%
	 %@ECHO% TZUTIL /S %@TIMEZONE%
	 ECHO:
 )

 rem -- Skip everything else if we didn't find the right NIC
 IF NOT DEFINED @VALID_NIC (
	 ECHO *** UNABLE TO FIND NIC NAMED %@NIC% ***
	 ECHO:
	 ECHO IP, DNS and WINS settings will be skipped...
	 ECHO:
	 GOTO :FinalReport
 )

 IF DEFINED @CLEARDNS (
	 %@ECHO%:
	 ECHO Clearing ALL DNS Entries
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 delete dnsservers name=%@NIC% address=all validate=no
	 ) ELSE (
		 %@ECHO% NETSH interface ip delete dns name=%@NIC% addr=all validate=no
	 )
 )

 IF DEFINED @CLEARWINS (
	 %@ECHO%:
	 ECHO Clearing ALL WINS Entries
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 delete winsservers name=%@NIC% address=all
	 ) ELSE (
		 %@ECHO% NETSH interface ip delete wins name=%@NIC% addr=all
	 )
 )

 IF DEFINED @MY_DNS1 IF NOT "%@MY_DNS1%"=="-" (
	 %@ECHO%:
	 ECHO Setting DNS #1 to: %@MY_DNS1%
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 set dnsservers name=%@NIC% source=static %@MY_DNS1% register=both validate=no
	 ) ELSE (
		 %@ECHO% NETSH interface ip set dns name=%@NIC% source=static %@MY_DNS1% register=both validate=no
	 )
 )

 IF DEFINED @MY_DNS2 IF NOT "%@MY_DNS2%"=="-" (
	 %@ECHO%:
	 ECHO Setting DNS #2 to: %@MY_DNS2%
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 add dnsservers name=%@NIC% %@MY_DNS2% index=2 validate=no
	 ) ELSE (
		 %@ECHO% NETSH interface ip add dns name=%@NIC% %@MY_DNS2% index=2 validate=no
	 )
 )

 IF DEFINED @MY_DNS3 IF NOT "%@MY_DNS3%"=="-" (
	 %@ECHO%:
	 ECHO Setting DNS #3 to: %@MY_DNS3%
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 add dnsservers name=%@NIC% %@MY_DNS3% index=3 validate=no
	 ) ELSE (
		 %@ECHO% NETSH interface ip add dns name=%@NIC% %@MY_DNS3% index=3 validate=no
	 )
 )

 IF DEFINED @MY_WINS1 IF NOT "%@MY_WINS1%"=="-" (
	 %@ECHO%:
	 ECHO Setting WINS #1 to: %@MY_WINS1%
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 set winsservers name=%@NIC% source=static %@MY_WINS1%
	 ) ELSE (
		 %@ECHO% NETSH interface ip set wins name=%@NIC% source=static %@MY_WINS1%
	 )
 )

 IF DEFINED @MY_WINS2 IF NOT "%@MY_WINS2%"=="-" (
	 %@ECHO%:
	 ECHO Setting WINS #2 to: %@MY_WINS2%
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 add winsservers name=%@NIC% %@MY_WINS2% index=2
	 ) ELSE (
		 %@ECHO% NETSH interface ip add wins name=%@NIC% %@MY_WINS2% index=2
	 )
 )

 IF DEFINED @MY_WINS3 IF NOT "%@MY_WINS3%"=="-" (
	 %@ECHO%:
	 ECHO Setting WINS #3 to: %@MY_WINS3%
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 add winsservers name=%@NIC% %@MY_WINS3% index=3
	 ) ELSE (
		 %@ECHO% NETSH interface ip add wins name=%@NIC% %@MY_WINS3% index=3
	 )
 )

 rem -- Skip to Local IP Change if OS is older than Vista (No DHCP IPv6 DNS will be set)
 IF %@OSBUILD% LSS 6000 GOTO :ChangeIP

 IF DEFINED @DHCPv6 (
	 %@ECHO%:
	 ECHO Setting IPv6 DNS to DHCP
	 %@ECHO% NETSH interface ipv6 set dnsservers name=%@NIC% source=dhcp register=both validate=no
	 GOTO :ChangeIP
 )

 rem -- Skip to Local IP Change if static IPV6 DNS is not enabled
 IF NOT DEFINED @IPV6 GOTO :ChangeIP

 IF DEFINED @MY_DNSv6_1 (
	 %@ECHO%:
	 ECHO Setting IPv6 DNS #1 to: %@MY_DNSv6_1%
	 %@ECHO% NETSH interface ipv6 set dnsservers name=%@NIC% source=static %@MY_DNSv6_1% register=both validate=no
 )

 IF DEFINED @MY_DNSv6_2 (
	 %@ECHO%:
	 ECHO Setting IPv6 DNS #2 to: %@MY_DNSv6_2%
	 %@ECHO% NETSH interface ipv6 add dnsservers name=%@NIC% %@MY_DNSv6_2% index=2 validate=no
 )

 IF DEFINED @MY_DNSv6_3 (
	 %@ECHO%:
	 ECHO Setting IPv6 DNS #3 to: %@MY_DNSv6_3%
	 %@ECHO% NETSH interface ipv6 add dnsservers name=%@NIC% %@MY_DNSv6_3% index=3 validate=no
 )


 rem -- Change IP Address, If Supplied
:ChangeIP
 IF DEFINED @IPADDR (
	 %@ECHO%:
	 ECHO Setting IP Address to: %@IPADDR%
	 IF %@OSBUILD% GEQ 6000 (
		 %@ECHO% NETSH interface ipv4 set address name=%@NIC% source=static %@IPADDR% mask=%@SUBMASK% gateway=%@MY_GATEWAY% gwmetric=1 store=persistent
	 ) ELSE (
		 %@ECHO% NETSH interface ip set address name=%@NIC% source=static %@IPADDR% mask=%@SUBMASK% gateway=%@MY_GATEWAY% gwmetric=1 store=persistent
	 )
 ) ELSE (
	 ECHO:
	 ECHO *** No IP Address Chosen *** 
	 TIMEOUT 15
	 ECHO:
 )
 %@ECHO% IPCONFIG /REGISTERDNS


 rem -- Generate Final Report
:FinalReport
 NOW \n\**** %@VER% -- \v\n\*
 IPCONFIG /ALL
 CALL :ShowTestMessage "WERE"
 ECHO:
 IF NOT DEFINED @VALID_NIC ECHO *** UNABLE TO FIND NIC NAMED %@NIC% ***


 rem -- Reset Environment Variables and Exit Batch File
:ExitBatch
 CALL :ShowStatus "FINISHED"
 ENDLOCAL
 EXIT /B


 rem -- SUBROUTINE: Set Variables
:SetVar
 rem %1 = Variable
 rem %2 = Value to be Set

 IF "%~2"=="*" GOTO :EOF
 SET %1=%~2
 IF DEFINED %1 SET %1=!%1: =!
 IF DEFINED %1 SET %1=!%1:	=!
 IF DEFINED %1 SET %1=!%1:+= !
 GOTO :EOF


 rem -- SUBROUTINE: Use CheckParams.exe to Capture Selected Parameters
:GetParams
 rem %1 = Parameters to Search For
 rem %2 = Variable to Set

 SET @OK=& IF "%~1"=="" GOTO :EOF
 FOR /F "TOKENS=2-3*" %%v IN ('CHECKPARAMS -q -a -c "%~1" -s %@ALL_PARAMS% 2^>NUL') DO IF /I "%%~v"=="TRUE" (
	 SET @OK=T
	 SET @REQ=T
	 IF NOT "%~2"=="" SET %~2=%%~x
 )
 GOTO :EOF


 rem -- SUBROUTINE: Show Read-Only Mode Message, If Appropriate
:ShowTestMessage
 rem %1 = Message Verb

 IF NOT DEFINED @ECHO GOTO :EOF
 SET @VERB=%~1
 IF NOT DEFINED @VERB SET @VERB=WILL BE
 NOW \s \n\**** DISPLAY-ONLY MODE ENABLED: NO IP ADDRESS CHANGES %@VERB% MADE \n\*
 ECHO 
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


 rem -- SUBROUTINE: Process Ethernet Adapter Names
:ProcessAdapterNames
 rem %* = Variable containing Adapter name

 SET "@VNIC=%*"
 SET "@VNIC=!@VNIC::=!"
 IF /I !@NIC!=="!@VNIC!" (
	 SET @VALID_NIC=TRUE
	 ECHO  -- !@VNIC! 		*** Valid Target ***
 ) ELSE (
	 ECHO  -- !@VNIC!
 )
 GOTO :EOF


 rem -- SUBROUTINE: Display Syntax Help if Required/Requested
:HelpMessage
 ECHO Configure Network Settings via CustomVariables.TXT and IPConfig.TXT
 ECHO:
 ECHO ----------
 ECHO YOU TYPED:  %0 %*
 ECHO ----------
 ECHO:
 ECHO -----------
 ECHO CMD SYNTAX:
 ECHO -----------
 ECHO  %~n0  [OPTIONS]
 ECHO  %~n0  [-IP:^<IP address to set for system^>]
 ECHO  %~n0  [-NIC:^<"Network Interface"^>]
 ECHO  %~n0  [-TZ:^<"Time Zone"^>]
 ECHO  %~n0  [-MATCH:^<"Alternate System Name to Match Settings from"^>]
 ECHO  %~n0  [-FILE:^<"Alternate Configuration File to Obtain Settings from"^>]
 ECHO  %~n0  [-h^|-?^|-h2^|-??]
 ECHO:
 ECHO -------------------
 ECHO OPTION DEFINITIONS:
 ECHO -------------------
 ECHO  -?,  /H .......... Display This Help Message  (also --HELP)
 ECHO  -??, /H2 ......... Display Extended Help Message
 ECHO  -T,  /TEST ....... Test Mode Only  ***DEFAULT***
 ECHO  -D,  /CLEARDNS ... Clear all DNS Entries before Setting New Ones
 ECHO  -W,  /CLEARWINS .. Clear all WINS Entries before Setting New Ones
 ECHO  -S,  /SET ........ Make Actual Changes to IP Configuration
 ECHO  -I:, /IP: ........ Set Static IPv4 Address for the system
 ECHO  -N:, /NIC: ....... Set Network Interface to make changes to [override defaults]
 ECHO  -M:, /MATCH: ..... Select another system whose configuration should be applied here
 ECHO  -F:, /FILE: ...... Use Custom Configuration File instead of default
 ECHO  -6,  /IPv6 ....... Set Static IPv6 DNS entries
 ECHO:

 IF ERRORLEVEL 8 IF NOT ERRORLEVEL 16 (
	 ECHO ----------------
	 ECHO SYNTAX EXAMPLES:
	 ECHO ----------------
	 ECHO  %~n0
	 ECHO  %~n0 /TEST
	 ECHO  %~n0 /IP:10.20.30.40
	 ECHO  %~n0 /IP:192.168.200.200 /MATCH:"OTHER_SYSTEM" /SET
	 ECHO  %~n0 /NIC:"NIC1" /SET
	 ECHO  %~n0 /NIC:"Ethernet" /CLEARWINS /SET
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
	 ECHO  * No changes of any kind will be made if neither -S or -SET are enabled.
	 ECHO:
	 ECHO  * If an IP address is provided, the system will be set to this new
	 ECHO    IP, otherwise only DNS and WINS changes will be made.
	 ECHO:
	 ECHO  * The -I: -N: and -M: parameters cannot accept blank values.
	 ECHO:
	 ECHO  * If the value provided with the -M: parameter is not found, then the
	 ECHO    default values ^(represented by "&"^) will be used/applied.
 )
 CALL :ShowStatus "FINISHED"
                        