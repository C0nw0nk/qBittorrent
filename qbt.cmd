@ECHO OFF & setLocal EnableDelayedExpansion

:: Copyright Conor McKnight
:: https://github.com/C0nw0nk/qBittorrent
:: https://www.facebook.com/C0nw0nk

:: To run this Automatically open command prompt RUN COMMAND PROMPT AS ADMINISTRATOR and use the following command
:: SCHTASKS /CREATE /SC HOURLY /TN "Cons qBittorrent Script" /RU "SYSTEM" /TR "C:\Windows\System32\cmd.exe /c start /B "C:\qbt\qbt.cmd"

:: Script Settings

:: IF you like my work please consider helping me keep making things like this
:: DONATE! The same as buying me a beer or a cup of tea/coffee :D <3
:: PayPal : https://paypal.me/wimbledonfc
:: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ZH9PFY62YSD7U&source=url
:: Crypto Currency wallets :
:: BTC BITCOIN : 3A7dMi552o3UBzwzdzqFQ9cTU1tcYazaA1
:: ETH ETHEREUM : 0xeD82e64437D0b706a55c3CeA7d116407E43d7257
:: SHIB SHIBA INU : 0x39443a61368D4208775Fd67913358c031eA86D59

:: qBittorrent WebUI Login
set username=admin
set password=pass
set webUI=http://localhost:8080

:: Automatically delete torrents older than X number of days
:: 3 days
set days_in_seconds=259200

:: Automatically delete torrents that have never been seen completed because it means they will never be complete you could download 99% of the torrent but nobody has the missing 1% meaning it will never finish downloading and will hang
:: 30 days
set last_seen_complete_days_in_seconds=2592000

:: Automatically delete torrents that have 0 seeders they will never download either

:: Automatically fix torrents stuck at 99.X%

:: Do not Download specific files inside of the torrent if they are blacklisted
:: Seperate each file extension with a space that you want to blacklist
set blacklisted_filetypes=".exe .txt .text .nfo .jpg .bmp .ico .png .gif .torrent .url .lnk .link .diz .ini .xml .sql .cmd .bat .dll .py .vbs .reg .html .htm .db .thumb .readme Sample sample. padding_file"

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

:start_loop
if "%~1"=="" (
start /wait /B qbt.cmd go
) else (
goto begin
)
goto start_loop
:begin

color 0A
%*
TITLE C0nw0nk - Automatic qBittorrent Script

SET root_path=%~dp0
set torrent_file=torrent.txt
set cookie_jar=\cookies.txt
set vbs_script=\time1.vbs

echo WScript.Echo(DateDiff("s", "01/01/1970 00:00:00", Now())) > %temp%%vbs_script%
for /f "tokens=*" %%a in ('
cscript //nologo %temp%%vbs_script%
') do set dynamic_time=%%a
del %temp%%vbs_script% 2>nul

set torrent_file=%torrent_file%_%dynamic_time%.txt
set cookie_jar=%cookie_jar%_%dynamic_time%.txt

rem Remove existing cookie jar
del /F %temp%%cookie_jar% 2>nul
rem Remove existing torrent list
del /F %root_path%%torrent_file% 2>nul

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info" | %root_path%jq.exe -r | findstr """hash""" > %root_path%%torrent_file%

rem settings torrents that get added are paused until force start by script this way this script gets to run its blacklist check to prevent blacklisted file types sneaking in inside of torrents
set settings_start_paused_enabled=%%7B%%22start_paused_enabled%%22%%3Atrue%%7D
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --data "json=%settings_start_paused_enabled%" --header "Content-Type: application/x-www-form-urlencoded" --header "Referer: %webUI%" "%webUI%/api/v2/app/setPreferences"

echo WScript.Echo(DateDiff("s", "01/01/1970 00:00:00", Now())) > %temp%%vbs_script%
for /f "tokens=*" %%a in ('
cscript //nologo %temp%%vbs_script%
') do set current_time=%%a
del %temp%%vbs_script% 2>nul

set "File=%root_path%%torrent_file%"
set /a count=0

for /F "tokens=* delims=" %%a in ('Type "%File%"') do (
         Set /a count+=1
         Set "output[!count!]=%%a"     
)

For /L %%i in (1,1,%Count%) Do (
	Call :Action "!output[%%i]!"
rem	pause
)

rem Remove used cookie jar
del /F %temp%%cookie_jar% 2>nul
rem Remove existing torrent list
del /F %root_path%%torrent_file% 2>nul

rem pause

Exit

::*******************************************************
:Action

rem set torrent hash
rem echo line : %1
rem echo (%1) | %root_path%jq.exe | findstr """hash"""
set torrent_=%1
set "torrent_=!torrent_:hash=!"
set "torrent_=!torrent_:"=!"
set "torrent_=!torrent_:,=!"
set "torrent_=!torrent_::=!"
set "torrent_=!torrent_: =!"
echo Hash: %torrent_%

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

rem stop Blacklisted files from sneaking in via torrents
for /f "tokens=*" %%a in ('
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/files?hash=%torrent_%" ^| %root_path%jq.exe -r ^| findstr """index"""
') do set torrent_clean_index_count=%%a
set "torrent_clean_index_count=!torrent_clean_index_count:index=!"
set "torrent_clean_index_count=!torrent_clean_index_count:"=!"
set "torrent_clean_index_count=!torrent_clean_index_count:,=!"
set "torrent_clean_index_count=!torrent_clean_index_count::=!"
set "torrent_clean_index_count=!torrent_clean_index_count: =!"
echo Number of files inside torrent: %torrent_clean_index_count%

set loop=0
set /a torrent_clean_index_count=%torrent_clean_index_count%+1
set torrent_clean_name=
:loop

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

for /f "tokens=*" %%a in ('
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/files?hash=%torrent_%&indexes=%loop%" ^| %root_path%jq.exe -r ^| findstr """name""" ^| findstr /R %blacklisted_filetypes%
') do set torrent_clean_name=true
IF NOT "%torrent_clean_name%"=="" (
echo Blacklisted file type inside torrent so do not download this particular content file inside of the torrent file
:: Do NOT Download particular file index
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --data "hash=%torrent_%" --data "id=%loop%" --data "priority=0" --header "Content-Type: application/x-www-form-urlencoded" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/filePrio"
)

set torrent_clean_name=
set /a loop=%loop%+1 
if "%loop%"=="%torrent_clean_index_count%" goto next
goto loop

:next

rem get torrent ETA

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

for /f "tokens=*" %%a in ('
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info?hashes=%torrent_%" ^| %root_path%jq.exe -r ^| findstr """eta"""
') do set torrent_eta=%%a
set "torrent_eta=!torrent_eta:eta=!"
set "torrent_eta=!torrent_eta:"=!"
set "torrent_eta=!torrent_eta:,=!"
set "torrent_eta=!torrent_eta::=!"
set "torrent_eta=!torrent_eta: =!"
echo ETA: %torrent_eta%

rem torrent progress stuck at 99.X% fix

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

for /f "tokens=*" %%a in ('
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info?hashes=%torrent_%" ^| %root_path%jq.exe -r ^| findstr """progress"""
') do set torrent_progress=%%a
set "torrent_progress=!torrent_progress:progress=!"
set "torrent_progress=!torrent_progress:"=!"
set "torrent_progress=!torrent_progress:,=!"
set "torrent_progress=!torrent_progress::=!"
set "torrent_progress=!torrent_progress: =!"
rem echo progress %torrent_progress%

echo WScript.Echo(FormatPercent(%torrent_progress%/1)) > %temp%%vbs_script%
for /f "tokens=*" %%a in ('
cscript //nologo %temp%%vbs_script%
') do set progress_percent=%%a
del %temp%%vbs_script% 2>nul

set "progress_percent=.!progress_percent:%%=!"
FOR %%a IN (%progress_percent%) DO FOR %%b IN (%%~na) DO SET "progress_percent_a=%%~xb" && SET "progress_percent_b=%%~xa"
set "progress_percent_a=!progress_percent_a:.=!"
set "progress_percent_b=!progress_percent_b:.=!"
rem echo progress is %progress_percent_a% and %progress_percent_b%
set progress_percent=%progress_percent_a%%progress_percent_b%

:: less than 100%
IF %progress_percent% LSS 10000 (
:: more than 99%
IF %progress_percent% GTR 9900 (
:: infinite
IF %torrent_eta% EQU 8640000 (
rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

echo we need to force recheck of torrent infinite stuck at 99.X%
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/recheck?hashes=%torrent_%"
)
)
)

rem last time torrent seen completed

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

for /f "tokens=*" %%a in ('
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info?hashes=%torrent_%" ^| %root_path%jq.exe -r ^| findstr """seen_complete"""
') do set torrent_last_complete=%%a
set "torrent_last_complete=!torrent_last_complete:seen_complete=!"
set "torrent_last_complete=!torrent_last_complete:"=!"
set "torrent_last_complete=!torrent_last_complete:,=!"
set "torrent_last_complete=!torrent_last_complete::=!"
set "torrent_last_complete=!torrent_last_complete: =!"
echo Torrent last seen complete: %torrent_last_complete%
echo("%torrent_last_complete%"|findstr "^[\"][-][1-9][0-9]*[\"]$ ^[\"][1-9][0-9]*[\"]$ ^[\"]0[\"]$">nul&&echo numeric||echo not numeric && EXIT /b
IF %torrent_last_complete% LEQ 0 (
echo it is 0
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/delete?hashes=%torrent_%&deleteFiles=true"
EXIT /b
)
set /a "torrent_compare_date=%current_time%-%last_seen_complete_days_in_seconds%"
IF %torrent_last_complete% NEQ 0 (
IF %torrent_last_complete% LEQ %torrent_compare_date% (
echo Completed torrent file is older than 30 days so deleting the torrent
rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/delete?hashes=%torrent_%&deleteFiles=true"
EXIT /b
)
)

rem number of seeds in swarm

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

for /f "tokens=*" %%a in ('
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info?hashes=%torrent_%" ^| %root_path%jq.exe -r ^| findstr """num_complete"""
') do set torrent_seeds=%%a
set "torrent_seeds=!torrent_seeds:num_complete=!"
set "torrent_seeds=!torrent_seeds:"=!"
set "torrent_seeds=!torrent_seeds:,=!"
set "torrent_seeds=!torrent_seeds::=!"
set "torrent_seeds=!torrent_seeds: =!"
echo Torrent seeds: %torrent_seeds%
echo("%torrent_seeds%"|findstr "^[\"][-][1-9][0-9]*[\"]$ ^[\"][1-9][0-9]*[\"]$ ^[\"]0[\"]$">nul&&echo numeric||echo not numeric && EXIT /b
IF %torrent_seeds% LEQ 0 (
echo Torrent seeds: 0

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/delete?hashes=%torrent_%&deleteFiles=true"
EXIT /b
)

rem delete completed torrents older than X number of days

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

set torrent_completion_on=
for /f "tokens=*" %%a in ('
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info?hashes=%torrent_%" ^| %root_path%jq.exe -r ^| findstr """completion_on"""
') do set torrent_completion_on=%%a
set "torrent_completion_on=!torrent_completion_on:completion_on=!"
set "torrent_completion_on=!torrent_completion_on:"=!"
set "torrent_completion_on=!torrent_completion_on:,=!"
set "torrent_completion_on=!torrent_completion_on::=!"
set "torrent_completion_on=!torrent_completion_on: =!"
echo Torrent completion on: %torrent_completion_on%
echo("%torrent_completion_on%"|findstr "^[\"][-][1-9][0-9]*[\"]$ ^[\"][1-9][0-9]*[\"]$ ^[\"]0[\"]$">nul&&echo numeric||echo not numeric meaning not yet finished downloading && EXIT /b
set /a "torrent_compare_date=%current_time%-%days_in_seconds%"
echo Compare date is: %torrent_compare_date%
IF %torrent_completion_on% NEQ 0 (

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

::If torrent complete then pause it to save bandwidth
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/pause?hashes=%torrent_%"
IF %torrent_completion_on% LEQ %torrent_compare_date% (

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

echo Completed torrent file is older than 3 days so deleting the torrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/delete?hashes=%torrent_%&deleteFiles=true"
EXIT /b
)
) ELSE (

rem Login to qBittorrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --header "Referer: %webUI%" --data "username=%username%&password=%password%" "%webUI%/api/v2/auth/login" >nul

:: Force start download on all torrent
curl -s -b "%temp%%cookie_jar%" -c "%temp%%cookie_jar%" --data "hashes=%torrent_%" --data "value=true" --header "Content-Type: application/x-www-form-urlencoded" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/setForceStart"
)

exit /b

::*******************************************************
