@echo off
cd
:: Setting working dir to the dir of this .bat file:
cd %0\..

if "%OS%"=="Windows_NT" ((cd /d %~dp0)&(goto next))
echo %0 | find.exe ":" >nul
if not errorlevel 1 %0\
cd %0\..
:next
echo Working dir:
cd

call pik sw 193
rdoc.bat -t TKXXS --force-update -f hanna --op ./doc  -x lib/tkxxs/tkxxs_classes.rb -x lib/tkxxs/samples --main ./README.rdoc ./README.rdoc ./lib/tkxxs.rb

