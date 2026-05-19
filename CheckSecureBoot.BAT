@ECHO OFF
 rem -- ASB (21 Apr 2026 // 13 May 2026 / 21 Apr 2026): Check Status of SecureBoot Certificates in Environment

:Variables -- v1.0.0.50
 SETLOCAL
 SET @MAINLOG=%TEMP%\2023CA-%RANDOM%.MAIN
 SET @SUMMARY=%@MAINLOG%.TXT

:Main
 ECHO Checking Status of SecureBoot Certificates in Environment ...
 (CALL DO . REG QUERY "$$\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecureBoot" /S) >"%@MAINLOG%" 2>&1
 READABLE "%@MAINLOG%" -F "\\; UEFI" --SB "\" --LB ":reg" -A -E -T -O "%@SUMMARY%"
 START "Final Report" "%@SUMMARY%"
 EXIT /B
                                            